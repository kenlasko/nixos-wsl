# Manage with nix-shell -p sops --run "sops config/secrets.yaml"
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets."secrets/id_rsa.sops.yaml" = { # This name *must* match what you use in ssh.nix
      paths = [ ./secrets/id_rsa.sops.yaml ]; # Path to the encrypted file *relative to config/sops.nix*
    };
  };
}