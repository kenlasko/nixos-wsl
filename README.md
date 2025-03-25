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
9. Exit and re-login
10. Use this script to copy kubectl/talosctl/omnictl configurations from outside the image
```
# Get the WSL host path for the logged-in user
HOSTPATH=$(echo "$WSLPATH" | grep -oP '(/mnt/\w/Users/\w+)' | head -1)

# Ensure ~/.kube directory exists, then copy the config file
if [ -f "$HOSTPATH/.kube/config" ]; then
    [ ! -d ~/.kube ] && mkdir -p ~/.kube 
    cp "$HOSTPATH/.kube/config" ~/.kube/config
else
    echo "No kubeconfig file found in $HOSTPATH"
fi

# Repeat for talosctl and omnictl
if [ -f "~/omni/talosconfig.yaml" ]; then
    [ ! -d ~/.talos ] && mkdir -p ~/.talos 
    cp "~/omni/talosconfig.yaml" ~/.talos/config
else
    echo "No talosconfig file found. Clone the kenlasko/omni repo to get this file"
fi

if [ -f "~/omni/omniconfig.yaml" ]; then
    [ ! -d ~/.config/omni/ ] && mkdir -p ~/.config/omni/
    cp "~/omni/omniconfig.yaml" ~/.config/omni/config
else
    echo "No omniconfig file found. Clone the kenlasko/omni repo to get this file"
fi
```

# Troubleshooting
## Git Push from VSCode fails
If you get `Host key verification failed. fatal: Could not read from remote repository.` when trying to push a git update to the remote repo, try this:
1. From VSCode, open a terminal and type:
```
git push
```

Answer yes to any questions you get.
