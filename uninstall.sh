#!/usr/bin/env bash
# Pi Extensions Uninstaller
# Removes pi coding agent and extensions (keeps system dependencies)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PI_PACKAGE="@mariozechner/pi-coding-agent"
EXTENSIONS_PACKAGE="@tomcreutz/pi_extensions"

print_header() {
    echo -e "\n${BLUE}${BOLD}==>${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

main() {
    echo -e "${BOLD}"
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║                                                           ║"
    echo "  ║   🥧  Pi Extensions Uninstaller                           ║"
    echo "  ║                                                           ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    print_warning "This will uninstall pi coding agent and extensions."
    print_info "System dependencies (Node.js, bubblewrap, socat, ripgrep) will NOT be removed."
    echo ""
    read -r -p "Are you sure you want to continue? [y/N] " response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Uninstallation cancelled."
        exit 0
    fi

    print_header "Uninstalling extensions package"
    # Use pi uninstall command
    if command -v pi &> /dev/null; then
        pi uninstall "$EXTENSIONS_PACKAGE" 2>/dev/null && \
            print_success "Extensions package uninstalled" || \
            print_info "Extensions package not installed or already removed"
    else
        print_info "pi not found, skipping extensions uninstall"
    fi

    print_header "Uninstalling pi coding agent"
    read -r -p "Also uninstall pi coding agent? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if npm list -g "$PI_PACKAGE" &> /dev/null; then
            npm uninstall -g "$PI_PACKAGE"
            print_success "Pi coding agent uninstalled"
        else
            print_info "Pi coding agent not installed"
        fi
    else
        print_info "Keeping pi coding agent"
    fi

    print_header "Configuration"
    local pi_config_file="$HOME/.config/pi/config.json"
    if [[ -f "$pi_config_file" ]]; then
        read -r -p "Remove pi config file? [y/N] " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -f "$pi_config_file"
            print_success "Config file removed"
        else
            print_info "Keeping config file at $pi_config_file"
        fi
    fi

    echo ""
    print_success "Uninstallation complete!"
    echo ""
}

main "$@"
