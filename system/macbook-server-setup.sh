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
# 4. Timezone Configuration
# ========================================
progress "Setting timezone to Europe/Berlin (CEST/CET)"
sudo timedatectl set-timezone Europe/Berlin
CURRENT_TZ=$(timedatectl show --value --property=Timezone)
done_msg
log "Timezone set to: $CURRENT_TZ"
info "Local time: $(date '+%Y-%m-%d %H:%M:%S %Z')"

# ========================================
# 5. Lid Close Configuration
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
# 6. Disable Sleep/Suspend
# ========================================
progress "Disabling sleep and suspend"
run_quiet sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
done_msg

# ========================================
# 7. Display Brightness Control
# ========================================
progress "Setting display brightness to 0 (headless server)"

# Add user to video group for brightness control permissions
sudo usermod -aG video $USER

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
# 8. Install Essential Packages
# ========================================
progress "Installing essential packages (2-3 minutes)"
run_quiet sudo apt install -y \
    git python3-pip python3-venv build-essential python3-dev \
    curl wget btop neovim net-tools lm-sensors openssh-server \
    fail2ban ufw
done_msg

# ========================================
# 9. SSH Hardening
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
# 10. Firewall Configuration
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
# 11. Fail2Ban Configuration
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
# 12. Thermal Management
# ========================================
progress "Setting up thermal management"
sudo apt install -y fancontrol thermald > /dev/null 2>&1
sudo sensors-detect --auto > /dev/null 2>&1
done_msg

# ========================================
# 13. Power Management (2011 MacBook Fixes)
# ========================================
progress "Configuring power management for 2011 MacBook server"

# Disable TLP if it exists (causes aggressive disk sleep/wake cycles on MacBooks)
if systemctl list-unit-files | grep -q tlp.service; then
    sudo systemctl stop tlp 2>/dev/null || true
    sudo systemctl disable tlp 2>/dev/null || true
    info "TLP disabled (causes disk issues on MacBook servers)"
fi

# Disable USB autosuspend (prevents device disconnections)
echo -1 | sudo tee /sys/module/usbcore/parameters/autosuspend > /dev/null
echo "options usbcore autosuspend=-1" | sudo tee /etc/modprobe.d/usb-autosuspend.conf > /dev/null

# Disable aggressive laptop-mode if present
if [ -f /proc/sys/vm/laptop_mode ]; then
    echo 0 | sudo tee /proc/sys/vm/laptop_mode > /dev/null
fi

# Disable SATA link power management (critical for 2011 MacBooks)
for i in /sys/class/scsi_host/host*/link_power_management_policy; do
    if [ -f "$i" ]; then
        echo max_performance | sudo tee "$i" > /dev/null
    fi
done

# Create systemd service to set SATA power policy on boot
sudo tee /etc/systemd/system/sata-power-performance.service > /dev/null << 'EOF'
[Unit]
Description=Set SATA link power management to max_performance
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'for i in /sys/class/scsi_host/host*/link_power_management_policy; do [ -f "$i" ] && echo max_performance > $i; done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable sata-power-performance.service > /dev/null 2>&1
sudo systemctl start sata-power-performance.service > /dev/null 2>&1

# Keep drives from spinning down
if command -v hdparm &> /dev/null; then
    for disk in /dev/sd?; do
        if [ -b "$disk" ]; then
            sudo hdparm -S 0 "$disk" 2>/dev/null || true  # Disable standby
            sudo hdparm -B 255 "$disk" 2>/dev/null || true # Disable APM
        fi
    done
fi

# Create udev rule to prevent disk spindown
echo 'ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", RUN+="/usr/sbin/hdparm -S 0 /dev/%k"' | \
    sudo tee /etc/udev/rules.d/99-no-disk-spindown.rules > /dev/null

# Create disk keepalive service (workaround for persistent MacBook EFI issues)
sudo tee /etc/systemd/system/disk-keepalive.service > /dev/null << 'EOF'
[Unit]
Description=Keep disk from sleeping on 2011 MacBook
After=multi-user.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do echo $(date) > /var/tmp/.keepalive; sync; sleep 15; done'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable disk-keepalive.service > /dev/null 2>&1
sudo systemctl start disk-keepalive.service > /dev/null 2>&1

# Add MacBook-specific kernel parameters for next boot
if ! grep -q "libata.force=noncq" /etc/default/grub; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 libata.force=noncq acpi_osi=Darwin"/' /etc/default/grub
    sudo update-grub > /dev/null 2>&1
    warn "Kernel parameters added for MacBook compatibility (requires reboot)"
fi

done_msg
info "2011 MacBook power management fixes applied"
warn "Disk keepalive service running (workaround for EFI firmware issues)"

# ========================================
# 14. Swap Configuration
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
# 15. Docker Installation
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
# 16. Auto-Recovery Configuration
# ========================================
progress "Setting up auto-recovery for remote access"

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