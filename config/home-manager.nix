{ config, pkgs, lib, ... }:

let
  wslpath = builtins.getEnv "WSLPATH";
  regex = "(/mnt/[a-z]/Users/[a-zA-Z0-9._-]+)/"; # Escaped regex for Nix strings
  match = lib.strings.match regex wslpath;
  extractedHomeDir = if match != null then
    builtins.elemAt match 0  # Extract the full match (group 0)
  else
    wslpath + "xxxxxx";
in

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
    wget                # A network utility to retrieve files from the Web
    wslu                # Windows Subsystem for Linux utilities
  ];

  home.sessionVariables.WSL_HOME = extractedHomeDir;
  home.enableNixpkgsReleaseCheck = false;

  # home.activation.copyKubeConfig = pkgs.lib.mkAfter ''
  #   if [ -n "$WINDOWS_HOME" ]; then
  #     mkdir -p "${config.home.homeDirectory}/.kube"
  #     cp "$WINDOWS_HOME/.kube/config" "${config.home.homeDirectory}/.kube/config"
  #   else
  #     echo "WINDOWS_HOME is not set, skipping kube config copy."
  #   fi
  # '';

  programs.bash = {
    enable = true;
    enableCompletion = true;
    # TODO add your custom bashrc here
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin:$HOME/go/bin"
    '';

    # set some aliases, feel free to add more or remove some
    shellAliases = {
      k = "kubectl";
    };
  };

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.11";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
