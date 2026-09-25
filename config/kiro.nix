# config/kiro.nix
#
# Kiro Crew gateway, declaratively. This module is deliberately NOT imported by
# config/default.nix -- it is pulled in ONLY by the `kiro` flake output, so it
# applies only with:
#
#     sudo nixos-rebuild switch --flake /etc/nixos#kiro
#
# A normal `--flake /etc/nixos#wsl` (or the `nixos` alias) build does NOT
# include it, so the gateway service (and the playwright-cli below) exist only
# on the opt-in generation.
#
# It runs the gateway from `pkgs.kirocrew` -- a pure Nix derivation of the
# kirocrew wheel (see packages/kirocrew.nix), no venv and no runtime pip.
#
# BROWSER TOOL SUPPORT (playwright-cli)
#   The gateway's browser tool shells out to a binary named exactly
#   `playwright-cli`, resolved by ABSOLUTE PATH from a fixed allow-list that
#   includes /run/current-system/sw/bin -- where environment.systemPackages
#   lands. We add a fully declarative `playwright-cli` there (see
#   packages/playwright-cli.nix): the npm package @playwright/cli pinned to the
#   version whose bundled Playwright browser build numbers match the nixpkgs
#   `playwright-driver` browsers, wired via PLAYWRIGHT_BROWSERS_PATH into the
#   /nix/store browsers dir. No curl installer, no CDN download, no writes into
#   ~/.kiro/crew/playwright-cli -- launch is fully offline from store paths.
#
#   playwright-cli is defined here via callPackage (NOT a shared overlay) so it
#   stays scoped to this kiro module only and never appears on the other hosts.
#
# Prerequisites (already done imperatively, listed here for reproducibility):
#   * SSH key auth works because config/ssh.nix sets services.openssh UsePAM=false
#     and PasswordAuthentication=false (the tunnel signs with an empty-passphrase key)

{ config, lib, pkgs, ... }:

let
  # Scoped to the kiro module only: pkgs.playwright-cli is intentionally NOT an
  # overlay, so it exists on this opt-in generation and nowhere else.
  playwright-cli = pkgs.callPackage ../packages/playwright-cli.nix { };
in
{
  environment.systemPackages = [
    pkgs.kirocrew
    playwright-cli
  ];

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
