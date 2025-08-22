#!/bin/bash
# Quick check if upgrade is done

if [ -f ~/upgrade-complete.marker ]; then
    echo "🎉 UPGRADE IS COMPLETE!"
    echo "📋 Final status:"
    tail -5 ~/upgrade-status.log
    echo ""
    echo "✅ Ready to run: bash macbook-server-setup.sh"
elif pgrep -f "ubuntu-release-upgrader" > /dev/null; then
    echo "⏳ Upgrade still running..."
    echo "📋 Latest status:"
    tail -3 ~/upgrade-status.log 2>/dev/null || echo "Monitor not started yet"
else
    echo "❓ Upgrade process not found - may have finished"
    echo "Run: bash macbook-server-setup.sh to continue"
fi