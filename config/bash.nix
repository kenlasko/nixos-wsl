{ pkgs
, config
, ...
}: {
  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      source <(kubectl completion bash)
      source <(cilium completion bash)
    '';
    bashrcExtra = ''
      export TZ="America/Toronto"
      export BROWSER=wslview
      export NIX_CONFIG="experimental-features = nix-command flakes"
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
      # openshift must come first: on a merged KUBECONFIG, current-context and
      # any duplicately-named user/context resolve from the first file. oc-login
      # writes the fresh token + "work" context here, so it must win over the
      # stale duplicate that ~/.kube/config (secrets-managed) holds for the same
      # cluster user. Other contexts (cloud/home/lab/omni-*) still merge in.
      export KUBECONFIG="$HOME/.kube/openshift:$HOME/.kube/config"
      complete -F __start_kubectl k
      export USERNAMETEST="${config.home.username}"

      # Log into OpenShift, writing token + context to a dedicated kubeconfig
      # so it merges into KUBECONFIG without disturbing ~/.kube/config.
      # Renames the auto-generated context to "work".
      #
      # With no args it logs in automatically: it reads the credentials from
      # the sops secrets and fetches an OAuth token the same way the web
      # console's "Copy login command" does (the openshift-challenging-client
      # OAuth flow), so no manual browser token-copying is needed.
      #
      # Usage:
      #   oc-login                                             (automatic)
      #   oc-login --web --server=https://api.cluster.example.com:6443
      #   oc-login --token=sha256~... --server=https://...     (paste from web console)
      oc-login() {
        mkdir -p "$HOME/.kube"
        local kc="$HOME/.kube/openshift"
        local server="https://api.okd41.nectarsandbox.com:6443"

        if [[ $# -gt 0 ]]; then
          # Explicit args: pass straight through to `oc login`.
          KUBECONFIG="$kc" oc login "$@" || return $?
        else
          local user pass discovery issuer resp token rc
          user=$(< /run/secrets/openshift_username) \
            || { echo "oc-login: cannot read /run/secrets/openshift_username" >&2; return 1; }
          pass=$(< /run/secrets/openshift_password) \
            || { echo "oc-login: cannot read /run/secrets/openshift_password" >&2; return 1; }

          # Keep curl out of a pipeline: in `curl ... | jq`, $? belongs to jq,
          # and jq exits 0 on empty input. A connection failure therefore slipped
          # past this check and resurfaced below as a bogus "check credentials".
          discovery=$(curl -fsSk --connect-timeout 10 \
            "$server/.well-known/oauth-authorization-server")
          rc=$?
          if [[ $rc -ne 0 ]]; then
            echo "oc-login: cannot reach $server for OAuth discovery (curl exit $rc)" >&2
            echo "  Check what the name resolves to: the public record for this" >&2
            echo "  cluster is not routable. Only the internal 10.0.0.0/16 address" >&2
            echo "  is reachable over the VPN, and some clients return the public" >&2
            echo "  record instead. Compare: dig +short $(echo "$server" | sed -e 's|https://||' -e 's|:.*||')" >&2
            return 1
          fi

          issuer=$(jq -re .issuer <<<"$discovery") \
            || { echo "oc-login: OAuth discovery at $server returned no issuer" >&2; return 1; }

          resp=$(curl -sk --connect-timeout 10 -u "$user:$pass" -H "X-CSRF-Token: 1" \
            "$issuer/oauth/authorize?client_id=openshift-challenging-client&response_type=token" \
            -o /dev/null -D -)
          rc=$?
          if [[ $rc -ne 0 ]]; then
            echo "oc-login: cannot reach OAuth issuer $issuer (curl exit $rc)" >&2
            return 1
          fi

          token=$(sed -n 's/.*access_token=\([^&]*\).*/\1/p' <<<"$resp" | tr -d '\r')
          if [[ -z "$token" ]]; then
            if grep -qiE '^HTTP/[0-9.]+ 401' <<<"$resp"; then
              echo "oc-login: credentials rejected for user '$user' (HTTP 401)" >&2
            else
              echo "oc-login: no access_token in OAuth response; status line(s):" >&2
              grep -iE '^HTTP/' <<<"$resp" >&2 || echo "  (no HTTP status returned)" >&2
            fi
            return 1
          fi

          KUBECONFIG="$kc" oc login --token="$token" --server="$server" \
            --insecure-skip-tls-verify=true >/dev/null || return $?
        fi

        local current
        current=$(KUBECONFIG="$kc" kubectl config current-context)
        if [[ "$current" != "work" ]]; then
          KUBECONFIG="$kc" kubectl config delete-context work >/dev/null 2>&1 || true
          KUBECONFIG="$kc" kubectl config rename-context "$current" work
        fi
      }
      omni-upgrade() {
        local env="$1"
        if [[ -z "$env" ]]; then
          echo "Usage: omni-upgrade {home|cloud|lab}"
          return 1
        fi

        local template="$HOME/omni/cluster-template-$env.yaml"
        if [[ ! -f "$template" ]]; then
          echo "Error: template $template does not exist"
          return 1
        fi

        omnictl cluster template sync -f "$template"
      }

      # Optional: simple completion for omni-upgrade
      _omni_upgrade_completions() {
        COMPREPLY=( $(compgen -W "home cloud lab" -- "''${COMP_WORDS[1]}") )
      }
      complete -F _omni_upgrade_completions omni-upgrade
    '';

    shellAliases = {
      b2 = "backblaze-b2";
      cilium = "cilium --namespace=cilium";
      cnpg = "kubectl cnpg -n cnpg";
      git-clean-branches = "git branch --merged main | grep -vE '^\*?\s*main$' | xargs -r git branch -d";
      k = "kubectl";
      kuc = "kubectl config use-context";
      nano = "nano --modernbindings";
      sops-update = "sops --config ~/nixos/.sops.yaml ~/nixos/config/secrets.yaml";
    };
  };
}