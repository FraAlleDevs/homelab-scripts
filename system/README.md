# System Scripts

This directory contains system preparation, hardening, and utility scripts for homelab infrastructure setup and management.

## 📁 Scripts Overview

```text
system/
├── macbook-server-setup.sh    # Main server preparation script
├── add-user.sh                # User management with homelab permissions
├── brightness-control.sh      # Remote screen brightness control
├── screen-on.sh               # Quick screen activation
├── screen-off.sh              # Quick screen deactivation
├── check-upgrade.sh           # Check Ubuntu upgrade status
├── monitor-upgrade.sh         # Monitor upgrade process
├── manual-shutdown.sh         # Safe shutdown without auto-reboot
├── system-info.sh             # Display system connection info
├── serverwatch                # Network server monitoring daemon
└── test-connection.sh         # Connection status testing utility
```

## 🖥️ Core System Setup

### `macbook-server-setup.sh`

**Purpose:** Complete server preparation script for MacBook Pro 2011 running Ubuntu Server.

**Features:**

- Network configuration (DHCP + DNS)
- System updates and essential packages
- SSH hardening (moves to port 2222)
- Firewall configuration (UFW)
- Fail2Ban setup
- Thermal and power management
- Docker installation
- Lid close behavior configuration
- 4GB swap setup

**Usage:**

```bash
bash macbook-server-setup.sh
```

**Prerequisites:**

- Fresh Ubuntu Server installation
- Ethernet connection
- Sudo privileges

**Post-installation:**

- SSH port changes to 2222 (22 remains active during transition)
- Reboot recommended for lid close behavior
- Docker group requires logout/login

---

## 👥 User Management

### `add-user.sh`

**Purpose:** Creates new users with all necessary permissions for homelab management.

**Features:**

- Creates user with home directory and bash shell
- Generates secure random password (saved to `/root/`)
- Adds to sudo and docker groups
- Sets up SSH directory with proper permissions
- Creates Freqtrade workspace directory
- Configures bash environment with useful aliases
- Creates welcome script with system information

**Usage:**

```bash
sudo bash add-user.sh <username>
```

**Created for new user:**

- Home directory: `/home/<username>/`
- SSH setup: `~/.ssh/` with proper permissions
- Docker and sudo access (logout/login required for docker)
- Freqtrade directory: `~/freqtrade/`
- Welcome script: `~/welcome.sh`
- Useful aliases: `ft-status`, `ft-logs`, `dps`, `dlog`

**Credentials:** Saved securely to `/root/<username>_credentials.txt`

---

## 🖼️ Display Management

### `brightness-control.sh`

**Purpose:** Comprehensive remote screen brightness control for MacBook servers.

**Features:**

- Turn screen on/off remotely via SSH
- Set specific brightness percentage (0-100%)
- Set absolute brightness levels
- Auto turn-off with configurable timeout
- Status monitoring and logging
- Multiple backlight interface support

**Usage:**

```bash
# Turn on at 75% brightness
bash brightness-control.sh on

# Turn on at 50% for 10 minutes
bash brightness-control.sh on 50 10

# Turn off
bash brightness-control.sh off

# Set specific level
bash brightness-control.sh level 500

# Check status
bash brightness-control.sh status
```

**Remote usage:**

```bash
ssh -p 2222 user@server 'bash ~/brightness-control.sh on'
```

### `screen-on.sh` / `screen-off.sh`

**Purpose:** Quick shortcuts for screen control.

**Usage:**

```bash
bash screen-on.sh [brightness%] [timeout_minutes]
bash screen-off.sh
```

---

## 🔄 System Maintenance

### `check-upgrade.sh` / `monitor-upgrade.sh`

**Purpose:** Ubuntu upgrade monitoring utilities.

**Features:**

- `monitor-upgrade.sh`: Runs upgrade monitoring in background
- `check-upgrade.sh`: Quick status check of upgrade completion
- Creates completion markers and status logs
- Multiple notification methods (wall, logger, terminal bell)

**Usage:**

```bash
# Start monitoring an upgrade
bash monitor-upgrade.sh

# Check if upgrade is complete
bash check-upgrade.sh
```

### `manual-shutdown.sh`

**Purpose:** Safe shutdown script that prevents automatic reboot.

**Usage:**

```bash
bash manual-shutdown.sh
```

---

## 📊 System Information

### `system-info.sh`

**Purpose:** Quick display of system connection information.

**Shows:**

- Current IP address
- SSH ports (22 and 2222)
- Freqtrade UI URL
- System uptime

**Usage:**

```bash
bash system-info.sh
```

---

## 📡 Network Monitoring

### `serverwatch`

**Purpose:** Advanced network server monitoring daemon with intelligent network detection.

**Key Features:**

- Continuous ping monitoring with configurable intervals
- Smart network detection (home WiFi, VPN, away detection)
- Reduces check frequency when away from home network
- Background daemon operation with PID management
- Real-time statistics and uptime tracking
- macOS notifications for alerts
- Comprehensive logging with multiple verbosity levels
- Response time measurement
- Status reporting and live log viewing

**Usage:**

```bash
# Start monitoring in background
./serverwatch start 192.168.1.100

# Start with custom settings
./serverwatch start 192.168.1.100 -i 10 -v

# Run in foreground (visible mode)
./serverwatch start 192.168.1.100 -f

# Check daemon status
./serverwatch status

# View live logs
./serverwatch log

# Stop monitoring
./serverwatch stop

# View statistics report
./serverwatch report
```

**Options:**

- `-f, --foreground`: Run in visible mode instead of background
- `-v, --verbose`: Enable detailed logging of every check
- `-i INTERVAL`: Set ping interval in seconds (default: 30)
- `-t TIMEOUT`: Set ping timeout in seconds (default: 5)
- `-a ALERT`: Alert after N consecutive failures (default: 3)
- `-d DIR`: Set custom log directory (default: ~/.serverwatch)

**Smart Features:**

- Detects when you're away from home network and reduces checks to hourly
- Automatically resumes normal monitoring when reconnected to home WiFi or VPN
- Sends macOS notifications for server down/recovery events
- Tracks comprehensive statistics including uptime percentage
- Logs stored in `~/.serverwatch/` with rotation and error separation

### `test-connection.sh`

**Purpose:** Quick connection status checker for troubleshooting network connectivity.

**Features:**

- WiFi SSID detection and home network verification
- WireGuard VPN status checking
- VPN connection enumeration via scutil
- Network interface inspection for VPN tunnels

**Usage:**

```bash
bash test-connection.sh
```

**Shows:**

- Current WiFi network name and home network status
- Active WireGuard interfaces and configuration
- All configured VPN connections
- VPN tunnel interfaces (utun, wg)

---

## 🔒 Security Notes

- Most scripts require sudo privileges when needed
- SSH hardening moves port from 22 to 2222
- Firewall (UFW) configured with minimal open ports
- Fail2Ban provides intrusion detection
- Secure credential generation and storage

## 📋 Quick Reference

### Common Workflows

**Initial Server Setup:**

```bash
bash macbook-server-setup.sh
sudo bash add-user.sh myuser
```

**Daily Operations:**

```bash
# Check system status
bash system-info.sh

# Monitor remote server
./serverwatch start 192.168.1.100

# Control screen remotely
bash brightness-control.sh on 75
```

**Maintenance:**

```bash
# Monitor system upgrade
bash monitor-upgrade.sh

# Safe shutdown
bash manual-shutdown.sh
```

**Troubleshooting:**

```bash
# Test network connectivity
bash test-connection.sh

# Check server monitoring status
./serverwatch status

# View monitoring logs
./serverwatch log
```
