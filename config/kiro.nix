# config/kiro.nix
#
# Kiro Crew gateway, declaratively. This module is deliberately NOT imported by
# config/default.nix -- it is pulled in ONLY by the `kiro` flake output, so it
# applies only with:
#
#     sudo nixos-rebuild switch --flake /etc/nixos#kiro
#
# A normal `--flake /etc/nixos#wsl` (or the `nixos` alias) build does NOT
# include it, so the gateway service exists only on the opt-in generation.
#
# It runs the gateway from the pip venv at /home/ken/.kirocrew-venv, injecting
# the LD_LIBRARY_PATH numpy needs on NixOS (libstdc++.so.6 from gcc-lib, libz.so.1
# from zlib) via lib.makeLibraryPath -- resolved at BUILD time from package refs,
# so a channel update recomputes the /nix/store paths and can never leave a
# stale hardcoded hash.
#
# Prerequisites (already done imperatively, listed here for reproducibility):
#   * the venv exists at /home/ken/.kirocrew-venv with `kirocrew` installed
#   * SSH key auth works because config/ssh.nix sets services.openssh UsePAM=false
#     and PasswordAuthentication=false (the tunnel signs with an empty-passphrase key)

{ config, lib, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.kirocrew ];

  systemd.services.kirocrew-gateway = {
    description = "Kiro Crew gateway (NixOS-native spoke for the Windows hub)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "ken";
      WorkingDirectory = "/home/ken";
      ExecStart = "${pkgs.kirocrew}/bin/kirocrew gateway";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
