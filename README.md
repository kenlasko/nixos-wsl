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
5. Temporarily install Git
```
nix-env -i git
```
7.  Clone the NixOS repo
```
git config --global user.email "ken.lasko@gmail.com"
git config --global user.name "Ken Lasko"
git clone git@github.com:kenlasko/nixos-wsl.git nixos
sudo cp -r nixos/* /etc/nixos
```
6. Build OS
```
sudo nixos-rebuild switch
```
7. Exit and re-login

9. Ensure you're logged in as ken and re-add key and repos
```
mkdir .ssh
cp /home/nixos/.ssh/* ~/.ssh
chmod 400 ~/.ssh/id_rsa
# Start ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
git clone git@github.com:kenlasko/nixos-wsl.git nixos
git clone git@github.com:kenlasko/k8s.git
git clone git@github.com:kenlasko/k8s-lab.git
git clone git@github.com:kenlasko/k8s-cloud.git
git clone git@github.com:kenlasko/omni.git
git clone git@github.com:kenlasko/docker.git
git clone git@github.com:kenlasko/omni-public.git
git clone git@github.com:kenlasko/pxeboot.git
```
8. Symlink configuration.nix to Github synced folder
```
sudo mv /etc/nixos/ /etc/nixos-BAK/
sudo ln -s ~/nixos /etc/nixos
```
10. Run the [nixos/scripts/copy-config.sh](scripts/copy-config.sh) script to copy kubectl/talosctl/omnictl configurations from outside the image
```
chmod u+x nixos/scripts/copy-config.sh
./nixos/scripts/copy-config.sh
```
11. Finally, copy the `sealed-secret-signing-key.crt` into the user's home directory

# NixOS Commands
## Rebuild
```
sudo nixos-rebuild switch --recreate-lock-file --flake .
```
## Delete all historical versions older than 7 days
```
sudo nix profile wipe-history --older-than 7d --profile /nix/var/nix/profiles/system
```

## Garbage Collection
```
sudo nix-collect-garbage --delete-old
nix-collect-garbage --delete-old
```

# Troubleshooting
## Opening terminal throws error
Edit the terminal profile and set the path to:
```
C:\WINDOWS\system32\wsl.exe -d nixos
```

## Git Push from VSCode fails
If you get `Host key verification failed. fatal: Could not read from remote repository.` when trying to push a git update to the remote repo, try this:
1. From VSCode, open a terminal and type:
```
git push
```
2. Answer yes to any questions you get.
