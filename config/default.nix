{ inputs
, lib
, config
, pkgs
, ...
}: {
  imports = [
    ./docker.nix
    ./git.nix
    ./k8s.nix
    ./omnictl.nix
    ./sops.nix
    ./ssh.nix
  ];
}
