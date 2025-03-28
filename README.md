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

You will have to modify the `.nix` files to change any references to `ken` (unless you happen to be named Ken). You will also have to generate a `secrets.yaml` with any relevant secrets, and modify the [sops.nix](config/sops.nix), [.sops.yaml](.sops.yaml) and any other files where those secrets will be referenced. Read [Configuring SOPS](#Configuring-SOPS) for details.


# Installation
1. Install NixOS in WSL by downloading the latest `nixos.wsl` from https://github.com/nix-community/NixOS-WSL and double-clicking the `nixos.wsl` file.

2. Paste the following text into your local host's `%USERPROFILE%\.wslconfig` and save (replace with your desired name):
```
[user]
default = ken
```

3. Copy the SOPS `keys.txt` into what will be the default user's `~/.config/sops/age` folder. For instructions on setting up SOPS and age, see [Configuring SOPS](#Configuring-SOPS)
```
sudo mkdir -p /home/ken/.config/sops/age
sudo chown -R nixos:users /home/ken
# Copy the keys.txt file using whatever method works
nano /home/ken/.config/sops/age/keys.txt
```

4. Rebuild the OS using the Github repo as a source. 

> [!WARNING]
> You will probably not want to do this before modifying some key files. Instead, clone the repo into `/etc/nixos` and make any necessary changes: `nix run nixpkgs#git -- clone https://github.com/kenlasko/nixos-wsl.git nixos && sudo rm -rf /etc/nixos/* && sudo cp -r nixos/* /etc/nixos`

```
sudo nixos-rebuild switch --flake github:kenlasko/nixos-wsl
```

5. Exit and re-login. Should automatically login as `ken`

6. Reset the permissions on `.config`, `.ssh` and `.kube` directories. These maintain the root perms set during initial setup, even though the rest of the folders have the correct permissions.
```
# Fix permissions for the .ssh .config and .kube directories
sudo chown -R ${USER}:users ~/.ssh ~/.config ~/.kube
```
---

> [!WARNING]
> From this point forward, these instructions are specific to my deployment. They won't apply to anybody else other than me.

7. Run the [nixos/scripts/cleanup.sh](scripts/cleanup.sh) script to perform final setup and cleanup tasks. 
```
~/nixos/scripts/cleanup.sh
```

# Configuring SOPS
SOPS allows you to store secrets such as SSH keys and passwords securely in your Git repo, much like Sealed Secrets does for Kubernetes. SOPS utilizes `age` to encrypt the secrets. All encrypted secrets are stored in [~/config/secrets.yaml](/config/secrets.yaml).

Here's the configuration steps for first-time users. This assumes a clean NixOS distribution with no prior configuration:

1. Generating age private key. 
```
mkdir -p ~/.config/sops/age
export NIX_CONFIG="experimental-features = nix-command flakes"
nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt  # Generate private key
```
2. Open `.config/sops/age/keys.txt` and copy the public key value. Save `~/.config/sops/age/keys.txt` somewhere secure and NOT in the Git repo. If you lose this, you will not be able to decrypt files encrypted with SOPS.
```
# created: 2025-03-28T12:57:52Z
# public key: age1jmeardw5auuj5m6yll49cpxtvge8cklltk9tlmy24xdre3wal4dq5vek65    <--- Copy this (but without the `# public key:` part)
AGE-SECRET-KEY-1QCX332PRGV7GA6R8MJZ7CDU7S9Y5G7J0FU8U0L9PL5DUV835R7YQC7DDU5
```
3. Create a file called `.sops.yaml` using the template below, and paste the public key into it
```
keys:
  - &primary age1jmeardw5auuj5m6yll49cpxtvge8cklltk9tlmy24xdre3wal4dq5vek65
creation_rules:
  - path_regex: config/secrets.yaml$
    key_groups:
    - age:
      - *primary
```

4. Edit [.sops.yaml](.sops.yaml) and replace the primary key with the public key from the new `keys.txt`
5. Make a temporary `config` directory
```
mkdir config
```
6. Run the following command to open a nix shell with `sops` in it. 

```
export NIX_CONFIG="experimental-features = nix-command flakes"
nix shell nixpkgs#sops 
```

7. Create a default `secrets.yaml` by running the below command. SOPS will create a default `secrets.yaml` with some sample content. Remove the sample content, add all desired secrets and save. SOPS will encrypt the contents automatically using the `keys.txt` created earlier.
```
sops --config .sops.yaml config/secrets.yaml
```
8. Verify that `secrets.yaml` is encrypted by running the below command:
```
cat config/secrets.yaml
```
9. Save all modified content:
- `~/.config/sops/age/keys.txt` - save somewhere secure and NOT in the Git repo. If you lose this, you will not be able to decrypt files encrypted with SOPS.
- `~/.sops.yaml` - this will replace the `.sops.yaml` at the root of the repo
- `config/secrets.yaml` - this will replace the `config/secrets.yaml` in the repo


# NixOS Handy Commands
## Full Rebuild
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
