#!/bin/bash
# MacBook Pro 2011 Ubuntu Server Setup
# System preparation and hardening script
# Run with: bash macbook-server-setup.sh
# Run with: bash macbook-server-setup.sh -v (verbose mode)

set -e  # Exit on error

# Get script directory for portable paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse command line arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-v|--verbose] [-h|--help]"
            echo "  -v, --verbose    Show detailed output"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

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
progress() { echo -ne "${BLUE}[⟳]${NC} $1... "; }
done_msg() { echo -e "${GREEN}Done!${NC}"; }

# Helper function for conditional output
run_quiet() {
    if [ "$VERBOSE" = "true" ]; then
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi
}

# Show mode
if [ "$VERBOSE" = "true" ]; then
    info "Running in VERBOSE mode"
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "Don't run as root. Script will use sudo when needed."
fi

echo "================================================"
echo "  MacBook Pro Server Setup & Hardening"
echo "================================================"
echo ""

# ========================================
# 1. Network Configuration (DHCP)
# ========================================
progress "Checking network connectivity"
ETH_INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^en' | head -1)
if ! ip addr show $ETH_INTERFACE | grep -q "inet "; then
    sudo dhclient $ETH_INTERFACE 2>/dev/null || sudo dhcpcd $ETH_INTERFACE 2>/dev/null || sudo systemctl restart systemd-networkd
    sleep 3
fi

if ping -c 1 8.8.8.8 &> /dev/null; then
    IP_ADDR=$(ip -4 addr show $ETH_INTERFACE | grep inet | awk '{print $2}' | cut -d/ -f1)
    done_msg
    log "Network OK - IP: $IP_ADDR"
else
    error "No network connectivity. Please check ethernet cable."
fi

# ========================================
# 2. DNS Configuration
# ========================================
progress "Configuring DNS"
cat << EOF | sudo tee /etc/netplan/99-custom-dns.yaml > /dev/null
network:
  version: 2
  ethernets:
    $ETH_INTERFACE:
      dhcp4: true
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF
sudo chmod 600 /etc/netplan/99-custom-dns.yaml
run_quiet sudo netplan apply || true
done_msg

# ========================================
# 3. System Updates
# ========================================
progress "Updating system packages (this may take 2-5 minutes)"
if ! run_quiet sudo apt update; then
    echo ""
    error "apt update failed. Running with visible output for debugging..."
    sudo apt update
    exit 1
fi

if ! run_quiet sudo apt upgrade -y; then
    echo ""
    error "apt upgrade failed. Running with visible output for debugging..."
    sudo apt upgrade -y
    exit 1
fi
done_msg

# ========================================
# 4. Lid Close Configuration
# ========================================
progress "Configuring lid close behavior"
sudo mkdir -p /etc/systemd/logind.conf.d
cat << EOF | sudo tee /etc/systemd/logind.conf.d/lid-server.conf > /dev/null
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF
done_msg
warn "Lid close changes will apply after reboot (SSH-safe)"

# ========================================
# 5. Disable Sleep/Suspend
# ========================================
progress "Disabling sleep and suspend"
run_quiet sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
done_msg

# ========================================
# 6. Display Brightness Control
# ========================================
progress "Setting display brightness to 0 (headless server)"

# Turn off display brightness immediately
for backlight in /sys/class/backlight/*/brightness; do
    if [ -w "$backlight" ]; then
        echo 0 | sudo tee "$backlight" > /dev/null 2>&1
    fi
done

# Create systemd service to set brightness to 0 on boot
cat << 'EOF' | sudo tee /etc/systemd/system/brightness-off.service > /dev/null
[Unit]
Description=Set display brightness to 0 for headless server
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for backlight in /sys/class/backlight/*/brightness; do if [ -w "$backlight" ]; then echo 0 > "$backlight"; fi; done'
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable brightness-off > /dev/null 2>&1

# Disable systemd-backlight service that restores brightness
sudo systemctl disable systemd-backlight@acpi_video0 2>/dev/null || true
sudo systemctl disable systemd-backlight@intel_backlight 2>/dev/null || true

done_msg

# ========================================
# 7. Install Essential Packages
# ========================================
progress "Installing essential packages (2-3 minutes)"
run_quiet sudo apt install -y \
    git python3-pip python3-venv build-essential python3-dev \
    curl wget btop neovim net-tools lm-sensors openssh-server \
    fail2ban ufw
done_msg

# ========================================
# 8. SSH Hardening
# ========================================
progress "Configuring SSH security"

# Create backup only if it doesn't exist
if [ ! -f /etc/ssh/sshd_config.backup ]; then
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
fi

# Check and update Port setting
if ! grep -q "^Port 2222$" /etc/ssh/sshd_config; then
    # Remove any existing Port lines (commented or uncommented)
    sudo sed -i '/^#*Port /d' /etc/ssh/sshd_config
    # Add the new Port setting
    echo "Port 2222" | sudo tee -a /etc/ssh/sshd_config > /dev/null
fi

# Check and update PermitRootLogin setting
if ! grep -q "^PermitRootLogin no$" /etc/ssh/sshd_config; then
    sudo sed -i '/^#*PermitRootLogin /d' /etc/ssh/sshd_config
    echo "PermitRootLogin no" | sudo tee -a /etc/ssh/sshd_config > /dev/null
fi

# Check and update MaxAuthTries setting  
if ! grep -q "^MaxAuthTries 3$" /etc/ssh/sshd_config; then
    sudo sed -i '/^#*MaxAuthTries /d' /etc/ssh/sshd_config
    echo "MaxAuthTries 3" | sudo tee -a /etc/ssh/sshd_config > /dev/null
fi

sudo systemctl reload ssh
done_msg
info "SSH moved to port 2222"

# ========================================
# 9. Firewall Configuration
# ========================================
progress "Configuring firewall"
sudo ufw default deny incoming > /dev/null 2>&1
sudo ufw default allow outgoing > /dev/null 2>&1
sudo ufw allow 22/tcp comment 'SSH-current' > /dev/null 2>&1
sudo ufw allow 2222/tcp comment 'SSH-new' > /dev/null 2>&1
sudo ufw allow 8080/tcp comment 'FreqUI' > /dev/null 2>&1
echo "y" | sudo ufw enable > /dev/null 2>&1
done_msg

# ========================================
# 10. Fail2Ban Configuration
# ========================================
progress "Configuring Fail2Ban"
cat << EOF | sudo tee /etc/fail2ban/jail.local > /dev/null
[sshd]
enabled = true
port = 22,2222
maxretry = 3
bantime = 3600
EOF
sudo systemctl restart fail2ban
done_msg

# ========================================
# 11. Thermal Management
# ========================================
progress "Setting up thermal management"
sudo apt install -y fancontrol thermald > /dev/null 2>&1
sudo sensors-detect --auto > /dev/null 2>&1
done_msg

# ========================================
# 12. Power Management
# ========================================
progress "Installing power management"
sudo apt install -y tlp tlp-rdw > /dev/null 2>&1
cat << EOF | sudo tee /etc/tlp.d/01-server.conf > /dev/null
TLP_DEFAULT_MODE=BAT
TLP_PERSISTENT_DEFAULT=1
CPU_SCALING_GOVERNOR_ON_AC=powersave
CPU_SCALING_GOVERNOR_ON_BAT=powersave
EOF
sudo systemctl enable tlp > /dev/null 2>&1
sudo tlp start > /dev/null 2>&1
done_msg

# ========================================
# 13. Swap Configuration
# ========================================
progress "Configuring 4GB swap"
if [ ! -f /swapfile ]; then
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile > /dev/null 2>&1
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null
fi
done_msg

# ========================================
# 14. Docker Installation
# ========================================
progress "Installing Docker (3-5 minutes)"
sudo apt remove -y docker docker-engine docker.io containerd runc > /dev/null 2>&1 || true
sudo apt install -y ca-certificates gnupg lsb-release > /dev/null 2>&1
sudo mkdir -p /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
fi
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update > /dev/null 2>&1
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1
sudo usermod -aG docker $USER
sudo systemctl enable docker > /dev/null 2>&1
done_msg

# ========================================
# Create System Info Script
# ========================================
progress "Creating system info script"
cat << 'EOF' > "$SCRIPT_DIR/system-info.sh"
#!/bin/bash
echo "IP: $(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)"
echo "SSH Port: 2222 (currently also 22)"
echo "FreqUI: http://$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1):8080"
echo "Uptime: $(uptime -p)"
EOF
chmod +x "$SCRIPT_DIR/system-info.sh"
# Script available at: homelab-scripts/system/system-info.sh
done_msg

# ========================================
# 15. Auto-Recovery Configuration
# ========================================
progress "Setting up auto-recovery for remote access"

# Install ethtool for Wake-on-LAN
sudo apt install -y ethtool wakeonlan > /dev/null 2>&1

# Enable Wake-on-LAN
ETH_INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^en' | head -1)
if [ -n "$ETH_INTERFACE" ]; then
    # Enable WoL (ignore errors if not supported)
    sudo ethtool -s $ETH_INTERFACE wol g 2>/dev/null || true
    
    # Make WoL persistent across reboots
    cat << EOF | sudo tee /etc/systemd/system/wol-enable.service > /dev/null
[Unit]
Description=Configure Wake On LAN
Requires=network.target
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/ethtool -s $ETH_INTERFACE wol g
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl enable wol-enable > /dev/null 2>&1
fi

# Create auto-reboot service for unexpected shutdowns
cat << 'EOF' | sudo tee /etc/systemd/system/auto-recovery.service > /dev/null
[Unit]
Description=Auto-recovery on unexpected shutdown
DefaultDependencies=false
Before=shutdown.target reboot.target halt.target

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/bin/true
ExecStop=/bin/bash -c 'if [ "$SYSTEMD_SHUTDOWN_REASON" = "shutdown" ] && [ ! -f /tmp/manual-shutdown ]; then systemctl reboot; fi'
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable auto-recovery > /dev/null 2>&1

# Create manual shutdown script
cat << 'EOF' > "$SCRIPT_DIR/manual-shutdown.sh"
#!/bin/bash
# Use this script for intentional shutdowns to prevent auto-reboot
echo "Creating manual shutdown marker..."
sudo touch /tmp/manual-shutdown
sudo shutdown -h now
EOF
chmod +x "$SCRIPT_DIR/manual-shutdown.sh"
# Script available at: homelab-scripts/system/manual-shutdown.sh

# Create Wake-on-LAN info script
MAC_ADDRESS=$(cat /sys/class/net/$ETH_INTERFACE/address 2>/dev/null)
cat << EOF > "$SCRIPT_DIR/wake-macbook.sh"
#!/bin/bash
# Wake up the MacBook remotely using Wake-on-LAN
# Usage: bash wake-macbook.sh
# Or from another machine: wakeonlan $MAC_ADDRESS

echo "Sending Wake-on-LAN packet to MAC: $MAC_ADDRESS"
wakeonlan $MAC_ADDRESS
echo "Wake packet sent. Wait 30-60 seconds for boot."
EOF
chmod +x "$SCRIPT_DIR/wake-macbook.sh"
# Script available at: homelab-scripts/system/wake-macbook.sh

done_msg

# ========================================
# Final Summary
# ========================================
echo ""
echo "================================================"
echo "  ✅ SERVER SETUP COMPLETE!"
echo "================================================"
echo ""
echo "📡 System Information:"
echo "   Server IP: ${IP_ADDR}"
echo "   SSH: ssh -p 2222 $USER@${IP_ADDR}"
echo ""
echo "⚠️  Important Notes:"
echo "   1. Lid close prevention needs reboot to activate"
echo "   2. Use 'sudo docker' until you logout/login"
echo "   3. SSH currently on both ports 22 and 2222"
echo ""
echo "🔄 Auto-Recovery Features:"
echo "   • Wake-on-LAN: Use ~/homelab-scripts/system/wake-macbook.sh from another machine"
echo "   • Auto-reboot: Unexpected shutdowns trigger automatic restart"
echo "   • Manual shutdown: Use ~/homelab-scripts/system/manual-shutdown.sh to prevent auto-reboot"
echo ""
echo "🔧 Next Steps:"
echo "   1. Run 'bash ~/homelab-scripts/applications/freqtrade-install.sh' to set up Freqtrade"
echo "   2. Or install your preferred applications"
echo "   3. Configure BIOS 'Restore on AC Power Loss' for hardware-level recovery"
echo ""
echo "Run ~/homelab-scripts/system/system-info.sh to check system status"
echo "================================================"

# ========================================
# Reboot Prompt
# ========================================
echo ""
warn "Several changes require a reboot to take full effect:"
echo "   • Lid close behavior"
echo "   • Display brightness settings"
echo "   • Power management optimizations"
echo "   • Auto-recovery services"
echo ""

read -p "$(echo -e "${YELLOW}[?]${NC} Reboot now? (y/N): ")" -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    info "Rebooting in 5 seconds... (Press Ctrl+C to cancel)"
    sleep 1
    echo -ne "${BLUE}[⟳]${NC} 4... "
    sleep 1
    echo -ne "3... "
    sleep 1
    echo -ne "2... "
    sleep 1
    echo -ne "1... "
    sleep 1
    echo -e "${GREEN}Rebooting now!${NC}"
    sudo reboot
else
    echo ""
    info "Reboot skipped. Run 'sudo reboot' when ready."
    echo ""
fi