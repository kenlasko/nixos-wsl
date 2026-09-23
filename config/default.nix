{ inputs
, lib
, config
, pkgs
, ...
}: {
  imports = [
    ./claude-code.nix
    ./docker.nix
    ./git.nix
    ./k8s.nix
    ./python.nix
    ./sops.nix
    ./ssh.nix
  ];
}
