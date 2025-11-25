#!/bin/sh
echo "Updating repos"
cd ~

# List of repos in the format "git_url local_dir"
repos=(
    "git@github.com:kenlasko/nixos-wsl.git nixos"
    "git@github.com:kenlasko/k8s.git k8s"
    "git@github.com:kenlasko/omni.git omni"
    "git@github.com:kenlasko/docker.git docker"
    "git@github.com:kenlasko/pxeboot.git pxeboot"
)

for repo in "${repos[@]}"; do
    url=$(echo $repo | awk '{print $1}')
    dir=$(echo $repo | awk '{print $2}')

    if [ -d "$dir/.git" ]; then
        echo "Updating $dir..."
        cd "$dir" && git pull && cd ..
    else
        echo "Cloning $dir..."
        git clone "$url" "$dir"
    fi
done
