#!/bin/bash
#
# NNTmux PreDB Match Rate Monitor
# Tracks PreDB matching progress and reports improvement metrics
#
# Usage: ./monitor-predb-matching.sh [interval_seconds]
#

set -e

# Configuration
INTERVAL=${1:-60}  # Default: check every 60 seconds
DB_NAME="nntmux"
REPORT_FILE="/tmp/predb_monitoring_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to execute SQL query
query_db() {
    mysql -N -B "$DB_NAME" -e "$1" 2>/dev/null
}

# Function to format numbers with commas
format_number() {
    printf "%'d" "$1"
}

# Function to calculate percentage
calc_percentage() {
    local part=$1
    local total=$2
    if [ "$total" -eq 0 ]; then
        echo "0.00"
    else
        echo "scale=2; ($part / $total) * 100" | bc
    fi
}

# Function to get current statistics
get_stats() {
    local total=$(query_db "SELECT COUNT(*) FROM releases;")
    local matched=$(query_db "SELECT COUNT(*) FROM releases WHERE predb_id > 0;")
    local unmatched=$(query_db "SELECT COUNT(*) FROM releases WHERE predb_id = 0;")
    local proc_nfo_pending=$(query_db "SELECT COUNT(*) FROM releases WHERE proc_nfo = 0;")
    local proc_files_pending=$(query_db "SELECT COUNT(*) FROM releases WHERE proc_files = 0;")
    local match_rate=$(calc_percentage "$matched" "$total")

    echo "$total|$matched|$unmatched|$proc_nfo_pending|$proc_files_pending|$match_rate"
}

# Function to display header
display_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         NNTmux PreDB Match Rate Monitor - v2.2.2 Fuzzy Matching           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Started:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${YELLOW}Interval:${NC} ${INTERVAL}s"
    echo -e "${YELLOW}Report:${NC} $REPORT_FILE"
    echo ""
}

# Function to display current stats
display_stats() {
    local stats=$1
    local iteration=$2

    IFS='|' read -r total matched unmatched proc_nfo_pending proc_files_pending match_rate <<< "$stats"

    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Iteration #${iteration}${NC} - $(date '+%H:%M:%S')"
    echo -e "${BLUE}───────────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${CYAN}Total Releases:${NC}        $(format_number $total)"
    echo -e "  ${GREEN}✓ Matched (PreDB):${NC}    $(format_number $matched) (${match_rate}%)"
    echo -e "  ${RED}✗ Unmatched:${NC}          $(format_number $unmatched)"
    echo ""
    echo -e "  ${YELLOW}Processing Queue:${NC}"
    echo -e "    • NFO pending:       $(format_number $proc_nfo_pending)"
    echo -e "    • Files pending:     $(format_number $proc_files_pending)"
    echo ""
}

# Function to display delta (changes since last check)
display_delta() {
    local prev_stats=$1
    local curr_stats=$2

    if [ -z "$prev_stats" ]; then
        return
    fi

    IFS='|' read -r prev_total prev_matched prev_unmatched prev_nfo prev_files prev_rate <<< "$prev_stats"
    IFS='|' read -r curr_total curr_matched curr_unmatched curr_nfo curr_files curr_rate <<< "$curr_stats"

    local delta_matched=$((curr_matched - prev_matched))
    local delta_unmatched=$((curr_unmatched - prev_unmatched))
    local delta_nfo=$((prev_nfo - curr_nfo))
    local delta_files=$((prev_files - curr_files))
    local delta_rate=$(echo "scale=2; $curr_rate - $prev_rate" | bc)

    echo -e "${BLUE}───────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${YELLOW}Changes (since last check):${NC}"

    if [ "$delta_matched" -gt 0 ]; then
        echo -e "    • New PreDB matches:  ${GREEN}+$(format_number $delta_matched)${NC}"
    elif [ "$delta_matched" -lt 0 ]; then
        echo -e "    • PreDB matches:      ${RED}$(format_number $delta_matched)${NC}"
    else
        echo -e "    • New PreDB matches:  ${YELLOW}0${NC}"
    fi

    if [ "$delta_nfo" -gt 0 ]; then
        echo -e "    • NFO processed:      ${GREEN}+$(format_number $delta_nfo)${NC}"
    fi

    if [ "$delta_files" -gt 0 ]; then
        echo -e "    • Files processed:    ${GREEN}+$(format_number $delta_files)${NC}"
    fi

    if [ "$delta_matched" -gt 0 ]; then
        local rate_per_min=$(echo "scale=2; ($delta_matched * 60) / $INTERVAL" | bc)
        echo -e "    • Match rate:         ${GREEN}${rate_per_min}/min${NC}"
        echo -e "    • Match % change:     ${GREEN}+${delta_rate}%${NC}"
    fi

    echo ""
}

# Function to log to file
log_stats() {
    local iteration=$1
    local stats=$2

    IFS='|' read -r total matched unmatched proc_nfo_pending proc_files_pending match_rate <<< "$stats"

    echo "$(date '+%Y-%m-%d %H:%M:%S'),$iteration,$total,$matched,$unmatched,$proc_nfo_pending,$proc_files_pending,$match_rate" >> "$REPORT_FILE"
}

# Function to display summary
display_summary() {
    local start_stats=$1
    local end_stats=$2
    local iterations=$3
    local elapsed=$4

    IFS='|' read -r start_total start_matched start_unmatched start_nfo start_files start_rate <<< "$start_stats"
    IFS='|' read -r end_total end_matched end_unmatched end_nfo end_files end_rate <<< "$end_stats"

    local total_new_matches=$((end_matched - start_matched))
    local total_rate_change=$(echo "scale=2; $end_rate - $start_rate" | bc)
    local avg_matches_per_min=$(echo "scale=2; ($total_new_matches * 60) / $elapsed" | bc)

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                            MONITORING SUMMARY                              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${YELLOW}Duration:${NC}              $(printf '%02d:%02d:%02d' $((elapsed/3600)) $((elapsed%3600/60)) $((elapsed%60)))"
    echo -e "  ${YELLOW}Iterations:${NC}            $iterations"
    echo ""
    echo -e "  ${CYAN}Starting Match Rate:${NC}   ${start_rate}% ($(format_number $start_matched) releases)"
    echo -e "  ${CYAN}Ending Match Rate:${NC}     ${end_rate}% ($(format_number $end_matched) releases)"
    echo ""
    if [ "$total_new_matches" -gt 0 ]; then
        echo -e "  ${GREEN}✓ Total New Matches:${NC}   $(format_number $total_new_matches)"
        echo -e "  ${GREEN}✓ Match Rate Gain:${NC}     +${total_rate_change}%"
        echo -e "  ${GREEN}✓ Avg Match Rate:${NC}      ${avg_matches_per_min}/min"
    else
        echo -e "  ${YELLOW}No new matches detected${NC}"
    fi
    echo ""
    echo -e "  ${YELLOW}Report saved to:${NC}"
    echo -e "  ${BLUE}$REPORT_FILE${NC}"
    echo ""
}

# Main monitoring loop
main() {
    display_header

    # Create CSV header in report file
    echo "timestamp,iteration,total_releases,matched,unmatched,proc_nfo_pending,proc_files_pending,match_rate" > "$REPORT_FILE"

    echo -e "${GREEN}Starting monitoring... Press Ctrl+C to stop${NC}"
    echo ""

    local iteration=0
    local prev_stats=""
    local start_stats=""
    local start_time=$(date +%s)

    # Trap Ctrl+C to display summary
    trap 'echo ""; echo -e "${YELLOW}Stopping monitor...${NC}"; display_summary "$start_stats" "$prev_stats" "$iteration" "$(($(date +%s) - start_time))"; exit 0' INT

    while true; do
        iteration=$((iteration + 1))

        # Get current stats
        curr_stats=$(get_stats)

        # Store starting stats
        if [ -z "$start_stats" ]; then
            start_stats="$curr_stats"
        fi

        # Display stats
        display_stats "$curr_stats" "$iteration"

        # Display delta if we have previous stats
        if [ -n "$prev_stats" ]; then
            display_delta "$prev_stats" "$curr_stats"
        fi

        # Log to file
        log_stats "$iteration" "$curr_stats"

        # Store current as previous for next iteration
        prev_stats="$curr_stats"

        # Wait for next iteration
        echo -e "${YELLOW}Next check in ${INTERVAL}s...${NC}"
        sleep "$INTERVAL"

        # Clear for next iteration
        clear
        display_header
    done
}

# Run main function
main
