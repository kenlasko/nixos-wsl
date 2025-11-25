# Introduction
This is a variation of my install docs for NixOS, but running in a dedicated VM instead of in Windows WSL.

## Initial steps
1. Create the NixOS VM using the latest [NixOS ISO](https://nixos.org/download/#). Give the VM at least 2GB of RAM and 100GB of disk space
2. Copy your SOPS `keys.txt` that's been saved somewhere secure and **NOT in the Git repo** into what will be the default users `~/.config/sops/age` folder. For new installations of SOPS and age, see [Configuring SOPS](#Configuring-SOPS)
```bash
sudo mkdir -p /home/ken/.config/sops/age
sudo chown -R nixos:users /home/ken
# Copy the keys.txt file using whatever method works
nano /home/ken/.config/sops/age/keys.txt
```

## Mount the data disk
A typical NixOS clean install from ISO won't mount the disk you created for it. The normal install will try to use tmpfs and run out of space. Use this process to mount the disk:

1. Get the name of the disk by running:
```bash
lsblk -f
```

2. Create the disk partition (assuming the disk is `sda`):
```bash
sudo parted /dev/sda -- mklabel gpt
sudo parted /dev/sda -- mkpart primary 1MiB 3MiB
sudo parted /dev/sda -- set 1 bios_grub on
sudo parted /dev/sda -- mkpart primary 3MiB 503MiB
sudo parted /dev/sda -- mkpart primary 503MiB 100%
```

3. Format the partitions
```bash
sudo mkfs.vfat -n NIXBOOT /dev/sda2
sudo mkfs.ext4 -L NIXROOT /dev/sda3
```

4. Mount the partitions
```bash
sudo mount /dev/disk/by-label/NIXROOT /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
```

## Build the OS
1. Build the OS using the Github repo as a source. 

> [!WARNING]
> You will probably not want to do this unless you are me. Instead, you should clone the repo into `/etc/nixos`:
> ```bash
> export NIX_CONFIG="experimental-features = nix-command flakes"
> nix run nixpkgs#git -- clone https://github.com/kenlasko/nixos-wsl.git nixos && sudo rm -rf /etc/nixos/* && sudo cp -r nixos/* /etc/nixos`
> ``` 
> and make any necessary changes to usernames (in `flake.nix`, `config/git.nix` and `config/home-manager.nix`) and secret references (in `config/sops.nix`) and replace `.sops.yaml` and `config/secrets.nix` with your own. 
>
> If you are me, then go ahead and run this ⬇️

```bash
sudo nixos-install --flake github:kenlasko/nixos-wsl#nas01 --root /mnt
```

4. Reboot. Should automatically login as `ken` using private key. Then run:
```bash
sudo nixos-rebuild switch --flake github:kenlasko/nixos-wsl#nas01 --refresh
```