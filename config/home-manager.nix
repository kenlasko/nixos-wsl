{ config, pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfree = true;
  home.username = "ken";
  home.homeDirectory = lib.mkForce "/home/ken";
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "24.11";

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    ansible             # Automatic package installation
    ggshield            # GitGuardian CLI for scanning secrets in code
    jq                  # Lightweight and flexible command-line JSON processor
    kubeseal            # A Kubernetes controller and tool for one-way encrypted Secrets
    openssl             # OpenSSL is a robust, full-featured open-source toolkit
    pre-commit          # Framework for managing and maintaining multi-language pre-commit hooks
    trufflehog          # Scans git repositories for secrets
    wget                # A network utility to retrieve files from the Web
    yq-go               # Command-line YAML processor
  ];

  # Configure Talos
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

  # Configure Omni
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

  # Configure Akeyless CLI
  home.file."bin/akeyless" = {
    executable = true;
    target = ".akeyless/bin/akeyless";
    source = builtins.fetchurl {
      url = "https://akeyless-cli.s3.us-east-2.amazonaws.com/cli/latest/production/cli-linux-amd64";
      sha256 = "1r3lck6a9yv8dqd8qnl9fx2qb44ls56c85z00a04c24rwv4h8kw8";
    };
  };
  home.sessionPath = [ "$HOME/.akeyless/bin" ];

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
