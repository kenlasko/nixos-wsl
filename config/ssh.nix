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
    };
    extraConfig = ''
      PermitRootLogin no
      AllowUsers ken
      UsePAM yes
    '';
  };
}