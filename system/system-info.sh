#!/bin/bash
echo "IP: $(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)"
echo "SSH Port: 2222 (currently also 22)"
echo "FreqUI: http://$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1):8080"
echo "Uptime: $(uptime -p)"
