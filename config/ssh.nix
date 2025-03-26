{ config, pkgs, ... }:

let
  # Decrypt the SSH key using sops-nix
  decryptedKey = pkgs.sops-nix.secrets."secrets/id_rsa".text;
in
{
  services.ssh-agent = {
    enable = true;  # Start ssh-agent at login
    identities = [
      {
        privateKey = decryptedKey;  # Load the decrypted key into ssh-agent
        user = "ken";               # Adjust as necessary
      }
    ];
  };
}