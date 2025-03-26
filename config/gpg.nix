{ pkgs
, ...
}: {
  # Improved support for YubiKey
  services.udev.packages = [ pkgs.yubikey-personalization ];

  home-manager.users.ken.programs.gpg = {
    enable = true;
  };

  home-manager.users.ken.services.gpg-agent = {
    enable = true;
    enableBashIntegration = true;
    pinentryPackage = pkgs.pinentry-curses;
  };
}