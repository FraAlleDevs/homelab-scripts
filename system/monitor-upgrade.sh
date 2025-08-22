#!/bin/bash
# Monitor Ubuntu upgrade completion and notify when done

echo "🔍 Monitoring Ubuntu upgrade process (PID 14091)..."
echo "💡 You can safely close this terminal - script runs in background"
echo "📄 Check progress: tail -f ~/upgrade-status.log"
echo ""

# Function to check if process is running
is_running() {
    kill -0 "$1" 2>/dev/null
}

# Monitor in background
(
    START_TIME=$(date)
    echo "[$START_TIME] Upgrade monitoring started" > ~/upgrade-status.log
    
    # Wait for process to finish
    while is_running 14091; do
        sleep 30
        echo "[$(date)] Upgrade still running..." >> ~/upgrade-status.log
    done
    
    # Process finished
    END_TIME=$(date)
    echo "[$END_TIME] ✅ UPGRADE COMPLETED!" >> ~/upgrade-status.log
    echo "[$END_TIME] ✅ UPGRADE COMPLETED!" | tee -a ~/upgrade-status.log
    
    # Multiple notification methods
    echo -e "\a\a\a"  # Terminal bell (if speakers connected)
    echo "🎉 Ubuntu upgrade finished at $END_TIME" | wall 2>/dev/null || true
    logger "Ubuntu upgrade completed at $END_TIME"
    
    # Create completion marker
    touch ~/upgrade-complete.marker
    echo "Ready to run: bash macbook-server-setup.sh" >> ~/upgrade-status.log
    
) &

echo "✅ Monitoring started in background"
echo "📋 Status file: ~/upgrade-status.log" 
echo "🔔 Completion marker: ~/upgrade-complete.marker"
echo ""
echo "💻 To check from another machine:"
SERVER_IP=$(ip -4 addr show | grep inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d/ -f1 | head -1)
echo "   ssh -p 2222 $USER@$SERVER_IP 'cat ~/upgrade-status.log'"