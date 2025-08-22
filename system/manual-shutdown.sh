#!/bin/bash
# Use this script for intentional shutdowns to prevent auto-reboot
echo "Creating manual shutdown marker..."
sudo touch /tmp/manual-shutdown
sudo shutdown -h now
