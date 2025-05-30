{ pkgs, pkgs-stable, ...}: 
{
  nixpkgs.config = {
    allowUnfree = true;
  };

  environment.systemPackages = with pkgs; [
    cilium-cli        # CLI to install, manage & troubleshoot Kubernetes clusters running Cilium
    doppler           # CLI for managing Doppler secrets and configuration
    hubble            # CLI to troubleshoot Cilium network issues
    infisical         # CLI for managing Infisical secrets and configuration
    k9s               # k9s Kubernetes TUI
    cmctl             # Command line tool for managing Cert Manager
    kubectl           # Kubernetes CLI tool
    kubeseal          # A Kubernetes controller and tool for one-way encrypted Secrets
    kubernetes-helm   # Package manager for kubernetes
    krew	            # Kubectl package installer
    kubelogin-oidc    # OIDC auth provider for kubectl
    kubent            # Easily check your cluster for use of deprecated APIs
    popeye            # Kubernetes cluster resource sanitizer
#    omnictl           # SideroLabs Omni CLI. Doesn't work, so using local install in flake.nix
    opentofu          # Tool for building, changing, and versioning infrastructure safely and efficiently
    talosctl          # Talos Kubernetes CLI
  ];
}
