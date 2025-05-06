# Introduction
NixOS is a declarative OS that has a very similar philosophy to Kubernetes, where all configuration is declared in `.nix` files, and the OS will adjust to match that declaration.

This is my build process for NixOS running in Windows WSL, which is basically a VM running NixOS. It uses [Home Manager](https://nix-community.github.io/home-manager/) and [flakes](https://nixos-and-flakes.thiscute.world/) for maximum flexibility.  It is **EXTREMELY** opinionated, in that the packages are relevant to my specific working environment, which is built around the following technologies:
- [kubectl](https://github.com/kubernetes/kubectl) - for managing Kubernetes resources
- [talosctl](https://github.com/siderolabs/talos/) - for managing Talos-based machines used for my Kubernetes clusters
- [omnictl](https://github.com/siderolabs/omni) - for managing my Kubernetes clusters
- [docker](https://docs.docker.com/) - for building multi-arch Docker images, and occasional tests of new containers
- [opentofu](https://opentofu.org/) - for [bootstrapping new Kubernetes clusters](https://github.com/kenlasko/k8s-bootstrap)
- [support for VSCode Remote](https://github.com/nix-community/nixos-vscode-server)
- Additional supporting tools such as 
    - [K9S](https://github.com/derailed/k9s) - kubectl TUI
    - [kubeseal](https://github.com/bitnami-labs/sealed-secrets) - for secure online storage of Kubernetes secrets
    - [cilium-cli](https://github.com/cilium/cilium) - for managing/troubleshooting Cilium networking
    - [kubent](https://github.com/doitintl/kube-no-trouble) - for checking for Kubernetes upgrade issues
    - [popeye](https://github.com/derailed/popeye) - Kubernetes resource linter

Your needs will certainly differ from this, but it should give you a very good starting point. I am still very new at this and there's a lot of nuances I don't fully understand, so there could be lots of room for improvement!

## Related Repositories
Links to my other repositories mentioned or used in this repo:
- [K8s Bootstrap](https://github.com/kenlasko/k8s-bootstrap): Bootstraps Kubernetes clusters with essential apps using Terraform/OpenTofu
- [K8s Cluster Configuration](https://github.com/kenlasko/k8s): Manages Kubernetes cluster manifests and workloads.
- [Omni](https://github.com/kenlasko/omni): Creates and manages the Kubernetes clusters.

# Prerequisites
You need to be running Windows and have the [Windows Subsystem for Linux (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install) installed and ready to go. I imagine the config will work on other OS's but I haven't tried it.

This repo uses [SOPS](https://github.com/Mic92/sops-nix) to securely encrypt secret information. Read [Configuring SOPS](#Configuring-SOPS) for details. You will require your own unique versions of the following files:
- `keys.txt` for secure secrets encryption using SOPS and age (see [Configuring SOPS](#Configuring-SOPS) for instructions on how to generate)
- [.sops.yaml](.sops.yaml) for defining the SOPS configuration
- [secrets.yaml](config/secrets.yaml) for securely storing secrets
- [sops.nix](config/sops.nix) for referencing secrets in NixOS


# NixOS Base Installation
1. Download the latest `nixos.wsl` from https://github.com/nix-community/NixOS-WSL 

2. Install NixOS by either:
    1. using default settings by double-clicking the downloaded `nixos.wsl` file.
    2. if you already have NixOS, install a second distribution by running something like:
    ```
    wsl --import <Name-For-Distribution> c:\<location-to-put-image> <path-to-downloaded-nixos.wsl>
    ```
    Example:
    ```
    wsl --import NixOS-Test c:\wsl\nixos-test "C:\Users\klasko\Downloads\nixos.wsl"
    ```


# NixOS Configuration
1. Run NixOS, by either selecting it from your Windows Terminal interface (should be at the bottom), or by running the following command from your Windows Terminal:
```
wsl -d <Name of distribution ie NixOS> --cd ~
```

2. Copy your SOPS `keys.txt` into what will be the default users `~/.config/sops/age` folder. For instructions on setting up SOPS and age, see [Configuring SOPS](#Configuring-SOPS)
```bash
sudo mkdir -p /home/ken/.config/sops/age
sudo chown -R nixos:users /home/ken
# Copy the keys.txt file using whatever method works
nano /home/ken/.config/sops/age/keys.txt
```

3. Rebuild the OS using the Github repo as a source. 

> [!WARNING]
> You will probably not want to do this unless you are me. Instead, you should clone the repo into `/etc/nixos`:
> ```bash
> export NIX_CONFIG="experimental-features = nix-command flakes"
> nix run nixpkgs#git -- clone https://github.com/kenlasko/nixos-wsl.git nixos && sudo rm -rf /etc/nixos/* && sudo cp -r nixos/* /etc/nixos`
> ``` 
> and make any necessary changes to usernames (in `flake.nix`, `config/git.nix` and `config/home-manager.nix`) and secret references (in `config/sops.nix`) and replace `.sops.yaml` and `config/secrets.nix` with your own.

```bash
sudo nixos-rebuild switch --flake github:kenlasko/nixos-wsl
```

5. Exit and re-login. Should automatically login as `ken`

6. Reset the permissions on `.config`, `.ssh` and `.kube` directories. These maintain the root perms set during initial setup, even though the rest of the folders have the correct permissions.
```bash
# Fix permissions for the .ssh .config and .kube directories
sudo chown -R ${USER}:users ~/.ssh ~/.config ~/.kube
```
---

> [!WARNING]
> From this point forward, these instructions are specific to my deployment. They won't apply to anybody else other than me.

7. Run the [nixos/scripts/cleanup.sh](scripts/cleanup.sh) script to perform final setup and cleanup tasks. 
```bash
~/nixos/scripts/cleanup.sh
```


# Configuring SOPS
[SOPS](https://github.com/Mic92/sops-nix) allows you to store secrets such as SSH keys and passwords securely in your Git repo, much like Sealed Secrets does for Kubernetes. SOPS utilizes `age` to encrypt the secrets. All encrypted secrets are stored in [~/config/secrets.yaml](/config/secrets.yaml).

Here's the configuration steps for first-time users. This assumes a clean NixOS distribution with no prior configuration:

1. Generating age private key. 
```bash
mkdir -p ~/.config/sops/age
export NIX_CONFIG="experimental-features = nix-command flakes"
nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt  # Generate private key
```
2. Open `.config/sops/age/keys.txt` and copy the public key value. Save `~/.config/sops/age/keys.txt` somewhere secure and **NOT in the Git repo**. (Mine is in Bitwarden). If you lose this, you will not be able to decrypt files encrypted with SOPS.
```bash
# created: 2025-03-28T12:57:52Z
# public key: age1jmeardw5auuj5m6yll49cpxtvge8cklltk9tlmy24xdre3wal4dq5vek65    <--- Copy this (but without the `# public key:` part)
AGE-SECRET-KEY-1QCX332PRGV7GA6R8MJZ7CDU7S9Y5G7J0FU8U0L9PL5DUV835R7YQC7DDU5
```
3. Create a file called `.sops.yaml` using the template below, and paste the public key into it
```yaml
keys:
  - &primary age1jmeardw5auuj5m6yll49cpxtvge8cklltk9tlmy24xdre3wal4dq5vek65
creation_rules:
  - path_regex: config/secrets.yaml$
    key_groups:
    - age:
      - *primary
```

4. Make a temporary `config` directory
```bash
mkdir config
```
5. Run the following command to open a nix shell with `sops` in it. 

```bash
export NIX_CONFIG="experimental-features = nix-command flakes"
nix shell nixpkgs#sops 
```

6. Create a default `secrets.yaml` by running the below command. SOPS will create a default `secrets.yaml` with some sample content. Remove the sample content, add all desired secrets and save. SOPS will encrypt the contents automatically using the `keys.txt` created earlier.
```bash
sops --config .sops.yaml config/secrets.yaml
```
7. Verify that `secrets.yaml` is encrypted by running the below command:
```bash
cat config/secrets.yaml
```
8. Save all modified content:
- `~/.config/sops/age/keys.txt` - save somewhere secure and **NOT in the Git repo**. If you lose this, you will not be able to decrypt files encrypted with SOPS.
- `~/.sops.yaml` - this will replace the `.sops.yaml` at the root of the repo
- `config/secrets.yaml` - this will replace the `config/secrets.yaml` in the repo


# NixOS Handy Commands
## Update packages
```
nix flake update
sudo nixos-rebuild switch
```

## Full Rebuild
```bash
sudo nixos-rebuild switch --recreate-lock-file --flake .
```
## Delete all historical versions older than 7 days
```bash
sudo nix profile wipe-history --older-than 7d --profile /nix/var/nix/profiles/system
```

## Garbage Collection
```bash
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
```bash
git push
```
2. Answer yes to any questions you get.
