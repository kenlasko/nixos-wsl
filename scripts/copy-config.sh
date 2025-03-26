#!/bin/sh

# Get the WSL host path for the logged-in user
HOSTPATH=$(echo "$WSLPATH" | grep -oP '(/mnt/\w/Users/\w+)' | head -1)

# Ensure ~/.kube directory exists, then copy the config file
if [ -f "$HOSTPATH/.kube/config" ]; then
    [ ! -d ~/.kube ] && mkdir -p ~/.kube 
    cp "$HOSTPATH/.kube/config" ~/.kube/config
    echo "Copied kubeconfig file from $HOSTPATH"
else
    echo "No kubeconfig file found in $HOSTPATH"
fi

# Get talosctl and omnictl config files from the Omni repo
if [ -f ~/omni/talosconfig.yaml ]; then
    [ ! -d ~/.talos ] && mkdir -p ~/.talos 
    cp ~/omni/talosconfig.yaml ~/.talos/config
    echo "Copied talosconfig file from ~/omni"
else
    echo "No talosconfig file found. Clone the kenlasko/omni repo to get this file"
fi

if [ -f ~/omni/omniconfig.yaml ]; then
    [ ! -d ~/.config/omni/ ] && mkdir -p ~/.config/omni/
    cp ~/omni/omniconfig.yaml ~/.config/omni/config
    echo "Copied omniconfig file from ~/omni"
else
    echo "No omniconfig file found. Clone the kenlasko/omni repo to get this file"
fi

# Get the Ansible hosts file from the k8s repo
if [ -f ~/k8s/ansible/resources/hosts ]; then
    [ ! -d /etc/ansible ] && sudo mkdir -p /etc/ansible
    sudo cp ~/k8s/ansible/resources/hosts /etc/ansible/hosts
    echo "Copied Ansible hosts file from ~/k8s"
else
    echo "No Ansible hosts file found. Clone the kenlasko/k8s repo to get this file"
fi