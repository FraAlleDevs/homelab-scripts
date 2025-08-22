#!/bin/bash
# Wake up the MacBook remotely using Wake-on-LAN
# Usage: bash wake-macbook.sh
# Or from another machine: wakeonlan c8:2a:14:26:78:92

echo "Sending Wake-on-LAN packet to MAC: c8:2a:14:26:78:92"
wakeonlan c8:2a:14:26:78:92
echo "Wake packet sent. Wait 30-60 seconds for boot."
