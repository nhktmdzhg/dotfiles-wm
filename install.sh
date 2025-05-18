#!/bin/sh

# Install AUR helper if not found
AUR_HELPER=$(command -v yay || command -v paru)
if [ -z "$AUR_HELPER" ]; then
    echo "No AUR helper found. Installing paru..."
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ..
    rm -rf paru
    AUR_HELPER=$(command -v paru)
fi

echo "Installing dependencies..."

# Read packages from pkgs.txt and install in one go
if [ -f "pkgs.txt" ]; then
    # Create an array of packages (skip comments and empty lines)
    packages=()
    while IFS= read -r pkg || [ -n "$pkg" ]; do
        pkg=$(echo "$pkg" | sed 's/#.*$//')  # Remove comments
        pkg=$(echo "$pkg" | xargs)           # Trim whitespace
        [ -n "$pkg" ] && packages+=("$pkg")  # Add to array if not empty
    done < "pkgs.txt"
    
    # Install all packages in one command if array is not empty
    if [ ${#packages[@]} -gt 0 ]; then
        echo "Installing packages: ${packages[*]}"
        $AUR_HELPER -S --needed --noconfirm "${packages[@]}"
    else
        echo "No valid packages found in pkgs.txt"
    fi
else
    echo "pkgs.txt not found. Skipping package installation."
fi

# Copy home directory contents
echo "Copying home directory contents..."
if [ -d "./home/username/" ]; then
    cp -rf ./home/username/. ~/
    echo "Home directory copied successfully."
else
    echo "./home/username/ not found. Skipping home directory copy."
fi

echo "All operations completed."

