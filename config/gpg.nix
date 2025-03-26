{ pkgs, ... }: {
  home-manager.users.ken.programs.gpg = {
    enable = true;
  };

  home-manager.users.ken.services.gpg-agent = {
    enable = true;
    enableBashIntegration = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  # Ensure pinentry is globally available
#   environment.systemPackages = with pkgs; [
#     pinentry
#   ];
}