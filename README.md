# Homelab Scripts

A collection of automation scripts for setting up and managing homelab infrastructure.

## 📁 Structure

```
homelab-scripts/
├── system/           # System preparation, hardening, and utility scripts
│   ├── macbook-server-setup.sh    # Main server preparation script
│   ├── add-user.sh                # User management with homelab permissions
│   ├── brightness-control.sh      # Remote screen brightness control
│   ├── screen-on.sh               # Quick screen activation
│   ├── screen-off.sh              # Quick screen deactivation
│   ├── check-upgrade.sh           # Check Ubuntu upgrade status
│   ├── monitor-upgrade.sh         # Monitor upgrade process
│   ├── manual-shutdown.sh         # Safe shutdown without auto-reboot
│   └── system-info.sh             # Display system connection info
├── applications/     # Application-specific installation scripts
│   └── freqtrade-install.sh       # Freqtrade trading bot setup
├── launchers/        # Orchestration scripts that combine multiple components
│   └── macbook-freqtrade-server-init.sh
└── docs/            # Documentation and guides
```

## 🖥️ System Scripts

### `system/macbook-server-setup.sh`
Prepares a MacBook Pro 2011 running Ubuntu Server for homelab use.

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
bash system/macbook-server-setup.sh
```

### `system/add-user.sh`
Creates new users with all necessary permissions for homelab management.

**Features:**
- Creates user with home directory and bash shell
- Generates secure random password
- Adds to sudo and docker groups
- Sets up SSH directory with proper permissions
- Creates Freqtrade workspace directory
- Configures bash environment with useful aliases
- Saves credentials securely to /root/

**Usage:**
```bash
sudo bash system/add-user.sh <username>
```

**Created for new user:**
- Home directory with SSH setup
- Docker and sudo access (logout/login required for docker)
- Freqtrade directory: `~/freqtrade/`
- Welcome script: `~/welcome.sh`
- Useful aliases: `ft-status`, `ft-logs`, `dps`, `dlog`

### `system/brightness-control.sh`
Remote screen brightness control for MacBook servers with display management.

**Features:**
- Turn screen on/off remotely via SSH
- Set specific brightness percentage (0-100%)
- Set absolute brightness levels
- Auto turn-off with timeout
- Status monitoring and logging
- Multiple backlight interface support

**Usage:**
```bash
# Turn on at 75% brightness
bash system/brightness-control.sh on

# Turn on at 50% for 10 minutes
bash system/brightness-control.sh on 50 10

# Turn off
bash system/brightness-control.sh off

# Set specific level
bash system/brightness-control.sh level 500

# Check status
bash system/brightness-control.sh status
```

**Remote usage:**
```bash
ssh -p 2222 user@server 'bash ~/brightness-control.sh on'
```

### `system/screen-on.sh` / `system/screen-off.sh`
Quick shortcuts for screen control.

**Usage:**
```bash
bash system/screen-on.sh [brightness%] [timeout_minutes]
bash system/screen-off.sh
```

### `system/check-upgrade.sh` / `system/monitor-upgrade.sh`
Ubuntu upgrade monitoring utilities.

**Features:**
- `monitor-upgrade.sh`: Runs upgrade monitoring in background
- `check-upgrade.sh`: Quick status check of upgrade completion
- Creates completion markers and status logs
- Multiple notification methods (wall, logger, terminal bell)

**Usage:**
```bash
# Start monitoring an upgrade
bash system/monitor-upgrade.sh

# Check if upgrade is complete
bash system/check-upgrade.sh
```

### `system/manual-shutdown.sh`
Safe shutdown script that prevents automatic reboot.

**Usage:**
```bash
bash system/manual-shutdown.sh
```

### `system/system-info.sh`
Quick display of system connection information.

**Shows:**
- Current IP address
- SSH ports (22 and 2222)
- Freqtrade UI URL
- System uptime

**Usage:**
```bash
bash system/system-info.sh
```

## 🤖 Application Scripts

### `applications/freqtrade-install.sh`
Installs and configures Freqtrade cryptocurrency trading bot with Docker.

**Features:**
- Docker Compose setup
- Freqtrade configuration (dry-run mode)
- Web UI on port 8080
- Helper scripts for common operations
- Secure credential generation

**Usage:**
```bash
bash applications/freqtrade-install.sh
```

**Helper Scripts Created:**
- `~/freqtrade/ft-status.sh` - Check container status and logs
- `~/freqtrade/ft-logs.sh` - Follow live logs
- `~/freqtrade/ft-download-data.sh` - Download market data
- `~/freqtrade/ft-backtest.sh` - Run backtesting
- `~/freqtrade/ft-bash.sh` - Access container shell

## 🚀 Launchers

### `launchers/macbook-freqtrade-server-init.sh`
Orchestrates the complete setup process for a MacBook Freqtrade server.

**Usage:**
```bash
bash launchers/macbook-freqtrade-server-init.sh
```

This launcher will:
1. Explain the setup process
2. Optionally run both system and application scripts in sequence
3. Provide guidance for manual execution

## 🔧 Quick Start

1. **Clone/Download** this repository to your target machine
2. **Run the launcher** for a complete setup:
   ```bash
   cd homelab-scripts
   bash launchers/macbook-freqtrade-server-init.sh
   ```
3. **Or run components separately:**
   ```bash
   # System setup (run once)
   bash system/macbook-server-setup.sh
   
   # Application installation (can be repeated)
   bash applications/freqtrade-install.sh
   ```

4. **Additional utilities available:**
   ```bash
   # User management
   sudo bash system/add-user.sh newuser
   
   # Remote screen control
   bash system/brightness-control.sh on 75
   bash system/screen-off.sh
   
   # System information
   bash system/system-info.sh
   
   # Safe shutdown (prevents auto-reboot)
   bash system/manual-shutdown.sh
   ```

## ⚠️ Important Notes

- **Don't run as root** - Scripts use sudo when needed
- **SSH changes** - Port moves from 22 to 2222 (both active during transition)
- **Reboot recommended** - For lid close behavior to take effect
- **Docker group** - Logout/login required for non-sudo Docker access

## 🔒 Security Features

- SSH hardening (custom port, no root login, limited auth attempts)
- UFW firewall with minimal open ports
- Fail2Ban protection
- Secure credential generation
- Docker daemon security

## 📋 Prerequisites

- Ubuntu Server (tested on MacBook Pro 2011)
- Ethernet connection for initial setup
- Sudo privileges
- Internet connectivity

## 🎯 Default Configuration

### SSH
- **Port:** 2222 (22 remains open during transition)
- **Root Login:** Disabled
- **Max Auth Tries:** 3

### Firewall
- **SSH:** Ports 22, 2222
- **Freqtrade UI:** Port 8080
- **Default:** Deny incoming, allow outgoing

### Freqtrade
- **Mode:** Dry-run (paper trading)
- **Exchange:** Binance (requires API keys)
- **UI:** http://your-ip:8080
- **Pairs:** BTC/USDT, ETH/USDT

## 📚 Additional Resources

- [Freqtrade Documentation](https://www.freqtrade.io/)
- [Docker Documentation](https://docs.docker.com/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)

## 🤝 Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## 📝 License

This project is open source and available under the MIT License.
