#!/usr/bin/env bash
# Pi Extensions Installer
# Install with: curl -LsSf https://raw.githubusercontent.com/tomcreutz/pi_extensions/main/install.sh | bash
#
# This script installs:
# - Required system dependencies (npm, bubblewrap, socat, ripgrep)
# - Pi coding agent (@mariozechner/pi-coding-agent)
# - This extensions package (@tomcreutz/pi_extensions)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
PI_PACKAGE="@mariozechner/pi-coding-agent"
EXTENSIONS_PACKAGE="@tomcreutz/pi_extensions"
EXTENSIONS_REPO="https://github.com/tomcreutz/pi_extensions.git"
MIN_NODE_VERSION=18

# Print functions
print_header() {
    echo -e "\n${BLUE}${BOLD}==>${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_ID_LIKE="${ID_LIKE:-$OS_ID}"
        OS_NAME="${PRETTY_NAME:-$OS_ID}"
    else
        print_error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi

    # Determine package manager and OS family
    if [[ "$OS_ID" == "arch" ]] || [[ "$OS_ID" == "cachyos" ]] || [[ "$OS_ID_LIKE" == *"arch"* ]]; then
        PKG_MANAGER="pacman"
        OS_FAMILY="arch"
    elif [[ "$OS_ID" == "ubuntu" ]] || [[ "$OS_ID" == "debian" ]] || [[ "$OS_ID_LIKE" == *"debian"* ]] || [[ "$OS_ID_LIKE" == *"ubuntu"* ]]; then
        PKG_MANAGER="apt"
        OS_FAMILY="debian"
    else
        print_error "Unsupported OS: $OS_NAME"
        print_info "This installer supports Ubuntu, Debian, Arch Linux, and CachyOS."
        exit 1
    fi

    print_info "Detected OS: $OS_NAME ($OS_FAMILY family)"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        SUDO=""
        print_warning "Running as root"
    else
        SUDO="sudo"
        # Check if sudo is available
        if ! command -v sudo &> /dev/null; then
            print_error "sudo is required but not installed. Please run as root or install sudo."
            exit 1
        fi
    fi
}

# Install package based on OS
install_package() {
    local pkg_debian="$1"
    local pkg_arch="$2"

    case "$OS_FAMILY" in
        debian)
            $SUDO apt-get install -y "$pkg_debian"
            ;;
        arch)
            $SUDO pacman -S --noconfirm --needed "$pkg_arch"
            ;;
    esac
}

# Update package manager cache
update_package_cache() {
    print_header "Updating package cache"
    case "$OS_FAMILY" in
        debian)
            $SUDO apt-get update
            ;;
        arch)
            $SUDO pacman -Sy
            ;;
    esac
    print_success "Package cache updated"
}

# Check and install Node.js/npm
check_nodejs() {
    print_header "Checking Node.js and npm"
    
    if command -v node &> /dev/null; then
        local node_version
        node_version=$(node -v | sed 's/v//' | cut -d. -f1)
        if [[ "$node_version" -ge "$MIN_NODE_VERSION" ]]; then
            print_success "Node.js $(node -v) is installed"
        else
            print_warning "Node.js version $(node -v) is too old. Minimum required: v$MIN_NODE_VERSION"
            install_nodejs
        fi
    else
        print_info "Node.js not found. Installing..."
        install_nodejs
    fi

    if command -v npm &> /dev/null; then
        print_success "npm $(npm -v) is installed"
    else
        print_error "npm not found after Node.js installation"
        exit 1
    fi
}

install_nodejs() {
    case "$OS_FAMILY" in
        debian)
            # Use NodeSource for newer Node.js on Debian/Ubuntu
            print_info "Installing Node.js from NodeSource..."
            $SUDO apt-get install -y ca-certificates curl gnupg
            $SUDO mkdir -p /etc/apt/keyrings
            curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | $SUDO gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
            echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | $SUDO tee /etc/apt/sources.list.d/nodesource.list
            $SUDO apt-get update
            $SUDO apt-get install -y nodejs
            ;;
        arch)
            $SUDO pacman -S --noconfirm --needed nodejs npm
            ;;
    esac
    print_success "Node.js installed: $(node -v)"
}

# Check and install bubblewrap
check_bubblewrap() {
    print_header "Checking bubblewrap"
    
    if command -v bwrap &> /dev/null; then
        print_success "bubblewrap is installed: $(bwrap --version 2>&1 | head -1)"
    else
        print_info "bubblewrap not found. Installing..."
        install_package "bubblewrap" "bubblewrap"
        print_success "bubblewrap installed"
    fi
}

# Check and install socat
check_socat() {
    print_header "Checking socat"
    
    if command -v socat &> /dev/null; then
        print_success "socat is installed: $(socat -V 2>&1 | head -1)"
    else
        print_info "socat not found. Installing..."
        install_package "socat" "socat"
        print_success "socat installed"
    fi
}

# Check and install ripgrep
check_ripgrep() {
    print_header "Checking ripgrep"
    
    if command -v rg &> /dev/null; then
        print_success "ripgrep is installed: $(rg --version | head -1)"
    else
        print_info "ripgrep not found. Installing..."
        install_package "ripgrep" "ripgrep"
        print_success "ripgrep installed"
    fi
}

# Install pi coding agent
install_pi() {
    print_header "Installing pi coding agent"
    
    if npm list -g "$PI_PACKAGE" &> /dev/null; then
        local current_version
        current_version=$(npm list -g "$PI_PACKAGE" --depth=0 2>/dev/null | grep "$PI_PACKAGE" | sed 's/.*@//')
        print_info "pi is already installed (version $current_version)"
        
        read -r -p "Do you want to update pi to the latest version? [y/N] " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            npm install -g "$PI_PACKAGE"
            print_success "pi updated"
        else
            print_info "Keeping current version"
        fi
    else
        npm install -g "$PI_PACKAGE"
        print_success "pi installed"
    fi
}

# Install extensions package using pi install
install_extensions() {
    print_header "Installing pi extensions"
    
    # Use pi install command for extensions
    print_info "Installing extensions via pi install..."
    pi install "$EXTENSIONS_REPO"
    print_success "Extensions installed"
}

# Show post-install configuration info
configure_pi() {
    print_header "Configuration"
    
    print_success "Extensions installed via 'pi install' are automatically configured!"
    print_info "You can manage installed packages with:"
    echo ""
    echo -e "  ${CYAN}pi list${NC}        - List installed packages"
    echo -e "  ${CYAN}pi uninstall${NC}   - Remove a package"
    echo ""
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  Installation Complete!${NC}"
    echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}Installed components:${NC}"
    echo -e "    • Node.js $(node -v)"
    echo -e "    • npm $(npm -v)"
    echo -e "    • bubblewrap $(bwrap --version 2>&1 | head -1 || echo 'installed')"
    echo -e "    • socat"
    echo -e "    • ripgrep $(rg --version | head -1 | cut -d' ' -f2)"
    echo -e "    • pi coding agent"
    echo -e "    • pi extensions ($EXTENSIONS_PACKAGE)"
    echo ""
    echo -e "  ${BOLD}Available extensions:${NC}"
    echo -e "    • ${CYAN}brave-search${NC} - Web search with Brave Search API"
    echo -e "    • ${CYAN}guardrails${NC} - Safety guardrails for AI operations"
    echo -e "    • ${CYAN}sandbox${NC} - Secure sandboxed execution"
    echo -e "    • ${CYAN}plan-mode${NC} - Structured planning mode"
    echo ""
    echo -e "  ${BOLD}Next steps:${NC}"
    echo -e "    1. Set up your API keys (e.g., ANTHROPIC_API_KEY)"
    echo -e "    2. Run ${CYAN}pi${NC} to start the coding agent"
    echo ""
    echo -e "  ${BOLD}Documentation:${NC}"
    echo -e "    https://github.com/mariozechner/pi-coding-agent"
    echo -e "    https://github.com/tomcreutz/pi_extensions"
    echo ""
}

# Main installation flow
main() {
    echo -e "${BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║                                                           ║"
    echo "  ║   🥧  Pi Extensions Installer                             ║"
    echo "  ║                                                           ║"
    echo "  ║   This will install pi coding agent and extensions        ║"
    echo "  ║                                                           ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Detect OS and check permissions
    detect_os
    check_root

    # Update package cache
    update_package_cache

    # Check and install dependencies
    check_nodejs
    check_bubblewrap
    check_socat
    check_ripgrep

    # Install pi and extensions
    install_pi
    install_extensions

    # Configure pi
    configure_pi

    # Print summary
    print_summary
}

# Run main
main "$@"
