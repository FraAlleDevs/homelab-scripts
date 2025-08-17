#!/bin/bash
# MacBook Pro 2011 Ubuntu Server Setup
# System preparation and hardening script
# Run with: bash macbook-server-setup.sh

set -e  # Exit on error

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
sudo netplan apply 2>/dev/null || true
done_msg

# ========================================
# 3. System Updates
# ========================================
progress "Updating system packages (this may take 2-5 minutes)"
sudo apt update > /dev/null 2>&1
sudo apt upgrade -y > /dev/null 2>&1
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
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target 2>/dev/null
done_msg

# ========================================
# 6. Install Essential Packages
# ========================================
progress "Installing essential packages (2-3 minutes)"
sudo apt install -y \
    git python3-pip python3-venv build-essential python3-dev \
    curl wget htop net-tools lm-sensors openssh-server \
    fail2ban ufw > /dev/null 2>&1
done_msg

# ========================================
# 7. SSH Hardening
# ========================================
progress "Configuring SSH security"
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
sudo sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sudo systemctl reload sshd
done_msg
info "SSH moved to port 2222"

# ========================================
# 8. Firewall Configuration
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
# 9. Fail2Ban Configuration
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
# 10. Thermal Management
# ========================================
progress "Setting up thermal management"
sudo apt install -y fancontrol thermald > /dev/null 2>&1
sudo sensors-detect --auto > /dev/null 2>&1
done_msg

# ========================================
# 11. Power Management
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
# 12. Swap Configuration
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
# 13. Docker Installation
# ========================================
progress "Installing Docker (3-5 minutes)"
sudo apt remove -y docker docker-engine docker.io containerd runc > /dev/null 2>&1 || true
sudo apt install -y ca-certificates gnupg lsb-release > /dev/null 2>&1
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
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
cat << 'EOF' > ~/system-info.sh
#!/bin/bash
echo "IP: $(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)"
echo "SSH Port: 2222 (currently also 22)"
echo "FreqUI: http://$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1):8080"
echo "Uptime: $(uptime -p)"
EOF
chmod +x ~/system-info.sh
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
echo "🔧 Next Steps:"
echo "   1. Run 'bash freqtrade-install.sh' to set up Freqtrade"
echo "   2. Or install your preferred applications"
echo ""
echo "Run ~/system-info.sh to check system status"
echo "================================================"