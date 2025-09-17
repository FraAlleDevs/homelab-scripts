#!/bin/bash

check_connection() {
    echo "=== Connection Status Check ==="
    echo "Time: $(date)"
    echo ""
    
    # Check WiFi
    if command -v networksetup &> /dev/null; then
        SSID=$(networksetup -getairportnetwork en0 2>/dev/null | grep -o ': .*' | cut -c 3-)
        echo "WiFi SSID: '$SSID'"
        if [[ "$SSID" == "AJS Net" ]]; then
            echo "✅ Connected to home WiFi"
        fi
    fi
    
    # Check WireGuard
    echo ""
    echo "WireGuard status:"
    if command -v wg &> /dev/null; then
        if sudo wg show 2>/dev/null | grep -q "interface:"; then
            echo "✅ WireGuard active (wg command)"
            sudo wg show 2>/dev/null | head -5
        fi
    fi
    
    # Check VPN via scutil
    if command -v scutil &> /dev/null; then
        echo ""
        echo "VPN connections (scutil):"
        scutil --nc list | grep -i vpn
    fi
    
    # Check network interfaces
    echo ""
    echo "VPN interfaces:"
    ifconfig -a 2>/dev/null | grep -E "^(utun|wg)" | while read line; do
        echo "  Found: $line"
    done
}

check_connection