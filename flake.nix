{
  description = "NixOS configuration for specific hosts with conditional WSL and default alias";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11"; # Use the actual stable branch (24.05 as of writing)
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nix-ld.url = "github:Mic92/nix-ld";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11"; # Match stable nixpkgs branch
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

          pkgs-stable = import inputs.nixpkgs-stable {
            inherit system;
            config.allowUnfree = true;
          };

          # No need for separate lib variable here anymore

          # --- Conditionally define the list of WSL modules/configs ---
          wslConfig =
            if enableWsl then
              [
                # Include the base WSL module path
                nixos-wsl.nixosModules.default
                # Include the specific WSL settings as a separate module element
                {
                  wsl.enable = true;
                  wsl.defaultUser = "ken";
                  # Add other WSL specific options here if needed
                  # environment.systemPackages = [ pkgs.wslu ];
                }
              ]
            else
              # If WSL is not enabled, this contributes nothing to the module list
              [];
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
              system.stateVersion = "24.11";
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
            

            (lib.mkIf (!enableWsl) {
              boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ]; # Common modules needed early for storage
              boot.initrd.kernelModules = [ ];
              boot.kernelModules = [ "kvm-amd" ]; # Or "kvm-intel" - adjust if needed, could be another parameter
              boot.extraModulePackages = [ ];

              fileSystems."/" = {
                # IMPORTANT: Make sure NIXOS_SD is the correct label for your server's SD card/disk
                device = "/dev/disk/by-label/NIXOS_SD";
                fsType = "ext4";
                options = [ "noatime" ]; # Good default for SSDs/SD cards
              };

              # Example for swap (optional, adjust device/label)
              # fileSystems."/swap" = {
              #   device = "/dev/disk/by-label/NIXOS_SWAP";
              #   fsType = "swap";
              # };
              # swapDevices = [ { device = "/dev/disk/by-label/NIXOS_SWAP"; } ];

              # Add bootloader config - GRUB is common for servers
              boot.loader.grub.enable = true;
              boot.loader.grub.device = "/dev/sda"; # IMPORTANT: Set to the actual boot disk (e.g., /dev/sda, /dev/nvme0n1), NOT a partition or label
              # boot.loader.grub.useOSProber = false; # Usually false for single-boot servers
            })



            # Inline settings and architecture-specific package
            ({ pkgs, ... }: {
              nix.settings.experimental-features = [ "nix-command" "flakes" ];
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