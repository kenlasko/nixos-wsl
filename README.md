# Installation
1. Install NixOS in WSL by downloading and double-clicking the latest `nixos.wsl` from https://github.com/nix-community/NixOS-WSL
2. Run the following in Windows to set the default username to ken:
```
notepad %USERPROFILE%\.wslconfig
```
3. Paste the following text into `%USERPROFILE%\.wslconfig` and save:
```
[user]
default = ken
```
4. Copy SSH key from secret store to `~/.ssh/id_rsa`. Then setup for Git access
```
chmod 400 ~/.ssh/id_rsa
# Start ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

5. Clone all necessary repos
```
git config --global user.email "ken.lasko@gmail.com"
git config --global user.name "Ken Lasko"
git clone git@github.com:kenlasko/nixos-wsl.git nixos
git clone git@github.com:kenlasko/k8s.git
git clone git@github.com:kenlasko/k8s-lab.git
git clone git@github.com:kenlasko/k8s-cloud.git
git clone git@github.com:kenlasko/omni.git
git clone git@github.com:kenlasko/docker.git
git clone git@github.com:kenlasko/omni-public.git
git clone git@github.com:kenlasko/pxeboot.git
```
6. Symlink configuration.nix to Github synced folder
```
sudo mv /etc/nixos/ /etc/nixos-BAK/
sudo ln -s ~/nixos /etc/nixos
```
7. Build OS
```
sudo nixos-rebuild switch
```
8. Exit and re-login
9. Run the [nixos/scripts/copy-config.sh](scripts/copy-config.sh) script to copy kubectl/talosctl/omnictl configurations from outside the image

# Updating NixOS
```
sudo nixos-rebuild switch --recreate-lock-file --flake .
```

# Troubleshooting
## Git Push from VSCode fails
If you get `Host key verification failed. fatal: Could not read from remote repository.` when trying to push a git update to the remote repo, try this:
1. From VSCode, open a terminal and type:
```
git push
```
2. Answer yes to any questions you get.
