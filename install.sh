#!/bin/bash
# AwesomeWM Dotfiles Installation Script
# Author: ミツキナノカ (nhktmdzhg)
# Description: Automated installer for AwesomeWM desktop environment
# Version: 2.0

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="$SCRIPT_DIR/install.log"
readonly BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Print functions
print_header() {
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}           AwesomeWM Dotfiles Installation Script${NC}"
    echo -e "${WHITE}                    ミツキナノカ's Setup${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════${NC}"
    echo
}

print_step() {
    echo -e "${CYAN}➤ $1${NC}"
    log "STEP: $1"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    log "SUCCESS: $1"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
    log "WARNING: $1"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
    log "ERROR: $1"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
    log "INFO: $1"
}

# Check if running on Arch Linux
check_system() {
    print_step "Checking system compatibility..."
    
    if ! command -v pacman >/dev/null 2>&1; then
        print_error "This script requires Arch Linux or an Arch-based distribution"
        exit 1
    fi
    
    if [[ $EUID -eq 0 ]]; then
        print_error "Do not run this script as root!"
        exit 1
    fi
    
    print_success "System check passed - Arch Linux detected"
}

# Create backup of existing configurations
create_backup() {
    print_step "Creating backup of existing configurations..."
    
    local backup_needed=false
    local configs_to_backup=(
        ".config/awesome"
        ".config/picom.conf"
        ".config/dunst"
        ".config/rofi"
        ".xinitrc"
        ".Xresources"
        ".gtkrc-2.0"
    )
    
    for config in "${configs_to_backup[@]}"; do
        if [[ -e "$HOME/$config" ]]; then
            backup_needed=true
            break
        fi
    done
    
    if [[ "$backup_needed" == true ]]; then
        mkdir -p "$BACKUP_DIR"
        for config in "${configs_to_backup[@]}"; do
            if [[ -e "$HOME/$config" ]]; then
                cp -r "$HOME/$config" "$BACKUP_DIR/" 2>/dev/null || true
                print_info "Backed up: $config"
            fi
        done
        print_success "Backup created at: $BACKUP_DIR"
    else
        print_info "No existing configurations found - backup skipped"
    fi
}

# Install AUR helper
install_aur_helper() {
    print_step "Checking for AUR helper..."
    
    local aur_helpers=("paru" "yay" "trizen" "pikaur")
    local aur_helper=""
    
    for helper in "${aur_helpers[@]}"; do
        if command -v "$helper" >/dev/null 2>&1; then
            aur_helper="$helper"
            break
        fi
    done
    
    if [[ -z "$aur_helper" ]]; then
        print_info "No AUR helper found. Installing paru..."
        
        # Install dependencies
        sudo pacman -S --needed --noconfirm base-devel git
        
        # Clone and install paru
        local temp_dir
        temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        git clone https://aur.archlinux.org/paru-bin.git
        cd paru-bin
        makepkg -si --noconfirm
        
        cd "$SCRIPT_DIR"
        rm -rf "$temp_dir"
        
        aur_helper="paru"
        print_success "Paru installed successfully"
    else
        print_success "Found AUR helper: $aur_helper"
    fi
    
    echo "$aur_helper"
}

# Install packages from pkgs.txt
install_packages() {
    local aur_helper="$1"
    print_step "Installing packages from pkgs.txt..."
    
    if [[ ! -f "$SCRIPT_DIR/pkgs.txt" ]]; then
        print_error "pkgs.txt not found in $SCRIPT_DIR"
        return 1
    fi
    
    local packages=()
    local pkg_count=0
    
    # Read packages from file
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Remove comments and whitespace
        line=$(echo "$line" | sed 's/#.*$//' | xargs)
        
        # Skip empty lines
        if [[ -n "$line" ]]; then
            packages+=("$line")
            ((pkg_count++))
        fi
    done < "$SCRIPT_DIR/pkgs.txt"
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        print_warning "No valid packages found in pkgs.txt"
        return 0
    fi
    
    print_info "Found $pkg_count packages to install"
    
    # Install packages
    print_info "Installing packages with $aur_helper..."
    if "$aur_helper" -S --needed --noconfirm "${packages[@]}"; then
        print_success "All packages installed successfully"
    else
        print_error "Some packages failed to install"
        return 1
    fi
}

install_st() {
    echo "Installing st..."
    git clone https://github.com/nhktmdzhg/st-config.git
    cd st-config
    make clean && make
    sudo make install
    cd ..
    rm -rf st-config
}

# Copy configuration files
install_configs() {
    print_step "Installing configuration files..."
    
    local source_dir="$SCRIPT_DIR/home/username"
    
    if [[ ! -d "$source_dir" ]]; then
        print_error "Configuration directory not found: $source_dir"
        return 1
    fi
    
    # Copy files with progress
    print_info "Copying configuration files..."
    if cp -rf "$source_dir"/. "$HOME/"; then
        print_success "Configuration files copied successfully"
    else
        print_error "Failed to copy configuration files"
        return 1
    fi
    
    # Set proper permissions
    print_info "Setting proper permissions..."
    chmod +x "$HOME/.config/awesome/xss-lock-tsl.sh" 2>/dev/null || true
    chmod +x "$HOME/.xinitrc" 2>/dev/null || true
    
    print_success "Permissions set successfully"
}

# Post-installation tasks
post_install() {
    print_step "Running post-installation tasks..."
    
    # Update font cache
    if command -v fc-cache >/dev/null 2>&1; then
        print_info "Updating font cache..."
        fc-cache -fv >/dev/null 2>&1
        print_success "Font cache updated"
    fi
    
    # Create wallpaper directory
    mkdir -p "$HOME/wallpaper"
    print_info "Created wallpaper directory: ~/wallpaper"
    
    print_success "Post-installation tasks completed"
}

# Display final instructions
show_final_message() {
    echo
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                    Installation Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "  1. ${CYAN}Log out and log back in${NC}"
    echo -e "  2. ${CYAN}Select 'AwesomeWM' from your display manager${NC}"
    echo -e "  3. ${CYAN}Add wallpapers to ~/wallpaper/ directory${NC}"
    echo
    echo -e "${YELLOW}Useful commands:${NC}"
    echo -e "  • ${CYAN}Super${NC} - Open application launcher"
    echo -e "  • ${CYAN}Super + Ctrl + R${NC} - Reload AwesomeWM"
    echo -e "  • ${CYAN}Super + Esc${NC} - Session menu"
    echo
    echo -e "${BLUE}Installation log: $LOG_FILE${NC}"
    if [[ -d "$BACKUP_DIR" ]]; then
        echo -e "${BLUE}Backup location: $BACKUP_DIR${NC}"
    fi
    echo
    echo -e "${PURPLE}Made with 💙 by ミツキナノカ${NC}"
    echo
}

# Cleanup function
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        print_error "Installation failed! Check $LOG_FILE for details."
    fi
    exit $exit_code
}

# Main installation function
main() {
    # Set up error handling
    trap cleanup EXIT
    
    # Clear log file
    : > "$LOG_FILE"
    
    # Start installation
    print_header
    
    check_system
    create_backup
    local aur_helper
    aur_helper=$(install_aur_helper)
    install_packages "$aur_helper"
    install_st
    install_configs
    post_install
    show_final_message
    
    print_success "Installation completed successfully!"
}

# Run main function
main "$@"
