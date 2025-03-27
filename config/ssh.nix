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
}