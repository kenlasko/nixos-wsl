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
      complete -F __start_kubectl k
      export USERNAMETEST="${config.home.username}"
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
      cilium = "cilium --namespace=cilium";
      cnpg = "kubectl cnpg -n postgresql";
      k = "kubectl";
      kuc = "kubectl config use-context";
      nano = "nano --modernbindings";
      sops-update = "sops --config ~/nixos/.sops.yaml ~/nixos/config/secrets.yaml";
    };
  };
}