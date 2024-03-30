#!/bin/bash

set -e
packages=("buildah" "uidmap" "libcap2" "libcap2-bin" "podman" "qemu" "binfmt-support" "qemu-user-static")
missing_packages=false

echo "::group::Checking Package Installation"
for pkg in "${packages[@]}"; do
    if ! dpkg -s "$pkg" &> /dev/null; then
        echo "Package $pkg is not installed."
        missing_packages=true
    else
        echo "Package $pkg is already installed."
    fi
done
echo "::endgroup::"

if [ "$missing_packages" = true ]; then
    echo "::group::Installing Missing Packages"
    sudo apt-get update
    sudo apt-get -y install "${packages[@]}"
    echo "::endgroup::"
else
    echo "All packages are already installed."
fi

echo "::group::Applying Additional Configurations"
sudo setcap cap_setuid+eip /usr/bin/newuidmap
sudo setcap cap_setgid+eip /usr/bin/newgidmap
sudo chmod u-s /usr/bin/newuidmap
sudo chmod u-s /usr/bin/newgidmap
sudo rm -rf ~/.local/share/containers/
echo -e "[storage]\ndriver = \"vfs\"" | sudo tee /etc/containers/storage.conf > /dev/null
mkdir -p "$HOME/.docker"
echo "::endgroup::"
echo "Configuration completed successfully."
