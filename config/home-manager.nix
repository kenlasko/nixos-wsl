{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.username = "ken";
  home.homeDirectory = "/home/ken";
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "24.11";

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    ansible             # Automatic package installation
    ggshield            # GitGuardian CLI for scanning secrets in code
    jq                  # Lightweight and flexible command-line JSON processor
    kubeseal            # A Kubernetes controller and tool for one-way encrypted Secrets
    pre-commit          # Framework for managing and maintaining multi-language pre-commit hooks
    sops                # Simple and flexible tool for managing secrets
    trufflehog          # Scans git repositories for secrets
    wget                # A network utility to retrieve files from the Web
    wslu                # Windows Subsystem for Linux utilities
    yq-go               # Command-line YAML processor
  ];

  home.file.talosconfig = {
    enable = true;
    target = ".talos/config";
    text = ''
      context: onprem-omni
      contexts:
          onprem-omni:
              endpoints:
                  - https://omni.ucdialplans.com/
              auth:
                  siderov1:
                      identity: ken.lasko@gmail.com
              cluster: home
      '';
  };

  home.file.omniconfig = {
    enable = true;
    target = ".config/omni/config";
    text = ''
      contexts:
          default:
              url: https://omni.ucdialplans.com/
              auth:
                  siderov1:
                      identity: ken.lasko@gmail.com
      context: default
      '';
  };


  # Start VSCode Server which makes it easy to integrate with VSCode on Windows
  # Note: for future updates, have to run "nix-prefetch-url --unpack https://github.com/msteen/nixos-vscode-server/tarball/master"
  #       to get the sha256 value
  imports = [
    "${fetchTarball {
      url = "https://github.com/msteen/nixos-vscode-server/tarball/master";
      sha256 = "09j4kvsxw1d5dvnhbsgih0icbrxqv90nzf0b589rb5z6gnzwjnqf";
    }}/modules/vscode-server/home.nix"
    ./bash.nix
  ];

  services.vscode-server.enable = true;

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
