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
      # Usage:
      #   oc-login --web --server=https://api.cluster.example.com:6443
      #   oc-login --token=sha256~... --server=https://...   (paste from web console)
      oc-login() {
        mkdir -p "$HOME/.kube"
        local kc="$HOME/.kube/openshift"
        KUBECONFIG="$kc" oc login "$@" || return $?
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