{ config, lib, ... }: {
  # Twingate zero-trust VPN client. NAS only.
  # Pulls in the `twingate` CLI, the twingate.service daemon, systemd-resolved
  # (for the split-DNS the client pushes per-link), and switches reverse-path
  # filtering to loose so the tunnel's replies are not dropped.
  config = lib.mkIf (builtins.elem config.networking.hostName [ "nixos-nas" ]) {
    services.twingate.enable = true;
  };
}
