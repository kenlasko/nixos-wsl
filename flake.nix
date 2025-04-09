{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nix-ld.url = "github:Mic92/nix-ld";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, nixpkgs-stable, nixos-wsl, nix-ld, sops-nix, home-manager, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          pkgs-stable = import nixpkgs {
            config.allowUnfree = true;
          };
        };

        modules = [
          nix-ld.nixosModules.nix-ld
          { 
            programs.nix-ld.dev.enable = true; 
          }
          ./config    # This contains several other .nix configs
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.ken = import ./config/home-manager.nix;
          }
          nixos-wsl.nixosModules.default
          {
            system.stateVersion = "24.11";
            wsl.enable = true;
            wsl.defaultUser = "ken";
          }
          # Inline the settings from your original configuration.nix
          ({ pkgs, ... }: {
            nix.gc = {
              automatic = true;
              dates = "weekly";
              options = "--delete-older-than 1w";
            };

            # Install omnictl from a local path
            environment.systemPackages = [
              (pkgs.stdenv.mkDerivation {
                name = "omnictl";
                version = "latest";
                src =  ./packages/omnictl-linux-amd64;
                dontUnpack = true;
                installPhase = ''
                  mkdir -p $out/bin
                  cp $src $out/bin/omnictl
                  chmod +x $out/bin/omnictl
                '';
              })
            ];
          })
        ];
      };
    };
  };
}
