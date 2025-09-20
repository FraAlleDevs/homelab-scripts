# Launcher Scripts

This directory contains orchestration scripts that combine multiple components and guide users through
complex setup processes.

## 📁 Launchers Overview

```text
launchers/
└── macbook-freqtrade-server-init.sh    # Complete MacBook Freqtrade server setup
```

## 🚀 Orchestration Scripts

### `macbook-freqtrade-server-init.sh`

**Purpose:** Comprehensive orchestration script that guides users through the complete setup process
for transforming a MacBook Pro 2011 into a dedicated Freqtrade trading server.

**What This Launcher Does:**

This script serves as a "setup wizard" that coordinates the execution of multiple system and application
scripts in the correct order, providing guidance and explanations at each step.

**Key Features:**

1. **Interactive Setup Process:**
   - Explains each step before execution
   - Allows user to choose automatic or manual execution
   - Provides detailed progress information
   - Handles errors gracefully with user guidance

2. **Complete System Orchestration:**
   - Coordinates system preparation
   - Manages application installation
   - Ensures proper execution order
   - Validates prerequisites

3. **User-Friendly Interface:**
   - Clear explanations of what each step does
   - Progress indicators
   - Option to skip steps or run manually
   - Post-installation guidance

**Usage:**

```bash
bash launchers/macbook-freqtrade-server-init.sh
```

**What the Launcher Orchestrates:**

### Phase 1: System Preparation

```bash
# Automatically runs or guides user through:
bash system/macbook-server-setup.sh
```

**This phase includes:**

- Network configuration and updates
- SSH hardening and security setup
- Firewall configuration
- Docker installation
- System optimization for server use
- Power management configuration

### Phase 2: Application Installation

```bash
# Automatically runs or guides user through:
bash applications/freqtrade-install.sh
```

**This phase includes:**

- Freqtrade Docker setup
- Trading bot configuration
- Web UI setup
- Helper scripts creation
- Security configuration

### Phase 3: Post-Installation Setup

- User creation guidance
- Network testing
- Service verification
- Quick start instructions

**Interactive Flow:**

When you run the launcher, you'll see:

```text
===========================================
MacBook Freqtrade Server Initialization
===========================================

This script will guide you through setting up a MacBook Pro 2011
as a dedicated Freqtrade cryptocurrency trading server.

The process includes:
1. System preparation and hardening
2. Freqtrade installation and configuration
3. Security setup and optimization

Would you like to:
[A] Run automatic setup (recommended)
[M] Manual step-by-step execution
[I] Information only (no changes)
[Q] Quit

Your choice:
```

**Execution Modes:**

### Automatic Mode (`A`)

- Runs all scripts automatically in sequence
- Shows progress and logs
- Stops on errors for user intervention
- Fastest method for experienced users

### Manual Mode (`M`)

- Presents each step with explanation
- User confirms before each execution
- Allows skipping steps if already completed
- Best for learning or customization

### Information Mode (`I`)

- Shows what would be done without executing
- Useful for understanding the process
- Generates a checklist for manual execution
- Safe way to preview changes

**Step-by-Step Process:**

### 1. Pre-flight Checks

```text
Checking prerequisites:
✓ Ubuntu Server detected
✓ Internet connectivity available
✓ Sudo privileges confirmed
✓ Sufficient disk space available

Ready to proceed with setup...
```

### 2. System Setup Phase

```text
PHASE 1: System Preparation
==========================

This will:
- Update system packages
- Configure network settings
- Install and configure Docker
- Setup SSH security (port 2222)
- Configure firewall (UFW)
- Install Fail2Ban
- Optimize power management

Estimated time: 10-15 minutes

Proceed with system setup? [Y/n]:
```

### 3. Application Setup Phase

```text
PHASE 2: Freqtrade Installation
===============================

This will:
- Install Freqtrade trading bot
- Configure Docker Compose
- Setup web UI (port 8080)
- Create helper scripts
- Configure trading pairs
- Setup dry-run mode

Estimated time: 5-10 minutes

Proceed with Freqtrade installation? [Y/n]:
```

### 4. Final Configuration

```text
PHASE 3: Final Configuration
============================

Setup complete! Now you can:

1. Create a user account:
   sudo bash system/add-user.sh username

2. Access Freqtrade web UI:
   http://your-ip:8080

3. Start server monitoring:
   ./system/serverwatch start your-ip

4. Test connectivity:
   bash system/test-connection.sh

Would you like to create a user account now? [Y/n]:
```

**Error Handling:**

The launcher includes comprehensive error handling:

```text
ERROR: System setup failed at step 3 (Docker installation)

Possible solutions:
1. Check internet connectivity
2. Verify package repositories are accessible
3. Ensure sufficient disk space

Would you like to:
[R] Retry this step
[S] Skip and continue (not recommended)
[M] Switch to manual mode
[Q] Quit and fix manually

Your choice:
```

**Post-Installation Summary:**

After successful completion:

```text
===========================================
Setup Complete! 🎉
===========================================

Your MacBook Freqtrade server is ready!

System Information:
- Server IP: 192.168.1.100
- SSH Port: 2222 (and 22 during transition)
- Freqtrade UI: http://192.168.1.100:8080

Next Steps:
1. Reboot to complete setup: sudo reboot
2. Create user accounts: sudo bash system/add-user.sh username
3. Configure exchange API keys in ~/freqtrade/config.json
4. Start monitoring: ./system/serverwatch start 192.168.1.100

Documentation:
- System scripts: ./system/README.md
- Applications: ./applications/README.md
- Main documentation: ./README.md

Happy trading! 📈
```

**Advanced Options:**

### Environment Variables

The launcher supports environment variables for automation:

```bash
# Run in automatic mode without prompts
FREQTRADE_AUTO=true bash launchers/macbook-freqtrade-server-init.sh

# Skip system setup (if already done)
FREQTRADE_SKIP_SYSTEM=true bash launchers/macbook-freqtrade-server-init.sh

# Custom configuration
FREQTRADE_USER=trader FREQTRADE_AUTO=true bash launchers/macbook-freqtrade-server-init.sh
```

### Log Files

The launcher creates detailed logs:

```bash
# View setup logs
tail -f /tmp/freqtrade-setup.log

# View error logs
tail -f /tmp/freqtrade-setup-errors.log
```

**Troubleshooting:**

### Common Issues

**Script Won't Start:**

```bash
# Check permissions
chmod +x launchers/macbook-freqtrade-server-init.sh

# Run with bash explicitly
bash launchers/macbook-freqtrade-server-init.sh
```

**System Setup Fails:**

```bash
# Check system requirements
lsb_release -a  # Confirm Ubuntu
df -h          # Check disk space
ping -c 3 8.8.8.8  # Test internet
```

**Docker Issues:**

```bash
# Check Docker installation
docker --version
docker ps

# Restart Docker if needed
sudo systemctl restart docker
```

**Network Issues:**

```bash
# Test connectivity
bash system/test-connection.sh

# Check firewall
sudo ufw status
```

### Recovery Options

**Partial Installation:**
If setup fails partway through, you can:

1. **Resume from where it failed:**

   ```bash
   # The launcher will detect completed steps
   bash launchers/macbook-freqtrade-server-init.sh
   ```

2. **Run individual components:**

   ```bash
   # Just system setup
   bash system/macbook-server-setup.sh

   # Just Freqtrade installation
   bash applications/freqtrade-install.sh
   ```

3. **Clean restart:**

   ```bash
   # Remove partial installation
   sudo docker-compose -f ~/freqtrade/docker-compose.yml down
   rm -rf ~/freqtrade/

   # Run launcher again
   bash launchers/macbook-freqtrade-server-init.sh
   ```

## 📋 Quick Reference

### Command Options

```bash
# Standard interactive setup
bash launchers/macbook-freqtrade-server-init.sh

# Automatic mode (no prompts)
FREQTRADE_AUTO=true bash launchers/macbook-freqtrade-server-init.sh

# Information only (preview)
FREQTRADE_INFO_ONLY=true bash launchers/macbook-freqtrade-server-init.sh

# With custom user creation
FREQTRADE_USER=myuser bash launchers/macbook-freqtrade-server-init.sh
```

### Expected Timeline

- **System Preparation:** 10-15 minutes
- **Application Installation:** 5-10 minutes
- **Final Configuration:** 2-5 minutes
- **Total Setup Time:** 20-30 minutes

### Prerequisites Checklist

Before running the launcher, ensure:

- [ ] MacBook Pro 2011 with Ubuntu Server installed
- [ ] Ethernet connection for initial setup
- [ ] User account with sudo privileges
- [ ] At least 10GB free disk space
- [ ] Internet connectivity

## 🎯 Design Philosophy

This launcher follows the principle of "progressive disclosure" - presenting information and options
when needed without overwhelming the user. It's designed to:

- **Guide newcomers** through the complex setup process
- **Speed up experienced users** with automatic modes
- **Provide flexibility** for customization needs
- **Handle errors gracefully** with recovery options
- **Document everything** for learning and troubleshooting

The goal is to transform a complex multi-script setup into a single, user-friendly experience while
maintaining the modularity and flexibility of the individual components.
