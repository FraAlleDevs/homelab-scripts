#!/bin/bash
# Add New User Script for Homelab System
# Creates a new user with all necessary permissions for running homelab services
# Usage: bash add-user.sh <username>

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
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root (use sudo)."
fi

# Check if username is provided
if [ -z "$1" ]; then
    error "Usage: sudo bash add-user.sh <username>"
fi

USERNAME="$1"

# Validate username
if ! [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    error "Invalid username. Use only lowercase letters, numbers, underscore, and hyphen."
fi

# Check if user already exists
if id "$USERNAME" &>/dev/null; then
    error "User '$USERNAME' already exists."
fi

# Generate random password
PASSWORD=$(openssl rand -base64 12)

echo "================================================"
echo "  Adding New User: $USERNAME"
echo "================================================"
echo ""

# ========================================
# 1. Create User with Home Directory
# ========================================
progress "Creating user '$USERNAME'"
useradd -m -s /bin/bash "$USERNAME"
done_msg

# ========================================
# 2. Set Generated Password
# ========================================
progress "Setting generated password"
echo "$USERNAME:$PASSWORD" | chpasswd
done_msg

# ========================================
# 3. Add to Required Groups
# ========================================
progress "Adding user to required groups"
# Add to sudo group for administrative access
usermod -aG sudo "$USERNAME"

# Add to docker group for Docker access
usermod -aG docker "$USERNAME"

# Add to common system groups
usermod -aG users,plugdev,netdev "$USERNAME"
done_msg

# ========================================
# 4. Set up SSH Directory
# ========================================
progress "Setting up SSH directory"
USER_HOME="/home/$USERNAME"
mkdir -p "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"
touch "$USER_HOME/.ssh/authorized_keys"
chmod 600 "$USER_HOME/.ssh/authorized_keys"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.ssh"
done_msg

# ========================================
# 5. Create Freqtrade Directory
# ========================================
progress "Setting up Freqtrade directory"
mkdir -p "$USER_HOME/freqtrade"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/freqtrade"
done_msg

# ========================================
# 6. Set up Bash Profile
# ========================================
progress "Configuring user environment"
cat << 'EOF' > "$USER_HOME/.bashrc"
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize

# Colored prompt
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ft-status='~/freqtrade/ft-status.sh'
alias ft-logs='~/freqtrade/ft-logs.sh'

# Docker aliases
alias dps='docker ps'
alias dlog='docker logs'
alias dexec='docker exec -it'

# Add local bin to PATH
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
EOF

chown "$USERNAME:$USERNAME" "$USER_HOME/.bashrc"
done_msg

# ========================================
# 7. Create Welcome Script
# ========================================
progress "Creating welcome information"
cat << EOF > "$USER_HOME/welcome.sh"
#!/bin/bash
echo "================================================"
echo "  Welcome to the Freqtrade System, $USERNAME!"
echo "================================================"
echo ""
echo "📂 Your directories:"
echo "   Home: $USER_HOME"
echo "   Freqtrade: $USER_HOME/freqtrade"
echo ""
echo "🐳 Docker access: Configured (logout/login required)"
echo "🔧 Sudo access: Enabled"
echo ""
echo "📋 Useful commands:"
echo "   ft-status    - Check Freqtrade status"
echo "   ft-logs      - View live logs"
echo "   dps          - List Docker containers"
echo ""
echo "🚀 Next steps:"
echo "   1. Install Freqtrade: bash ~/homelab-scripts/applications/freqtrade-install.sh"
echo "   2. Configure API keys in ~/freqtrade/user_data/config.json"
echo ""
echo "Run this script anytime with: bash ~/welcome.sh"
echo "================================================"
EOF

chmod +x "$USER_HOME/welcome.sh"
chown "$USERNAME:$USERNAME" "$USER_HOME/welcome.sh"
done_msg

# ========================================
# 8. Save Credentials
# ========================================
progress "Saving user credentials"
cat << EOF > "/root/${USERNAME}-credentials.txt"
User: $USERNAME
Password: $PASSWORD
Home: $USER_HOME
SSH: ssh $USERNAME@\$(hostname -I | awk '{print \$1}') -p 2222
EOF
chmod 600 "/root/${USERNAME}-credentials.txt"
done_msg

# ========================================
# 9. Final Summary
# ========================================
echo ""
echo "================================================"
echo "  ✅ USER CREATION COMPLETE!"
echo "================================================"
echo ""
echo "👤 User Information:"
echo "   Username: $USERNAME"
echo "   Password: $PASSWORD"
echo "   Home: $USER_HOME"
echo "   Shell: /bin/bash"
echo ""
echo "🔐 Groups:"
echo "   - sudo (administrative access)"
echo "   - docker (Docker container management)"
echo "   - users, plugdev, netdev (system access)"
echo ""
echo "📁 Directories Created:"
echo "   - $USER_HOME/.ssh (SSH configuration)"
echo "   - $USER_HOME/freqtrade (Freqtrade workspace)"
echo ""
echo "💾 Credentials saved to: /root/${USERNAME}-credentials.txt"
echo ""
echo "⚠️  Important Notes:"
echo "   1. User must logout/login for Docker group to take effect"
echo "   2. SSH public key can be added to $USER_HOME/.ssh/authorized_keys"
echo "   3. Run 'bash ~/welcome.sh' as $USERNAME for getting started info"
echo ""
echo "🚀 Quick Start for $USERNAME:"
echo "   sudo su - $USERNAME"
echo "   bash ~/welcome.sh"
echo ""
echo "================================================"