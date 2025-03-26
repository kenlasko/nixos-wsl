# Manage with nix-shell -p sops --run "sops configuration/secrets.yaml"
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
  };
}