# Homelab Scripts

A collection of automation scripts for setting up and managing homelab infrastructure.

## 📁 Structure

```
homelab-scripts/
├── system/           # System preparation and hardening scripts
├── applications/     # Application-specific installation scripts
├── launchers/        # Orchestration scripts that combine multiple components
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