#!/bin/bash
#
# Add PreDB Match Rate Monitor to Tmux
# Creates a new pane in the NNTmux tmux session showing real-time monitoring
#
# Usage: ./tmux-add-monitor.sh [interval_seconds]
#

INTERVAL=${1:-30}
TMUX_SESSION="nntmux"
PANE_TITLE="PreDB-Monitor"

# Check if tmux session exists
if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
    echo "Error: Tmux session '$TMUX_SESSION' not found!"
    echo ""
    echo "Available sessions:"
    tmux list-sessions 2>/dev/null || echo "  No tmux sessions running"
    exit 1
fi

# Check if monitor pane already exists
if tmux list-panes -t "$TMUX_SESSION" -F "#{pane_title}" 2>/dev/null | grep -q "^$PANE_TITLE$"; then
    echo "Monitor pane already exists in session '$TMUX_SESSION'"
    echo ""
    read -p "Kill existing monitor and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Find and kill the pane
        PANE_ID=$(tmux list-panes -t "$TMUX_SESSION" -F "#{pane_id} #{pane_title}" | grep "$PANE_TITLE" | awk '{print $1}')
        if [ -n "$PANE_ID" ]; then
            tmux kill-pane -t "$TMUX_SESSION:$PANE_ID"
            echo "Existing monitor pane removed"
        fi
    else
        echo "Aborted"
        exit 0
    fi
fi

echo "Adding PreDB Match Rate Monitor to tmux session '$TMUX_SESSION'..."
echo "  Interval: ${INTERVAL}s"
echo ""

# Get the main window (usually window 0)
MAIN_WINDOW=$(tmux list-windows -t "$TMUX_SESSION" -F "#{window_index}" | head -1)

# Split the window to create a new pane at the bottom (20% height)
tmux split-window -t "$TMUX_SESSION:$MAIN_WINDOW" -v -p 20

# Get the new pane ID
NEW_PANE=$(tmux list-panes -t "$TMUX_SESSION:$MAIN_WINDOW" -F "#{pane_id}" | tail -1)

# Set the pane title
tmux select-pane -t "$TMUX_SESSION:$NEW_PANE" -T "$PANE_TITLE"

# Create a wrapper script that will run in the pane
WRAPPER_SCRIPT="/tmp/tmux_predb_monitor_$$.sh"
cat > "$WRAPPER_SCRIPT" << 'EOFSCRIPT'
#!/bin/bash

INTERVAL=%INTERVAL%
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Function to get stats
get_stats() {
    mysql -N -B nntmux -e "
    SELECT 
        COUNT(*),
        SUM(CASE WHEN predb_id > 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN predb_id = 0 THEN 1 ELSE 0 END),
        ROUND(SUM(CASE WHEN predb_id > 0 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2),
        SUM(CASE WHEN proc_nfo = 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN proc_files = 0 THEN 1 ELSE 0 END)
    FROM releases;
    " 2>/dev/null
}

# Store initial stats
INITIAL_STATS=$(get_stats)
START_TIME=$(date +%s)

while true; do
    clear
    
    # Header
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     NNTmux PreDB Match Rate Monitor - v2.2.2 Fuzzy Matching Active      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Get current stats
    CURRENT_STATS=$(get_stats)
    read -r total matched unmatched match_rate nfo_pending files_pending <<< "$CURRENT_STATS"
    
    # Calculate runtime
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    HOURS=$((ELAPSED / 3600))
    MINUTES=$(((ELAPSED % 3600) / 60))
    SECONDS=$((ELAPSED % 60))
    
    # Format numbers
    total_fmt=$(printf "%'d" "$total")
    matched_fmt=$(printf "%'d" "$matched")
    unmatched_fmt=$(printf "%'d" "$unmatched")
    nfo_fmt=$(printf "%'d" "$nfo_pending")
    files_fmt=$(printf "%'d" "$files_pending")
    
    echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC}  |  Runtime: ${YELLOW}$(printf '%02d:%02d:%02d' $HOURS $MINUTES $SECONDS)${NC}"
    echo ""
    echo -e "${CYAN}Current Statistics:${NC}"
    echo -e "  Total Releases:        $total_fmt"
    echo -e "  ${GREEN}✓ Matched (PreDB):${NC}     $matched_fmt ${GREEN}($match_rate%)${NC}"
    echo -e "  ${RED}✗ Unmatched:${NC}           $unmatched_fmt"
    echo ""
    echo -e "${CYAN}Processing Queue:${NC}"
    echo -e "  NFO pending:           $nfo_fmt"
    echo -e "  Files pending:         $files_fmt"
    echo ""
    
    # Calculate improvement since start
    if [ -n "$INITIAL_STATS" ]; then
        read -r init_total init_matched init_unmatched init_rate init_nfo init_files <<< "$INITIAL_STATS"
        
        new_matches=$((matched - init_matched))
        rate_change=$(echo "scale=2; $match_rate - $init_rate" | bc)
        processed_nfo=$((init_nfo - nfo_pending))
        processed_files=$((init_files - files_pending))
        
        if [ "$new_matches" -gt 0 ] || [ "$processed_nfo" -gt 0 ]; then
            echo -e "${CYAN}Progress Since Start:${NC}"
            
            if [ "$new_matches" -gt 0 ]; then
                echo -e "  ${GREEN}✓ New PreDB Matches:${NC}   $(printf "%'d" $new_matches) ${GREEN}(+${rate_change}%)${NC}"
                
                if [ "$ELAPSED" -gt 0 ]; then
                    rate_per_min=$(echo "scale=2; ($new_matches * 60) / $ELAPSED" | bc)
                    echo -e "  ${GREEN}✓ Match Rate:${NC}          ${rate_per_min}/min"
                fi
            fi
            
            if [ "$processed_nfo" -gt 0 ]; then
                echo -e "  ${BLUE}• NFO Processed:${NC}       $(printf "%'d" $processed_nfo)"
            fi
            
            if [ "$processed_files" -gt 0 ]; then
                echo -e "  ${BLUE}• Files Processed:${NC}     $(printf "%'d" $processed_files)"
            fi
            
            echo ""
        fi
    fi
    
    # Check active processes
    if ps aux | grep -E 'releases:fix-names|update:postprocess' | grep -v grep > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Postprocessing ACTIVE${NC}"
    else
        echo -e "${YELLOW}⚠ Postprocessing IDLE${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "  Refreshing in ${INTERVAL}s... (Press Ctrl+C in this pane to stop monitor)"
    
    sleep "$INTERVAL"
done
EOFSCRIPT

# Replace placeholder with actual interval
sed -i "s/%INTERVAL%/$INTERVAL/g" "$WRAPPER_SCRIPT"
chmod +x "$WRAPPER_SCRIPT"

# Send commands to the new pane
tmux send-keys -t "$TMUX_SESSION:$NEW_PANE" "cd /opt/nntmux" C-m
tmux send-keys -t "$TMUX_SESSION:$NEW_PANE" "$WRAPPER_SCRIPT" C-m

# Clean up wrapper script after a delay (in background)
(sleep 5 && rm -f "$WRAPPER_SCRIPT") &

echo ""
echo -e "\033[0;32m✓ PreDB Monitor added successfully!\033[0m"
echo ""
echo "To view the monitor:"
echo "  tmux attach-session -t $TMUX_SESSION"
echo ""
echo "To remove the monitor pane:"
echo "  tmux kill-pane -t $TMUX_SESSION:$NEW_PANE"
echo ""
echo "The monitor is now running and will update every ${INTERVAL}s"
