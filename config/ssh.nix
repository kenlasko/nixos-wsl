{ config, pkgs, lib, ... }:

{
  # Enable the SSH agent
  programs.ssh = {
    startAgent = true;  # Ensure SSH agent is running
    extraConfig = ''
      Host github.com
        IdentityFile ~/.ssh/github_rsa
        AddKeysToAgent yes
        StrictHostKeyChecking no
    '';
  };

  services.openssh = {
    enable = true;  # Enable the OpenSSH server
    settings = {
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      PermitRootLogin = "no";
      AllowUsers = [ "ken" ];
    };
    # NOTE: previously extraConfig re-declared `UsePAM yes`, contradicting
    # settings.UsePAM above. That stray line is removed; PermitRootLogin and
    # AllowUsers now live in settings (typed, canonical) instead of extraConfig.
  };
}
