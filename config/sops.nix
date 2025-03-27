# Manage with nix-shell -p sops --run "sops config/secrets.yaml"
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/ken/.config/sops/age/keys.txt";

    secrets.example_key = {};
    secrets."myservice/my_subdir/my_secret" = {};
    secrets.github_token = {
        sopsFile = ./secrets/id_rsa.sops.yaml;
        format = "yaml";
    };
  };
}