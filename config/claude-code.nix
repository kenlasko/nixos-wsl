# Claude Code CLI (https://claude.ai/claude-code)
# Config: ~/.claude/ (settings, MCP servers, sessions)
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    claude-code # CLI binary (from nixpkgs-unstable)
    bubblewrap  # Sandbox filesystem/network isolation (/sandbox command)
    socat       # Sandbox network proxy for domain filtering
  ];
}
