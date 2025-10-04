# Manage by running `sops ~/nixos/config/secrets.yaml`

{ pkgs, ... }: # Ensure inputs is available if used
{
  environment.systemPackages = with pkgs; [
    sops
  ];
  
  sops = {
    defaultSopsFile = ./secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/ken/.config/sops/age/keys.txt";

    secrets.id_ed25519= {
        owner = "ken";
        path = "/home/ken/.ssh/id_ed25519";
        mode = "0400";
    };
    secrets."id_ed25519.pub" = {
        owner = "ken";
        path = "/home/ken/.ssh/id_ed25519.pub";
        mode = "0400";
    };
    secrets.docker_pat = {
        owner = "ken";
        mode = "0400";
    };
    secrets.github_rsa = {
        owner = "ken";
        path = "/home/ken/.ssh/github_rsa";
        mode = "0400";
    };
    secrets."github_rsa.pub" = {
        owner = "ken";
        path = "/home/ken/.ssh/github_rsa.pub";
        mode = "0400";
    };
    secrets.id_codesign = {
        owner = "ken";
        path = "/home/ken/.ssh/id_codesign";
        mode = "0400";
    };
    secrets."id_codesign.pub" = {
        owner = "ken";
        path = "/home/ken/.ssh/id_codesign.pub";
        mode = "0400";
    };
    secrets.kubeconfig = {
        owner = "ken";
        path = "/home/ken/.kube/config";
        mode = "0600";
    };
    secrets.mariadb-root-password = {
        owner = "ken";
    };
    secrets."omni-s3-config.yaml" = {
        owner = "ken";
        path = "/home/ken/omni/s3-config.yaml";
        mode = "0444";
    };
    secrets.postgresql-root-password = {
        owner = "ken";
    };
    secrets.dmh-email-address = {
        owner = "ken";
        mode = "0400";
    };
    secrets.dmh-email-message = {
        owner = "ken";
        mode = "0400";
    };
    secrets.sealed-secrets-signing-key = {
        owner = "ken";
    };
    secrets.sealed-secrets-private-key = {
        owner = "ken";
    };
    secrets."global-sealed-secrets-key.yaml" = {
        owner = "ken";
        mode = "0400";
    };
    secrets."default-sealing-key.yaml" = {
        owner = "ken";
        mode = "0400";
    };
    secrets."eso-secretstore-secrets.yaml" = {
        owner = "ken";
        mode = "0400";
    };
    secrets.ucdialplans-admin-msuserid = {
        owner = "ken";
        mode = "0400";
    };
  };
}