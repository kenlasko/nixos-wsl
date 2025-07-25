{ config, pkgs, lib, ... }:

{
  home.username = "ken";
  home.homeDirectory = lib.mkForce "/home/ken";
  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "25.05";

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    # ggshield            # GitGuardian CLI for scanning secrets in code
    go                  # Go programming language
    jq                  # Lightweight and flexible command-line JSON processor
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
      url = "https://akeyless-cli.s3.us-east-2.amazonaws.com/cli/1.127.0/production/cli-linux-amd64";
      sha256 = "0b1nwpbfnvsgq0ki8f8ywgdmspddipma26bgxhy780iqzrw42a43";
    };
  };
  home.sessionPath = [ "$HOME/.akeyless/bin" ];

  # Start VSCode Server which makes it easy to integrate with VSCode on Windows
  # Note: for future updates, have to run "nix-prefetch-url --unpack https://github.com/msteen/nixos-vscode-server/tarball/master"
  #       to get the sha256 value
  imports = [
    "${fetchTarball {
      url = "https://github.com/msteen/nixos-vscode-server/tarball/master";
      sha256 = "1l77kybmghws3y834b1agb69vs6h4l746ga5xccvz4p1y8wc67h7";
    }}/modules/vscode-server/home.nix"
    ./bash.nix
  ];

  services.vscode-server.enable = true;

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
