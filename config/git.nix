{ pkgs
, ...
}: {
  home-manager.users.ken = {
    home.packages = with pkgs; [
 
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
      };
    };

    # GnuPG
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
}
