# Manage with nix-shell -p sops --run "sops config/secrets.yaml"
{
  sops = {
    defaultSopsFile = ./secrets.yaml;

  };
}