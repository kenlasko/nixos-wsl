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
    ./python.nix
    ./sops.nix
    ./ssh.nix
  ];
}
