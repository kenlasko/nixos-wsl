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
        # Add code signing configuration
        gpg.format = "ssh";
        user.signingkey = "~/.ssh/id_codesign.pub";
        commit.gpgsign = true;
      };
    };
  };
}
