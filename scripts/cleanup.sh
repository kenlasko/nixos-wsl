#!/bin/sh
echo "Cloning private repos"
cd ~
git clone git@github.com:kenlasko/nixos-wsl.git nixos
git clone git@github.com:kenlasko/k8s.git
git clone git@github.com:kenlasko/k8s-lab.git
git clone git@github.com:kenlasko/k8s-cloud.git
git clone git@github.com:kenlasko/omni.git
git clone git@github.com:kenlasko/docker.git
git clone git@github.com:kenlasko/omni-public.git
git clone git@github.com:kenlasko/pxeboot.git
git clone git@github.com:kenlasko/k8s-bootstrap.git terraform

echo "Fixing permissions on .ssh, .config, and .kube directories"
sudo chown -R ${USER}:users .ssh .config .kube

# Symlink `/etc/nixos` to Github synced folder. Done so we can easily save config in Git
echo "Symlink `/etc/nixos` to Github synced folder."
sudo rm -rf /etc/nixos/
sudo ln -s ~/nixos /etc/nixos

# Get the Ansible hosts file from the k8s repo
if [ -f ~/k8s/ansible/resources/hosts ]; then
    [ ! -d /etc/ansible ] && sudo mkdir -p /etc/ansible
    sudo cp ~/k8s/ansible/resources/hosts /etc/ansible/hosts
    echo "Copied Ansible hosts file from ~/k8s"
else
    echo "No Ansible hosts file found. Clone the kenlasko/k8s repo to get this file"
fi

# Delete the no longer needed nixos home directory
echo "Deleting /home/nixos directory"
sudo rm -rf /home/nixos