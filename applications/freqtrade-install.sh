#!/bin/bash
# Freqtrade Docker Installation Script
# Installs and configures Freqtrade with Docker Compose
# Run with: bash freqtrade-install.sh

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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please run macbook-server-setup.sh first."
fi

# Get current IP for display
IP_ADDR=$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)

echo "================================================"
echo "  Freqtrade Installation"
echo "================================================"
echo ""

# ========================================
# 1. Freqtrade Docker Setup
# ========================================
progress "Setting up Freqtrade with Docker"
FREQTRADE_DIR="$HOME/freqtrade"
mkdir -p $FREQTRADE_DIR
cd $FREQTRADE_DIR

# Create docker-compose.yml
cat << 'EOFDOCKER' > docker-compose.yml
version: '3.8'
services:
  freqtrade:
    image: freqtradeorg/freqtrade:stable
    container_name: freqtrade
    volumes:
      - ./user_data:/freqtrade/user_data
    command: >
      trade
      --logfile /freqtrade/user_data/logs/freqtrade.log
      --db-url sqlite:////freqtrade/user_data/tradesv3.sqlite
      --config /freqtrade/user_data/config.json
      --strategy SampleStrategy
    restart: unless-stopped

  freqtrade-ui:
    image: freqtradeorg/freqtrade:stable
    container_name: freqtrade-ui
    command: >
      webserver
      --config /freqtrade/user_data/config.json
    ports:
      - "8080:8080"
    volumes:
      - ./user_data:/freqtrade/user_data
    restart: unless-stopped
EOFDOCKER

# Create directories
mkdir -p user_data/{data,logs,strategies}

# Create config with random passwords
JWT_SECRET=$(openssl rand -hex 32)
API_PASSWORD=$(openssl rand -hex 16)

cat << EOF > user_data/config.json
{
    "max_open_trades": 3,
    "stake_currency": "USDT",
    "stake_amount": "unlimited",
    "tradable_balance_ratio": 0.99,
    "fiat_display_currency": "USD",
    "dry_run": true,
    "dry_run_wallet": 1000,
    "exchange": {
        "name": "binance",
        "key": "",
        "secret": "",
        "pair_whitelist": ["BTC/USDT", "ETH/USDT"]
    },
    "api_server": {
        "enabled": true,
        "listen_ip_address": "0.0.0.0",
        "listen_port": 8080,
        "jwt_secret_key": "${JWT_SECRET}",
        "username": "freqtrader",
        "password": "${API_PASSWORD}"
    },
    "bot_name": "freqtrade",
    "initial_state": "stopped"
}
EOF

# Save credentials
echo "FreqUI Access:" > ~/freqtrade-credentials.txt
echo "URL: http://${IP_ADDR}:8080" >> ~/freqtrade-credentials.txt
echo "Username: freqtrader" >> ~/freqtrade-credentials.txt
echo "Password: ${API_PASSWORD}" >> ~/freqtrade-credentials.txt
chmod 600 ~/freqtrade-credentials.txt
done_msg

# ========================================
# 2. Pull Docker Image
# ========================================
progress "Pulling Freqtrade Docker image (1-2 minutes)"
sudo docker pull freqtradeorg/freqtrade:stable > /dev/null 2>&1
done_msg

# ========================================
# 3. Start Services
# ========================================
progress "Starting Freqtrade services"
cd $FREQTRADE_DIR
sudo docker compose up -d > /dev/null 2>&1
done_msg

# ========================================
# 4. Create Helper Scripts
# ========================================
progress "Creating helper scripts"
cat << 'EOF' > ~/freqtrade/ft-status.sh
#!/bin/bash
echo "=== Docker Containers ==="
sudo docker ps --format "table {{.Names}}\t{{.Status}}"
echo ""
echo "=== Recent Logs ==="
sudo docker logs freqtrade --tail 5
EOF
chmod +x ~/freqtrade/ft-status.sh

cat << 'EOF' > ~/freqtrade/ft-logs.sh
#!/bin/bash
sudo docker logs freqtrade --tail 100 -f
EOF
chmod +x ~/freqtrade/ft-logs.sh

cat << 'EOF' > ~/freqtrade/ft-download-data.sh
#!/bin/bash
sudo docker run --rm -v "$(pwd)/user_data:/freqtrade/user_data" freqtradeorg/freqtrade:stable download-data --config /freqtrade/user_data/config.json --days 30 --timeframes 1h 5m
EOF
chmod +x ~/freqtrade/ft-download-data.sh

cat << 'EOF' > ~/freqtrade/ft-backtest.sh
#!/bin/bash
sudo docker run --rm -v "$(pwd)/user_data:/freqtrade/user_data" freqtradeorg/freqtrade:stable backtesting --config /freqtrade/user_data/config.json --strategy SampleStrategy
EOF
chmod +x ~/freqtrade/ft-backtest.sh

cat << 'EOF' > ~/freqtrade/ft-bash.sh
#!/bin/bash
sudo docker exec -it freqtrade bash
EOF
chmod +x ~/freqtrade/ft-bash.sh
done_msg

# ========================================
# Final Summary
# ========================================
echo ""
echo "================================================"
echo "  ✅ FREQTRADE INSTALLATION COMPLETE!"
echo "================================================"
echo ""
echo "📡 Access Information:"
echo "   FreqUI: http://${IP_ADDR}:8080"
echo "   Credentials: ~/freqtrade-credentials.txt"
echo ""
echo "📦 Freqtrade Status:"
echo "   Mode: DRY-RUN (paper trading)"
echo "   Config: ~/freqtrade/user_data/config.json"
echo "   Directory: ~/freqtrade"
echo ""
echo "🔧 Helper Scripts:"
echo "   ~/freqtrade/ft-status.sh    - Check status and logs"
echo "   ~/freqtrade/ft-logs.sh      - Follow live logs"
echo "   ~/freqtrade/ft-download-data.sh - Download market data"
echo "   ~/freqtrade/ft-backtest.sh  - Run backtesting"
echo "   ~/freqtrade/ft-bash.sh      - Access container shell"
echo ""
echo "⚠️  Next Steps:"
echo "   1. Add exchange API keys to ~/freqtrade/user_data/config.json"
echo "   2. Restart: cd ~/freqtrade && sudo docker compose restart"
echo "   3. Download data: ./ft-download-data.sh"
echo ""
echo "Run ~/freqtrade/ft-status.sh to check Freqtrade"
echo "================================================"