{ inputs
, lib
, config
, pkgs
, ...
}: {
  imports = [
    ./git.nix
  ];

  # Nix-specific settings
#  nix = {
#    settings = {
#      experimental-features = "nix-command flakes";
#      auto-optimise-store = true;
#    };
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
#    registry = (lib.mapAttrs (_: flake: { inherit flake; })) ((lib.filterAttrs (_: lib.isType "flake")) inputs);
#  };

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
#  nix.nixPath = [ "/etc/nix/path" ];
#  environment.etc =
#    lib.mapAttrs'
#      (name: value: {
#        name = "nix/path/${name}";
#        value.source = value.flake;
#      })
#      config.nix.registry;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
#  system.stateVersion = "23.11";
}
