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
5. Copy SSH key from secret store to `~/.ssh/id_rsa`. Then setup for Git access
```
chmod 400 ~/.ssh/id_rsa
# Start ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

6. Clone all necessary repos
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
7. Symlink configuration.nix to Github synced folder
```
sudo mv /etc/nixos/ /etc/nixos-BAK/
sudo ln -s ~/nixos /etc/nixos
```
8. Build OS
```
sudo nixos-rebuild switch
```
