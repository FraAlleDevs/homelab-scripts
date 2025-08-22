#!/bin/bash
# Freqtrade Docker Installation Script
# Installs and configures Freqtrade with Docker Compose using FraAlleDevs fork
# Based on: https://www.freqtrade.io/en/stable/docker_quickstart/
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
echo "  Freqtrade Installation (FraAlleDevs Fork)"
echo "================================================"
echo ""

# ========================================
# 1. Freqtrade Docker Setup
# ========================================
progress "Setting up Freqtrade with Docker"
FREQTRADE_DIR="$HOME/freqtrade"
mkdir -p $FREQTRADE_DIR
cd $FREQTRADE_DIR

# Clone FraAlleDevs/freqtrade fork (develop branch)
if [ ! -d "freqtrade-fork" ]; then
    progress "Cloning FraAlleDevs/freqtrade fork (develop branch)"
    git clone -b develop https://github.com/FraAlleDevs/freqtrade.git freqtrade-fork
    done_msg
fi

# Create docker-compose.yml using custom build from develop branch
cat << 'EOFDOCKER' > docker-compose.yml
version: '3.8'
services:
  freqtrade:
    build: ./freqtrade-fork
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
    build: ./freqtrade-fork
    container_name: freqtrade-ui
    command: >
      webserver
      --config /freqtrade/user_data/config.json
    ports:
      - "8080:8080"
    volumes:
      - ./user_data:/freqtrade/user_data
    restart: unless-stopped
    depends_on:
      - freqtrade
EOFDOCKER

# Create user_data directory structure following official recommendations
progress "Creating user_data directory structure"
docker compose run --rm freqtrade create-userdir --userdir user_data

# Create configuration using official method
progress "Creating configuration file"
docker compose run --rm freqtrade new-config --config user_data/config.json

# Generate credentials for API access
JWT_SECRET=$(openssl rand -hex 32)
API_PASSWORD=$(openssl rand -hex 16)

# Update config with custom settings using jq or sed
progress "Updating configuration with custom settings"
if command -v jq &> /dev/null; then
    # Use jq if available for proper JSON manipulation
    cat user_data/config.json | jq --arg jwt "$JWT_SECRET" --arg pwd "$API_PASSWORD" '
        .api_server.enabled = true |
        .api_server.listen_ip_address = "0.0.0.0" |
        .api_server.listen_port = 8080 |
        .api_server.jwt_secret_key = $jwt |
        .api_server.username = "freqtrader" |
        .api_server.password = $pwd |
        .dry_run = true |
        .dry_run_wallet = 1000 |
        .exchange.name = "coinbase" |
        .exchange.pair_whitelist = ["BTC/USD", "ETH/USD"] |
        .bot_name = "freqtrade" |
        .initial_state = "stopped"
    ' > user_data/config_temp.json && mv user_data/config_temp.json user_data/config.json
else
    # Fallback: Update key settings with sed (basic approach)
    sed -i 's/"dry_run": false/"dry_run": true/' user_data/config.json
    warn "jq not found. Manual configuration update needed for API server settings."
fi

# Save credentials
echo "FreqUI Access:" > ~/freqtrade-credentials.txt
echo "URL: http://${IP_ADDR}:8080" >> ~/freqtrade-credentials.txt
echo "Username: freqtrader" >> ~/freqtrade-credentials.txt
echo "Password: ${API_PASSWORD}" >> ~/freqtrade-credentials.txt
chmod 600 ~/freqtrade-credentials.txt
done_msg

# ========================================
# 2. Build Custom Docker Image
# ========================================
progress "Building custom Freqtrade Docker image (this may take 3-5 minutes)"
cd $FREQTRADE_DIR
docker compose build
done_msg

# ========================================
# 3. Create Helper Scripts
# ========================================
progress "Creating helper scripts"

# Service startup script
cat << 'EOF' > ~/freqtrade/ft-start.sh
#!/bin/bash
# Start Freqtrade services
echo "Starting Freqtrade services..."
cd ~/freqtrade
docker compose up -d
echo "Services started. Access FreqUI at http://localhost:8080"
echo "Check status with: ./ft-status.sh"
EOF
chmod +x ~/freqtrade/ft-start.sh

# Service stop script
cat << 'EOF' > ~/freqtrade/ft-stop.sh
#!/bin/bash
# Stop Freqtrade services
echo "Stopping Freqtrade services..."
cd ~/freqtrade
docker compose down
echo "Services stopped."
EOF
chmod +x ~/freqtrade/ft-stop.sh

# Status check script
cat << 'EOF' > ~/freqtrade/ft-status.sh
#!/bin/bash
echo "=== Docker Containers ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(NAMES|freqtrade)"
echo ""
echo "=== Recent Logs ==="
if docker ps --format "{{.Names}}" | grep -q "^freqtrade$"; then
    docker logs freqtrade --tail 5
else
    echo "Freqtrade container is not running. Use ./ft-start.sh to start services."
fi
EOF
chmod +x ~/freqtrade/ft-status.sh

# Logs script
cat << 'EOF' > ~/freqtrade/ft-logs.sh
#!/bin/bash
if docker ps --format "{{.Names}}" | grep -q "^freqtrade$"; then
    docker logs freqtrade --tail 100 -f
else
    echo "Freqtrade container is not running. Use ./ft-start.sh to start services."
fi
EOF
chmod +x ~/freqtrade/ft-logs.sh

# Data download script
cat << 'EOF' > ~/freqtrade/ft-download-data.sh
#!/bin/bash
cd ~/freqtrade
docker compose run --rm freqtrade download-data --config /freqtrade/user_data/config.json --days 30 --timeframes 1h 5m
EOF
chmod +x ~/freqtrade/ft-download-data.sh

# Backtesting script
cat << 'EOF' > ~/freqtrade/ft-backtest.sh
#!/bin/bash
cd ~/freqtrade
docker compose run --rm freqtrade backtesting --config /freqtrade/user_data/config.json --strategy SampleStrategy
EOF
chmod +x ~/freqtrade/ft-backtest.sh

# Shell access script
cat << 'EOF' > ~/freqtrade/ft-bash.sh
#!/bin/bash
if docker ps --format "{{.Names}}" | grep -q "^freqtrade$"; then
    docker exec -it freqtrade bash
else
    echo "Freqtrade container is not running. Use ./ft-start.sh to start services."
fi
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
echo "📡 Access Information (when started):"
echo "   FreqUI: http://${IP_ADDR}:8080"
echo "   Credentials: ~/freqtrade-credentials.txt"
echo ""
echo "📦 Freqtrade Configuration:"
echo "   Fork: FraAlleDevs/freqtrade (develop branch)"
echo "   Mode: DRY-RUN (paper trading)"
echo "   Config: ~/freqtrade/user_data/config.json"
echo "   Directory: ~/freqtrade"
echo ""
echo "🔧 Management Scripts:"
echo "   ~/freqtrade/ft-start.sh     - Start Freqtrade services"
echo "   ~/freqtrade/ft-stop.sh      - Stop Freqtrade services"
echo "   ~/freqtrade/ft-status.sh    - Check status and logs"
echo "   ~/freqtrade/ft-logs.sh      - Follow live logs"
echo "   ~/freqtrade/ft-download-data.sh - Download market data"
echo "   ~/freqtrade/ft-backtest.sh  - Run backtesting"
echo "   ~/freqtrade/ft-bash.sh      - Access container shell"
echo ""
echo "⚠️  Next Steps:"
echo "   1. Start services: ~/freqtrade/ft-start.sh"
echo "   2. Add exchange API keys to ~/freqtrade/user_data/config.json"
echo "   3. Download data: ~/freqtrade/ft-download-data.sh"
echo "   4. Restart after config changes: ~/freqtrade/ft-stop.sh && ~/freqtrade/ft-start.sh"
echo ""
echo "ℹ️  Note: Services are NOT automatically started. Use ft-start.sh when ready."
echo "================================================"