{ pkgs
, ...
}: {
  users.users.ken.extraGroups = [ "docker" ];
  virtualisation.docker = {
    enable = true;
    extraPackages = with pkgs; [
      docker-buildx
    ];
  };
}