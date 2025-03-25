{ pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    cilium-cli          # CLI to install, manage & troubleshoot Kubernetes clusters running Cilium
    k9s                 # k9s Kubernetes TUI
    kubectl             # Kubernetes CLI tool
    kubernetes-helm     # Package manager for kubernetes
    krew		# Kubectl package installer
    kubelogin-oidc      # OIDC auth provider for kubectl
    kubent              # Easily check your cluster for use of deprecated APIs
    popeye              # Kubernetes cluster resource sanitizer
#    omnictl            # Omniverse CLI (if available in NixOS repos)
    talosctl            # Talos Kubernetes CLI
  ];
}
