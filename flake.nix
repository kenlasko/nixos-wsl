{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, nixpkgs-stable, nixos-wsl, sops-nix, home-manager, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          pkgs-stable = import nixpkgs {
            config.allowUnfree = true;
          };
        };

        modules = [
          sops-nix.nixosModules.sops
          ./configuration.nix
          ./config
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
          # For WSL compatibility for VSCode Remote
          (pkgs: {
            programs.nix-ld = {
              enable = true;
              package = pkgs.nix-ld-rs;
            };
          })
        ];
      };
    };
  };
}
