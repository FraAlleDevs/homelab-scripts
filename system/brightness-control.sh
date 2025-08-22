#!/bin/bash
# Remote Screen Brightness Control for MacBook Server
# Usage: brightness-control.sh [on|off|status|level] [brightness%] [timeout_minutes]

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get backlight interfaces and their max values
get_backlights() {
    for backlight_dir in /sys/class/backlight/*; do
        if [ -d "$backlight_dir" ]; then
            interface=$(basename "$backlight_dir")
            max_brightness=$(cat "$backlight_dir/max_brightness" 2>/dev/null || echo "0")
            current=$(cat "$backlight_dir/brightness" 2>/dev/null || echo "0")
            echo "$interface:$max_brightness:$current"
        fi
    done
}

# Set brightness for all interfaces
set_brightness() {
    local target_brightness="$1"
    local changed=false
    
    while IFS=':' read -r interface max_brightness current; do
        if [ "$max_brightness" -gt 0 ]; then
            brightness_file="/sys/class/backlight/$interface/brightness"
            if [ -w "$brightness_file" ]; then
                echo "$target_brightness" | sudo tee "$brightness_file" > /dev/null 2>&1
                changed=true
                echo -e "${BLUE}[$interface]${NC} Set to $target_brightness (max: $max_brightness)"
            fi
        fi
    done < <(get_backlights)
    
    if [ "$changed" = "false" ]; then
        echo -e "${YELLOW}Warning: No writable backlight interfaces found${NC}"
    fi
}

# Calculate brightness from percentage
calc_brightness() {
    local percentage="$1"
    local max_brightness="$2"
    echo $(( (max_brightness * percentage) / 100 ))
}

# Show current status
show_status() {
    echo -e "${BLUE}📺 Current Brightness Status:${NC}"
    while IFS=':' read -r interface max_brightness current; do
        if [ "$max_brightness" -gt 0 ]; then
            percentage=$(( (current * 100) / max_brightness ))
            status="OFF"
            [ "$current" -gt 0 ] && status="ON"
            echo -e "  $interface: $current/$max_brightness (${percentage}%) - ${status}"
        fi
    done < <(get_backlights)
}

# Auto turn off after timeout
auto_turnoff() {
    local timeout_minutes="$1"
    if [ "$timeout_minutes" -gt 0 ]; then
        echo -e "${YELLOW}⏰ Auto turn-off in $timeout_minutes minutes${NC}"
        (
            sleep $((timeout_minutes * 60))
            set_brightness 0
            echo -e "${BLUE}[$(date)]${NC} Screen automatically turned off" >> ~/brightness.log
        ) &
        echo "Background auto-off PID: $!"
    fi
}

# Main script
case "${1:-status}" in
    "on")
        percentage="${2:-75}"  # Default to 75%
        timeout="${3:-0}"      # Default no timeout
        
        echo -e "${GREEN}🔆 Turning screen brightness ON (${percentage}%)${NC}"
        
        while IFS=':' read -r interface max_brightness current; do
            if [ "$max_brightness" -gt 0 ]; then
                target=$(calc_brightness "$percentage" "$max_brightness")
                brightness_file="/sys/class/backlight/$interface/brightness"
                if [ -w "$brightness_file" ]; then
                    echo "$target" | sudo tee "$brightness_file" > /dev/null 2>&1
                    echo -e "${BLUE}[$interface]${NC} Set to $target/$max_brightness (${percentage}%)"
                fi
            fi
        done < <(get_backlights)
        
        echo "[$(date)] Screen turned ON at ${percentage}%" >> ~/brightness.log
        auto_turnoff "$timeout"
        ;;
        
    "off")
        echo -e "${GREEN}🔅 Turning screen brightness OFF${NC}"
        set_brightness 0
        echo "[$(date)] Screen turned OFF" >> ~/brightness.log
        ;;
        
    "level")
        level="${2:-0}"
        echo -e "${GREEN}🔧 Setting brightness level to $level${NC}"
        set_brightness "$level"
        echo "[$(date)] Screen set to level $level" >> ~/brightness.log
        ;;
        
    "status")
        show_status
        ;;
        
    "help"|"-h"|"--help")
        echo "Remote Screen Brightness Control"
        echo ""
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  on [percentage] [timeout_min]  - Turn screen on (default: 75%, no timeout)"
        echo "  off                           - Turn screen off"
        echo "  level [0-max]                - Set specific brightness level"
        echo "  status                       - Show current brightness status"
        echo "  help                         - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 on                        # Turn on at 75%"
        echo "  $0 on 50                     # Turn on at 50%"
        echo "  $0 on 100 5                  # Turn on at 100% for 5 minutes"
        echo "  $0 off                       # Turn off"
        echo "  $0 level 500                 # Set to specific level"
        echo ""
        echo "Remote usage:"
        echo "  ssh -p 2222 user@server 'bash ~/brightness-control.sh on'"
        ;;
        
    *)
        echo "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac