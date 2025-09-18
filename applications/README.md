# Application Scripts

This directory contains application-specific installation and configuration scripts for homelab services.

## 📁 Applications Overview

```text
applications/
└── freqtrade-install.sh       # Freqtrade cryptocurrency trading bot setup
```

## 🤖 Trading Applications

### `freqtrade-install.sh`

**Purpose:** Complete installation and configuration of Freqtrade cryptocurrency trading bot using Docker.

**What is Freqtrade?**
Freqtrade is an open-source cryptocurrency algorithmic trading bot written in Python. It's designed to support all major exchanges and be controlled via a web UI, telegram, or command line interface.

**Key Features:**

- Docker Compose setup for easy deployment
- Freqtrade configuration in dry-run mode (paper trading)
- Web UI accessible on port 8080
- Helper scripts for common operations
- Secure credential generation
- Pre-configured with popular trading pairs
- Backtesting capabilities
- Strategy development environment

**Installation Process:**

```bash
bash freqtrade-install.sh
```

**What the script does:**

1. **Environment Setup:**
   - Creates `~/freqtrade/` directory structure
   - Downloads and configures Docker Compose files
   - Sets up configuration directories

2. **Docker Configuration:**
   - Pulls latest Freqtrade Docker image
   - Configures container networking
   - Sets up persistent data volumes

3. **Freqtrade Configuration:**
   - Creates `config.json` with safe defaults
   - Configures dry-run mode (no real trading)
   - Sets up Binance exchange (requires API keys)
   - Configures popular trading pairs (BTC/USDT, ETH/USDT)
   - Enables web UI on port 8080

4. **Helper Scripts Creation:**
   - `ft-status.sh` - Check container status and logs
   - `ft-logs.sh` - Follow live logs
   - `ft-download-data.sh` - Download historical market data
   - `ft-backtest.sh` - Run strategy backtesting
   - `ft-bash.sh` - Access container shell

5. **Security Setup:**
   - Generates secure JWT secret for web UI
   - Creates API credentials template
   - Sets proper file permissions

**Post-Installation Directory Structure:**

```text
~/freqtrade/
├── docker-compose.yml          # Main Docker configuration
├── config.json                 # Freqtrade configuration
├── user_data/                  # Trading data and strategies
│   ├── strategies/             # Trading strategy files
│   ├── data/                   # Historical market data
│   └── logs/                   # Application logs
├── ft-status.sh                # Helper: Check status
├── ft-logs.sh                  # Helper: View logs
├── ft-download-data.sh         # Helper: Download data
├── ft-backtest.sh              # Helper: Run backtests
└── ft-bash.sh                  # Helper: Container access
```

**Helper Scripts Usage:**

### `ft-status.sh`

Check container status and recent logs:

```bash
cd ~/freqtrade
./ft-status.sh
```

### `ft-logs.sh`

Follow live application logs:

```bash
cd ~/freqtrade
./ft-logs.sh
```

### `ft-download-data.sh`

Download historical market data kfor backtesting:

```bash
cd ~/freqtrade
./ft-download-data.sh
```

### `ft-backtest.sh`

Run strategy backtesting:

```bash
cd ~/freqtrade
./ft-backtest.sh
```

### `ft-bash.sh`

Access the container shell for advanced operations:

```bash
cd ~/freqtrade
./ft-bash.sh
```

**Web UI Access:**

- URL: `http://your-server-ip:8080`
- Default login: Check `config.json` for credentials
- Features: Live trading view, strategy management, backtesting interface

**Configuration Details:**

**Default Trading Pairs:**

- BTC/USDT
- ETH/USDT
- Additional pairs can be added in `config.json`

**Exchange Configuration:**

- Configured for Binance (testnet and live)
- Requires API key and secret (add to `config.json`)
- Dry-run mode enabled by default (no real trading)

**Trading Strategy:**

- Uses sample strategy included with Freqtrade
- Custom strategies can be added to `user_data/strategies/`
- Strategy development guide available in Freqtrade documentation

**Risk Management:**

- **IMPORTANT:** Starts in dry-run mode (paper trading only)
- Real trading requires manual configuration changes
- Always test strategies thoroughly before live trading
- Never invest more than you can afford to lose

**Next Steps After Installation:**

1. **Access Web UI:**

   ```bash
   # Get your server IP
   bash ../system/system-info.sh
   # Open http://your-ip:8080 in browser
   ```

2. **Download Market Data:**

   ```bash
   cd ~/freqtrade
   ./ft-download-data.sh
   ```

3. **Run Initial Backtest:**

   ```bash
   ./ft-backtest.sh
   ```

4. **Monitor Live Dry-Run:**

   ```bash
   ./ft-logs.sh
   ```

**Adding Exchange API Keys:**

To enable real market data (even in dry-run mode), add your exchange API keys to `config.json`:

```json
{
  "exchange": {
    "name": "binance",
    "key": "your_api_key_here",
    "secret": "your_secret_key_here",
    "sandbox": true
  }
}
```

**Security Considerations:**

- API keys are stored in plain text in `config.json`
- Ensure proper file permissions (set by installer)
- Use exchange API keys with limited permissions
- Consider using testnet/sandbox for initial testing
- Never share your API keys or configuration files

**Troubleshooting:**

**Container Issues:**

```bash
# Check container status
./ft-status.sh

# View detailed logs
./ft-logs.sh

# Restart services
docker-compose down && docker-compose up -d
```

**Web UI Not Accessible:**

```bash
# Check if port 8080 is open
sudo ufw status
# Should show: 8080 ALLOW Anywhere

# Check container is running
docker ps | grep freqtrade
```

**Data Download Issues:**

```bash
# Access container shell
./ft-bash.sh
# Inside container:
freqtrade download-data --exchange binance --pairs BTC/USDT ETH/USDT
```

**Performance Monitoring:**

```bash
# Monitor resource usage
docker stats

# Check logs for errors
./ft-logs.sh | grep -i error
```

## 📚 Additional Resources

- [Freqtrade Documentation](https://www.freqtrade.io/)
- [Strategy Development Guide](https://www.freqtrade.io/en/stable/strategy-customization/)
- [Backtesting Guide](https://www.freqtrade.io/en/stable/backtesting/)
- [Exchange Configuration](https://www.freqtrade.io/en/stable/exchanges/)

## ⚠️ Important Disclaimers

- **Cryptocurrency trading involves significant risk**
- **Always start with dry-run mode**
- **Never invest more than you can afford to lose**
- **Test all strategies thoroughly before live trading**
- **This software is for educational and research purposes**
- **Past performance does not guarantee future results**
