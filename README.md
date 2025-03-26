# Introduction
NixOS is a declarative OS that has a very similar philosophy to Kubernetes, where all configuration is declared in `.nix` files, and the OS will adjust to match that declaration.

This is my build process for NixOS running in Windows WSL, which is basically a VM running NixOS. It is designed for the following:
- Managing Kubernetes clusters via `kubectl` along with supporting tools, such as `talosctl`, `omnictl`, etc
- Building multi-arch Docker images for my UCDialplans.com website
- Support for VSCode Remote

It uses [Home Manager](https://nix-community.github.io/home-manager/) and [flakes](https://nixos-and-flakes.thiscute.world/) for maximum flexibility. 

I am still very new at this, so there could be lots of room for improvement!

# Prerequisites
You need to be running Windows and have the [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install) installed and ready to go. I imagine the config will work on other OS's but I haven't tried it.

# Installation
1. Install NixOS in WSL by downloading and double-clicking the latest `nixos.wsl` from https://github.com/nix-community/NixOS-WSL
2. Paste the following text into `%USERPROFILE%\.wslconfig` and save:
```
[user]
default = ken
```
3. Clone the NixOS repo and rebuild the OS
```
export NIX_CONFIG="experimental-features = nix-command flakes"
nix run nixpkgs#git -- clone https://github.com/kenlasko/nixos-wsl.git nixos
sudo cp -r nixos/* /etc/nixos
sudo nixos-rebuild switch
```
4. Exit and re-login. Should automatically login as `ken`
5. Copy SSH key from secret store to `~/.ssh/id_rsa`. Then setup for Git access
```
chmod 400 ~/.ssh/id_rsa
# Start ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```
6.  Download all necessary repos
```
git clone git@github.com:kenlasko/nixos-wsl.git nixos
git clone git@github.com:kenlasko/k8s.git
git clone git@github.com:kenlasko/k8s-lab.git
git clone git@github.com:kenlasko/k8s-cloud.git
git clone git@github.com:kenlasko/omni.git
git clone git@github.com:kenlasko/docker.git
git clone git@github.com:kenlasko/omni-public.git
git clone git@github.com:kenlasko/pxeboot.git
```
7. Symlink `/etc/nixos` to Github synced folder
```
sudo rm -rf /etc/nixos/
sudo ln -s ~/nixos /etc/nixos
```
8. Run the [nixos/scripts/copy-config.sh](scripts/copy-config.sh) script to copy kubectl/talosctl/omnictl configurations from outside the image. THIS IS SPECIFIC TO MY DEPLOYMENT AND WON'T APPLY TO YOU
```
./nixos/scripts/copy-config.sh
```
9. Finally, copy the `sealed-secret-signing-key.crt` into the user's home directory for use with Sealed Secrets. AGAIN, THIS IS SPECIFIC TO MY DEPLOYMENT AND WON'T APPLY TO YOU

# NixOS Handy Commands
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
