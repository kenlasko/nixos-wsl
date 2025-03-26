{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.username = "ken";
  home.homeDirectory = "/home/ken";

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    ansible             # Automatic package installation
    docker              # Open source project to pack, ship and run any application as a lightweight container
    git                 # Git version control
    gnupg               # Modern release of the GNU Privacy Guard, a GPL OpenPGP implementation
    jq                  # Lightweight and flexible command-line JSON processor
    kubeseal            # A Kubernetes controller and tool for one-way encrypted Secrets
    terraform           # Tool for building, changing, and versioning infrastructure safely and efficiently
    wget                # A network utility to retrieve files from the Web
    wslu                # Windows Subsystem for Linux utilities
  ];

  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "24.11";

  home.sessionVariables = rec {
    OMNICONFIG = "~/.config/omni/config";
  };

  # Start VSCode Server which makes it easy to integrate with VSCode on Windows
  # Note: for future updates, have to run "nix-prefetch-url --unpack https://github.com/msteen/nixos-vscode-server/tarball/master"
  #       to get the sha256 value
  imports = [
    "${fetchTarball {
      url = "https://github.com/msteen/nixos-vscode-server/tarball/master";
      sha256 = "09j4kvsxw1d5dvnhbsgih0icbrxqv90nzf0b589rb5z6gnzwjnqf";
    }}/modules/vscode-server/home.nix"
  ];

  services.vscode-server.enable = true;

  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      source <(kubectl completion bash)
      source <(cilium completion bash)
    '';
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
      complete -F __start_kubectl k
    '';

    # set some aliases, feel free to add more or remove some
    shellAliases = {
      cilium = "cilium --namespace=cilium";
      k = "kubectl";
      tf = "terraform";
    };
  };

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
