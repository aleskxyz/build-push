#!/bin/bash

set -e
basic_packages=("buildah" "uidmap" "libcap2" "libcap2-bin" "podman")
multiarch_packages=("qemu" "binfmt-support" "qemu-user-static")
archs="${INPUT_ARCHS}"
platforms="${INPUT_PLATFORMS}"
missing_packages=()

# Validate input
if [ -n "$archs" ] && [ -n "$platforms" ]; then
    echo "::error::Both 'archs' and 'platforms' are set. Please specify only one."
    exit 1
fi

# Determine all required packages based on inputs
required_packages=("${basic_packages[@]}")
if [ -n "$archs" ] || [ -n "$platforms" ]; then
    required_packages+=("${multiarch_packages[@]}")
fi

# Check for missing packages
echo "::group::Checking Package Installation"
for pkg in "${required_packages[@]}"; do
    if ! dpkg -s "$pkg" &> /dev/null; then
        echo "Package $pkg is not installed."
        missing_packages+=("$pkg")
    else
        echo "Package $pkg is already installed."
    fi
done
echo "::endgroup::"

# If there are missing packages, update and install
if [ ${#missing_packages[@]} -ne 0 ]; then
    echo "::group::Updating package lists and installing missing packages"
    sudo apt-get update
    sudo apt-get -y install "${missing_packages[@]}"
    echo "::endgroup::"
else
    echo "All required packages are already installed."
fi

# Apply additional configurations
echo "::group::Applying Additional Configurations"
sudo setcap cap_setuid+eip /usr/bin/newuidmap
sudo setcap cap_setgid+eip /usr/bin/newgidmap
sudo chmod u-s /usr/bin/newuidmap
sudo chmod u-s /usr/bin/newgidmap
if [ ! -f ~/.local/share/containers/.clean ]; then
    sudo rm -rf ~/.local/share/containers/*
    mkdir -p ~/.local/share/containers/
    sudo touch ~/.local/share/containers/.clean
fi
echo -e "[storage]\ndriver = \"vfs\"" | sudo tee /etc/containers/storage.conf > /dev/null
mkdir -p "$HOME/.docker"
echo "::endgroup::"
echo "Configuration completed successfully."
