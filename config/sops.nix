# Manage with nix-shell -p sops --run "sops ~/nixos/config/secrets.yaml"
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/ken/.config/sops/age/keys.txt";

    secrets.github_rsa = {
        owner = "ken";
        path = "/home/ken/.ssh/github_rsa";
        mode = "0400";
    };
    secrets.id_codesign = {
        owner = "ken";
        path = "/home/ken/.ssh/id_codesign";
        mode = "0400";
    };
    secrets.id_codesign.pub = {
        owner = "ken";
        path = "/home/ken/.ssh/id_codesign.pub";
        mode = "0400";
    };
    secrets.kubeconfig = {
        owner = "ken";
        path = "/home/ken/.kube/config";
        mode = "0600";
    };
    secrets."omni-s3-config.yaml" = {
        owner = "ken";
        path = "/home/ken/omni/s3-config.yaml";
        mode = "0444";
    };
    secrets.sealed-secrets-signing-key = {
        owner = "ken";
    };
    secrets."global-sealed-secrets-key.yaml" = {
        owner = "ken";
        mode = "0444";
    };
    secrets."default-sealing-key.yaml" = {
        owner = "ken";
        mode = "0444";
    };
    secrets.ucdialplans-admin-msuserid = {
        owner = "ken";
        mode = "0444";
    };
  };
}