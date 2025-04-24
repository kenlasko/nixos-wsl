{ pkgs
, ...
}: {
  home-manager.users.ken = {
    home.packages = with pkgs; [
      pinentry
    ];


    programs.git = {
      enable = true;

      userName = "Ken Lasko";
      userEmail = "ken.lasko@gmail.com";

      extraConfig = {

        init.defaultBranch = "main";
        url = {
          "ssh://git@github.com" = {
            insteadOf = "https://github.com";
          };
        };
        # Add GPG signing configurations
        user.signingkey = "3A82EFDA2CD08F09";
        commit.gpgsign = true;
        gpg.program = "${pkgs.gnupg}/bin/gpg";
      };
    };

    # GPG Configuration
    programs.gpg = {
      enable = true;
    };
    # Enable GPG Agent via services
    services.gpg-agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry;
    };
  };
}
