{ config, pkgs, ... }:

# let
#   # Decrypt the SSH key using sops-nix
#   decryptedKey = config.sops.secrets."secrets/id_rsa.sops.yaml".text;
# in
{
  # Enable the SSH agent
}