{ config
, lib
, pkgs
, ...
}: {
  # Freeform daemon.settings keys can't be removed by an override, so the DNS
  # pin is gated here. config/kiro.nix sets this false.
  options.local.docker.customDns = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Pin Docker daemon DNS servers in daemon.json.";
  };

  config = {
    users.users.ken.extraGroups = [ "docker" ];
    virtualisation.docker = {
      enable = true;
      extraPackages = with pkgs; [
        docker-buildx
      ];
      daemon.settings = {
        dns = lib.mkIf config.local.docker.customDns
          [ "192.168.10.53" "192.168.1.17" "192.168.1.18" ];
        # Cap BuildKit cache; it grew to 200+ GB unbounded
        builder.gc = {
          enabled = true;
          defaultKeepStorage = "20GB";
        };
      };
      # Weekly cleanup of stopped containers, dangling images and old build cache
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--filter=until=168h" ];
      };
    };

    # Auto-login to Docker Hub using /run/secrets/docker_pat
    systemd.services.docker-login = {
      description = "Docker Auto Login";
      after = [ "docker.service" ];
      wants = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          /bin/sh -c 'cat /run/secrets/docker_pat | ${pkgs.docker}/bin/docker login -u kenlasko --password-stdin'
        '';
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}