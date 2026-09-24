{ config, lib, ... }: {
  # Twingate zero-trust VPN client. NAS only.
  # Pulls in the `twingate` CLI, the twingate.service daemon, systemd-resolved
  # (for the split-DNS the client pushes per-link), and switches reverse-path
  # filtering to loose so the tunnel's replies are not dropped.
  config = lib.mkIf (builtins.elem config.networking.hostName [ "nixos-nas" ]) {
    services.twingate.enable = true;

    # Required for dhcpcd to hand the DHCP-provided nameservers to
    # systemd-resolved. dhcpcd runs as its own unprivileged user and sets them
    # over D-Bus, which resolved refuses unless a polkit rule grants that user
    # org.freedesktop.resolve1.set-dns-servers. The nixpkgs dhcpcd module ships
    # exactly that rule, but via security.polkit.extraConfig, which is inert
    # while polkit itself is disabled.
    #
    # Without it dhcpcd logs "Failed to set DNS configuration: Access denied",
    # ens3 ends up with no nameservers at all, and the Twingate client -- which
    # reads the system resolvers to use as its upstream for anything outside a
    # Resource -- logs "No DNS servers found for bypass interface ens3" and
    # falls back to hardcoded 1.1.1.1/8.8.8.8, sending every non-Resource
    # lookup to public DNS.
    security.polkit.enable = true;
  };
}
