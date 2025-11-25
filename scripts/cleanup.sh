#!/bin/sh

echo "Fixing permissions on .ssh, .config, and .kube directories"
sudo chown -R ${USER}:users .ssh .config .kube

echo "Cloning private repos"
cd ~
git clone git@github.com:kenlasko/nixos-wsl.git nixos
git clone git@github.com:kenlasko/k8s.git
git clone git@github.com:kenlasko/omni.git
git clone git@github.com:kenlasko/docker.git
git clone git@github.com:kenlasko/pxeboot.git

# Symlink `/etc/nixos` to Github synced folder. Done so we can easily save config in Git
echo "Symlink `/etc/nixos` to Github synced folder."
sudo rm -rf /etc/nixos/
sudo ln -s ~/nixos /etc/nixos

# Delete the no longer needed nixos home directory
echo "Deleting /home/nixos directory"
sudo rm -rf /home/nixos