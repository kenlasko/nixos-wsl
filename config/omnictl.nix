{
  description = "Flake to install omnictl-linux-amd64 from local path";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, system }:
  let
    pkgs = import nixpkgs { inherit system; };
  in
  {
    packages.${system}.default = pkgs.stdenv.mkDerivation {
      name = "omnictl";
      version = "latest"; # Or specify a version if you know it
      src = pkgs.path {
        path = /home/ken/nixos/packages/omnictl-linux-amd64;
      };
      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/omnictl
        chmod +x $out/bin/omnictl
      '';
    };

    devShells.${system}.default = pkgs.mkShell {
      packages = [ self.packages.${system}.default ];
    };
  };
}