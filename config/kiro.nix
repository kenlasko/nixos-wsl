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

  # Kiro-only home-manager additions for ken. home-manager merges attrsets, so
  # this ADDS to the base config/home-manager.nix (home.packages, home.file)
  # without clobbering it -- these two items therefore exist ONLY on the opt-in
  # #kiro generation, never on #wsl / rpi1 / rpi2 / nas01.
  #
  #   * kiro-cli lands in ken's PER-USER profile at
  #     /etc/profiles/per-user/ken/bin/kiro-cli -- exactly where
  #     KIROCREW_KIRO_BIN below already points. Do not change that path.
  #   * kiro-cli is UNFREE; config.allowUnfree = true is set globally (flake.nix
  #     sets it on both nixpkgs imports and via nixpkgs.config.allowUnfree), and
  #     home-manager useGlobalPkgs makes this fragment use that same pkgs, so the
  #     unfree allowance is inherited here.
  #
  # config.local.json overlay: `config.local.json` is deep-merged OVER
  # `config.json`, and the gateway REWRITES config.json wholesale on save -- so a
  # declarative setting belongs in the overlay, which those rewrites never touch.
  # agent.sandbox = "off" disables Kiro Crew's OS-level (bubblewrap) sandbox,
  # which cannot create its mount namespace under the WSL kernel ("bwrap: Failed
  # to make / slave: Operation not permitted"). Trade-off: private/isolated
  # workflows (e.g. pods) need a working namespace sandbox and won't run with it
  # off; ordinary agent chat/tools are unaffected.
  home-manager.users.ken = { pkgs, ... }: {
    home.packages = [ pkgs.kiro-cli ];

    home.file.kirocrewLocalConfig = {
      target = ".kiro/crew/config.local.json";
      text = builtins.toJSON {
        agent.sandbox = "off";
      };
    };
  };

  # Leave Docker on default DNS resolution (no "dns" key in daemon.json).
  local.docker.customDns = false;

  systemd.services.kirocrew-gateway = {
    description = "Kiro Crew gateway (NixOS-native spoke for the Windows hub)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    # kiro-cli resolution. The gateway spawns kiro-cli WITHOUT trusting PATH (an
    # agent-writable dir could lead the inherited PATH), so its unattended
    # resolver searches only a fixed set -- ~/.local/bin, ~/.cargo/bin, and this
    # operator override (KIROCREW_KIRO_BIN). On this host kiro-cli is installed
    # by home-manager into ken's PER-USER profile, so `which kiro-cli` works in
    # ken's shell but it is NOT in the system profile (/run/current-system/sw/bin
    # is empty) and NOT in the gateway's minimal PATH -- hence the "resolves only
    # through PATH, which this spawn does not trust" refusal. The service runs as
    # user ken, so point the blessed override at ken's per-user profile symlink
    # -- stable across rebuilds, never a bare /nix/store/...-kiro-cli-<hash> path.
    environment.KIROCREW_KIRO_BIN = "/etc/profiles/per-user/ken/bin/kiro-cli";

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
