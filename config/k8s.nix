{ pkgs, pkgs-stable, ...}: 
{
  nixpkgs.config = {
    allowUnfree = true;
  };

  environment.systemPackages = with pkgs; [
    cilium-cli        # CLI to install, manage & troubleshoot Kubernetes clusters running Cilium
    k9s               # k9s Kubernetes TUI
    kubectl           # Kubernetes CLI tool
    kubeseal          # A Kubernetes controller and tool for one-way encrypted Secrets
    kubernetes-helm   # Package manager for kubernetes
    krew	            # Kubectl package installer
    kubelogin-oidc    # OIDC auth provider for kubectl
    kubent            # Easily check your cluster for use of deprecated APIs
    popeye            # Kubernetes cluster resource sanitizer
    omnictl           # SideroLabs Omni CLI
    talosctl          # Talos Kubernetes CLI
    terraform         # Tool for building, changing, and versioning infrastructure safely and efficiently
  ];
}
