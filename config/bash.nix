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
    '';

    shellAliases = {
      cilium = "cilium --namespace=cilium";
      k = "kubectl";
      kuc = "kubectl config use-context";
      nano = "nano --modernbindings";
    };
  };
}