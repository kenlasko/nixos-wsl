{ config, pkgs, lib, ... }:

# let
#   # Decrypt the SSH key using sops-nix
#   decryptedKey = config.sops.secrets."secrets/id_rsa.sops.yaml".text;
# in
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