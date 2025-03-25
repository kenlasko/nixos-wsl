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
#        pull.ff = "only";
#        push = {
#          default = "current";
#          autoSetupRemote = true;
#        };
        url = {
          "ssh://git@github.com" = {
            insteadOf = "https://github.com";
          };
        };
      };
    };
  };
}
