{ ...
}: {
  # Twingate zero-trust VPN client.
  # Pulls in the `twingate` CLI, the twingate.service daemon, and switches
  # reverse-path filtering to loose so the tunnel's replies are not dropped.
  services.twingate.enable = true;

  # The daemon resolves internal resources through systemd-resolved.
  services.resolved.enable = true;
}
