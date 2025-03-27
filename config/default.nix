{ inputs
, lib
, config
, pkgs
, ...
}: {
  imports = [
    ./bash.nix
    ./docker.nix
    ./git.nix
    ./gpg.nix
    ./k8s.nix
    ./sops.nix
    #./ssh.nix
  ];
}
