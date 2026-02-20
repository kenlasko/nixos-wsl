{ pkgs
, ...
}: {
  users.users.ken.extraGroups = [ "docker" ];
  virtualisation.docker = {
    enable = true;
    extraPackages = with pkgs; [
      docker-buildx
    ];
    daemon.settings = {
      dns = [ "192.168.10.53" "192.168.1.17" "192.168.1.18" ];
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
}