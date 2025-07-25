{
  description = "NixOS configuration for specific hosts with conditional WSL and default alias";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05"; # Use the actual stable branch (24.05 as of writing)
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nix-ld.url = "github:Mic92/nix-ld";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05"; # Match stable nixpkgs branch
      inputs.nixpkgs.follows = "nixpkgs"; # Follows unstable unless overridden
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, nixos-wsl, nix-ld, sops-nix, home-manager, ... }:
    let
      # Helper function to generate NixOS configuration
      mkNixosSystem = { system, hostname, enableWsl ? false }:
        let
          omnictlSrcMap = {
            "x86_64-linux" = ./packages/omnictl-linux-amd64;
            "aarch64-linux" = ./packages/omnictl-linux-arm64;
          };
          omnictlSrc = omnictlSrcMap.${system} or (throw "Unsupported system for omnictl: ${system}");

          # Add allowUnfree to BOTH nixpkgs versions
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          pkgs-stable = import inputs.nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };

          # --- Conditionally define the list of WSL modules/configs ---
          wslConfig =
            if enableWsl then
              [
                # Include the base WSL module path
                nixos-wsl.nixosModules.default
                # Include the specific WSL settings as a separate module element
                ({ pkgs, ... }: { 
                  wsl.enable = true;
                  wsl.defaultUser = "ken";
                  # Add other WSL specific options here if needed
                  environment.systemPackages = [ pkgs.wslu ];
                })
              ]
            else
              [
                {
                  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ]; # Common modules
                  boot.initrd.kernelModules = [ ];
                  boot.kernelModules = [ "kvm-intel" ]; 
                  boot.extraModulePackages = [ ];

                  fileSystems."/" = {
                    device = "/dev/disk/by-label/NIXROOT"; 
                    fsType = "ext4";
                    options = [ "noatime" ];
                  };
                  fileSystems."/boot" = { 
                    device = "/dev/disk/by-label/NIXBOOT";
                    fsType = "vfat";
                    options = [ "fmask=0022" "dmask=0022" ];
                  };

                  # Add bootloader config
                  boot.loader.grub.enable = true;
                  boot.loader.grub.device = "/dev/sda";
                }
              ];
          # --- End conditional definition ---

        in nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit pkgs-stable inputs hostname enableWsl;
          };

          # Combine the unconditional modules with the conditional WSL modules
          modules = [
            # Basic host setup
            ({ config, pkgs, ... }: {
              networking.hostName = hostname;
              system.stateVersion = "25.05";
            })

            # User configuration
            ({ config, pkgs, ... }: {
              users.users.ken = {
                isNormalUser = true;
                home = "/home/ken";
                extraGroups = [ "wheel" ];
                hashedPassword = "";
                shell = pkgs.bashInteractive;
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPQKpuk+eeBuKg9xMkRVZ/n4Q8ggn8Msni4gAUdQrXaB Bitwarden"
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMMucJUNg9fmu3W6iKhVBPEnNKaH6USY2bdkgp0zLUOl JuiceSSH"
                ];
              };
            })

            # Enable passwordless sudo
            {
              security.sudo = {
                enable = true;
                wheelNeedsPassword = false;
              };
            }

            # Add a 2GB swapfile to specific hosts
            ({ config, pkgs, lib, ... }: {
              config = lib.mkIf (builtins.elem config.networking.hostName [ "nixos-nas" ]) {
                swapDevices = [
                  {
                    device = "/swapfile";
                    size = 2048; # Size in MB
                  }
                ];
              };
            })

            # Nix-LD configuration
            nix-ld.nixosModules.nix-ld
            { programs.nix-ld.dev.enable = true; }

            # Your custom configurations from ./config
            ./config

            # Sops configuration
            sops-nix.nixosModules.sops
            # Add sops settings...

            # Home Manager configuration
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit pkgs-stable inputs hostname enableWsl; };
              home-manager.users.ken = import ./config/home-manager.nix;
            }

            # Inline settings and architecture-specific package
            ({ pkgs, ... }: {
              nix.settings.experimental-features = [ "nix-command" "flakes" ];
              nix.settings.download-buffer-size = 16384;
              nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 1w"; };
              nixpkgs.config.allowUnfree = true;

              environment.systemPackages = [
                (pkgs.stdenv.mkDerivation {
                  pname = "omnictl";
                  version = "latest";
                  src = omnictlSrc;
                  dontUnpack = true;
                  installPhase = ''
                    runHook preInstall
                    mkdir -p $out/bin
                    cp $src $out/bin/omnictl
                    chmod +x $out/bin/omnictl
                    runHook postInstall
                  '';
                  meta.platforms = [ system ];
                })
                pkgs.git
              ];
            })
          ] ++ wslConfig; # Append the conditional wslConfig list here
        };
    in
    {
      nixosConfigurations = {
        # Host configurations (unchanged)
        "rpi1" = mkNixosSystem {
          system = "aarch64-linux";
          hostname = "rpi1";
        };
        "rpi2" = mkNixosSystem {
          system = "aarch64-linux";
          hostname = "rpi2";
        };
        "nas01" = mkNixosSystem {
          system = "x86_64-linux";
          hostname = "nixos-nas";
        };
       "wsl" = mkNixosSystem {
          system = "x86_64-linux";
          hostname = "nixos";
          enableWsl = true; # Enable WSL here
        };

        # Alias (unchanged)
        "nixos" = self.nixosConfigurations."wsl";
      };

      # Formatter (unchanged)
      formatter = inputs.nixpkgs.legacyPackages."x86_64-linux".alejandra;
    };
}
