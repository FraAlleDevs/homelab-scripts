# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a collection of bash automation scripts for setting up and managing homelab infrastructure, specifically designed for transforming MacBook Pro 2011 machines into Ubuntu Server-based homelab nodes with Freqtrade cryptocurrency trading bot capabilities.

## Architecture

### Three-Layer Script Architecture

1. **System Layer** (`system/`): Core infrastructure scripts for Ubuntu Server setup, security hardening, user management, and system utilities
2. **Application Layer** (`applications/`): Application-specific installation scripts (currently Freqtrade)  
3. **Orchestration Layer** (`launchers/`): High-level scripts that coordinate system and application layers for complete automated setup

### Key Design Patterns

- **Modular Architecture**: Each script is self-contained and can be run independently
- **Progressive Setup**: Scripts can be run in sequence (system → application) or orchestrated via launchers
- **Error Handling**: Scripts include comprehensive error handling with user intervention points
- **Logging and Status**: Built-in logging, status reporting, and monitoring capabilities
- **Security First**: SSH hardening, firewall configuration, and secure credential generation throughout

## Common Commands

### Documentation
```bash
# Lint markdown files (auto-fix on save with Cmd+S in VS Code)
# Markdownlint configuration in .markdownlint.json enforces 120 char line length

# View comprehensive documentation
cat README.md                    # Main overview
cat system/README.md             # System scripts details  
cat applications/README.md       # Application scripts details
cat launchers/README.md          # Orchestration scripts details
```

### Primary Workflows
```bash
# Complete automated setup (recommended)
bash launchers/macbook-freqtrade-server-init.sh

# Manual step-by-step setup
bash system/macbook-server-setup.sh              # System preparation (run once)
bash applications/freqtrade-install.sh           # Application installation
sudo bash system/add-user.sh <username>          # User creation

# Server monitoring and maintenance
./system/serverwatch start <ip>                  # Start monitoring daemon
./system/serverwatch status                      # Check monitoring status
bash system/system-info.sh                       # Display connection info
bash system/test-connection.sh                   # Test network connectivity
```

### Development and Testing
```bash
# Test individual scripts
bash system/brightness-control.sh status         # Test display management
bash system/manual-shutdown.sh                   # Test safe shutdown

# Monitor script execution
tail -f ~/.serverwatch/monitor.log               # Server monitoring logs
docker-compose -f ~/freqtrade/docker-compose.yml logs -f  # Freqtrade logs

# Validation
bash system/check-upgrade.sh                     # Check system upgrade status
sudo ufw status                                  # Verify firewall configuration
docker ps                                        # Check running containers
```

## Critical Implementation Details

### SSH Security Model
- Scripts migrate SSH from port 22 to 2222 while keeping both ports active during transition
- Root login disabled, Fail2Ban configured, max 3 auth attempts
- Scripts should never assume port 22 - always specify port 2222 for remote operations

### ServerWatch Daemon Architecture
- `system/serverwatch` is a sophisticated daemon with PID management, signal handling, and smart network detection
- Implements intelligent monitoring that reduces check frequency when away from home network
- Uses network detection logic: home WiFi SSID "AJS Net", VPN "vpn@ajs", or IP range 192.168.178.x
- Stores state in `~/.serverwatch/` with JSON statistics, configuration, and rotating logs

### Freqtrade Integration
- Always installs in dry-run mode (paper trading) for safety
- Creates helper scripts in `~/freqtrade/` for common operations (ft-status.sh, ft-logs.sh, etc.)
- Configured for Binance exchange with BTC/USDT and ETH/USDT pairs
- Web UI accessible on port 8080 with secure JWT authentication

### User Management Pattern
- `system/add-user.sh` creates users with full homelab permissions (sudo, docker groups)
- Generates secure random passwords saved to `/root/<username>_credentials.txt`
- Sets up SSH directory, Freqtrade workspace, and useful bash aliases
- Requires logout/login for docker group membership to take effect

## VS Code Configuration

The repository includes VS Code workspace settings that:
- Enable markdownlint auto-fix on save (`Cmd+S`)
- Enforce 120-character line length for markdown files
- Configure proper formatting and linting for documentation
- Disable auto-save (manual save required to trigger fixes)

## Script Execution Context

- All scripts designed to run as regular user with sudo when needed
- Never run scripts as root directly - they use sudo internally for privileged operations
- Scripts assume Ubuntu Server environment with internet connectivity
- Target hardware: MacBook Pro 2011, but adaptable to other Ubuntu Server installations

## Security Considerations

- Scripts handle sensitive data (SSH keys, passwords, API credentials) securely
- Firewall configured with minimal open ports (22, 2222, 8080)
- All network services configured with security best practices
- Credential generation uses cryptographically secure methods