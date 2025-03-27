# Manage with nix-shell -p sops --run "sops config/secrets.yaml"
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/ken/.config/sops/age/keys.txt";

    secrets.sshkey = {};
    secrets.sealed-secrets-signing-key = {
        owner = "ken";
        path = "/home/ken/sealed-secrets-signing-key.crt";
    };
  };
}