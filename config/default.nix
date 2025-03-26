{ inputs
, lib
, config
, pkgs
, ...
}: {
  imports = [
    ./docker.nix
    ./git.nix
    ./gpg.nix
    ./k8s.nix
  ];
}
