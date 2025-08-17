#!/bin/bash
# MacBook Pro 2011 Ubuntu Server Setup for Freqtrade
# This script has been split into separate components for better maintainability
# Run with: bash macbook-freqtrade-server-init.sh

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

echo "================================================"
echo "  MacBook Pro Freqtrade Server Setup"
echo "================================================"
echo ""

info "This setup has been split into two separate scripts:"
echo ""
echo "1. 🖥️  macbook-server-setup.sh"
echo "   - System preparation and hardening"
echo "   - Network, SSH, firewall, Docker installation"
echo "   - One-time server setup"
echo ""
echo "2. 🤖 freqtrade-install.sh"
echo "   - Freqtrade application installation"
echo "   - Docker compose setup and configuration"
echo "   - Can be run multiple times or on different systems"
echo ""

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_SCRIPT="$SCRIPT_DIR/../system/macbook-server-setup.sh"
APP_SCRIPT="$SCRIPT_DIR/../applications/freqtrade-install.sh"

# Check if the separated scripts exist
if [ ! -f "$SYSTEM_SCRIPT" ] || [ ! -f "$APP_SCRIPT" ]; then
    error "Required scripts not found. Please ensure you're running from the homelab-scripts directory structure."
fi

echo "📋 Recommended execution order:"
echo ""
echo "   bash system/macbook-server-setup.sh      # First time only"
echo "   bash applications/freqtrade-install.sh   # Install Freqtrade"
echo ""

read -p "Would you like to run both scripts now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Starting server setup..."
    bash "$SYSTEM_SCRIPT"
    echo ""
    log "Starting Freqtrade installation..."
    bash "$APP_SCRIPT"
    echo ""
    log "Complete setup finished!"
else
    info "Run the scripts individually when ready:"
    echo "   bash system/macbook-server-setup.sh"
    echo "   bash applications/freqtrade-install.sh"
fi

echo "================================================"