#!/bin/bash
#
# 24-Hour PreDB Match Rate Monitor
# Runs continuously for 24 hours, logging every hour
# Creates hourly reports and a final 24-hour summary
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Configuration
INTERVAL=3600  # 1 hour in seconds
DURATION=$((24 * 3600))  # 24 hours in seconds
START_TIME=$(date +%s)
END_TIME=$((START_TIME + DURATION))
SESSION_ID=$(date +%Y%m%d_%H%M%S)
LOG_DIR="/tmp/predb_24h_monitoring"
LOG_FILE="${LOG_DIR}/monitoring_${SESSION_ID}.csv"
SUMMARY_FILE="${LOG_DIR}/summary_${SESSION_ID}.txt"
HOURLY_DIR="${LOG_DIR}/hourly"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Create directories
mkdir -p "$LOG_DIR"
mkdir -p "$HOURLY_DIR"

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

# Function to format numbers
format_number() {
    printf "%'d" "$1"
}

# Function to save hourly report
save_hourly_report() {
    local hour=$1
    local stats=$2
    local prev_stats=$3
    local report_file="${HOURLY_DIR}/hour_${hour}.txt"

    IFS=' ' read -r total matched unmatched match_rate nfo_pending files_pending <<< "$stats"

    {
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║      Hour $hour of 24 - PreDB Match Rate Report                  "
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "Current Statistics:"
        echo "  Total Releases:     $(format_number $total)"
        echo "  Matched (PreDB):    $(format_number $matched) (${match_rate}%)"
        echo "  Unmatched:          $(format_number $unmatched)"
        echo "  NFO Queue:          $(format_number $nfo_pending)"
        echo "  Files Queue:        $(format_number $files_pending)"
        echo ""

        if [ -n "$prev_stats" ]; then
            IFS=' ' read -r prev_total prev_matched prev_unmatched prev_rate prev_nfo prev_files <<< "$prev_stats"

            local delta_matched=$((matched - prev_matched))
            local delta_rate=$(echo "scale=2; $match_rate - $prev_rate" | bc)
            local processed_nfo=$((prev_nfo - nfo_pending))

            echo "Progress in Last Hour:"
            echo "  New PreDB Matches:  $(format_number $delta_matched)"
            echo "  Match Rate Change:  +${delta_rate}%"
            echo "  NFOs Processed:     $(format_number $processed_nfo)"
            echo "  Match Rate/Hour:    $(echo "scale=2; $delta_matched / 1" | bc)/hour"
            echo ""
        fi

        echo "════════════════════════════════════════════════════════════════"
    } > "$report_file"

    echo "✓ Hourly report saved: $report_file"
}

# Initialize
echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     24-Hour PreDB Match Rate Monitoring - v2.2.2 Fuzzy        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Session ID:${NC}       $SESSION_ID"
echo -e "${YELLOW}Start Time:${NC}       $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${YELLOW}End Time:${NC}         $(date -d @$END_TIME '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r $END_TIME '+%Y-%m-%d %H:%M:%S')"
echo -e "${YELLOW}Interval:${NC}         1 hour"
echo -e "${YELLOW}Log File:${NC}         $LOG_FILE"
echo -e "${YELLOW}Summary File:${NC}     $SUMMARY_FILE"
echo ""

# Create CSV header
echo "timestamp,hour,elapsed_seconds,total_releases,matched,unmatched,match_rate,nfo_pending,files_pending,delta_matched,delta_rate" > "$LOG_FILE"

# Get initial stats
echo "Capturing initial baseline..."
INITIAL_STATS=$(get_stats)
PREVIOUS_STATS="$INITIAL_STATS"

IFS=' ' read -r init_total init_matched init_unmatched init_rate init_nfo init_files <<< "$INITIAL_STATS"

echo ""
echo -e "${GREEN}✓ Baseline captured:${NC}"
echo "  Total Releases:  $(format_number $init_total)"
echo "  Matched:         $(format_number $init_matched) (${init_rate}%)"
echo "  Unmatched:       $(format_number $init_unmatched)"
echo ""
echo -e "${BLUE}Starting 24-hour monitoring...${NC}"
echo "Press Ctrl+C to stop early and generate summary"
echo ""

# Trap Ctrl+C to generate summary
trap 'echo ""; echo "Monitoring interrupted. Generating summary..."; generate_final_summary; exit 0' INT

# Function to generate final summary
generate_final_summary() {
    local current_stats=$(get_stats)
    IFS=' ' read -r final_total final_matched final_unmatched final_rate final_nfo final_files <<< "$current_stats"

    local elapsed=$(($(date +%s) - START_TIME))
    local hours=$((elapsed / 3600))
    local minutes=$(((elapsed % 3600) / 60))

    local total_new_matches=$((final_matched - init_matched))
    local total_rate_change=$(echo "scale=2; $final_rate - $init_rate" | bc)
    local avg_matches_per_hour=$(echo "scale=2; $total_new_matches / ($elapsed / 3600)" | bc)

    {
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║           24-HOUR MONITORING FINAL SUMMARY                     ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Session ID:      $SESSION_ID"
        echo "Start Time:      $(date -d @$START_TIME '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -r $START_TIME '+%Y-%m-%d %H:%M:%S')"
        echo "End Time:        $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Duration:        ${hours}h ${minutes}m"
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "                    BASELINE vs FINAL                           "
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "                      BASELINE          FINAL           CHANGE"
        echo "Total Releases:       $(printf '%10s' "$(format_number $init_total)")     $(printf '%10s' "$(format_number $final_total)")     +$(format_number $((final_total - init_total)))"
        echo "Matched (PreDB):      $(printf '%10s' "$(format_number $init_matched)")     $(printf '%10s' "$(format_number $final_matched)")     +$(format_number $total_new_matches)"
        echo "Match Rate:           $(printf '%9s' "${init_rate}%")     $(printf '%9s' "${final_rate}%")     +${total_rate_change}%"
        echo "Unmatched:            $(printf '%10s' "$(format_number $init_unmatched)")     $(printf '%10s' "$(format_number $final_unmatched)")     $(format_number $((final_unmatched - init_unmatched)))"
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "                    PERFORMANCE METRICS                         "
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "Total New Matches:         $(format_number $total_new_matches)"
        echo "Match Rate Improvement:    +${total_rate_change}%"
        echo "Average Matches/Hour:      ${avg_matches_per_hour}"
        echo "NFOs Processed:            $(format_number $((init_nfo - final_nfo)))"
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "                    FILES & REPORTS                             "
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "Detailed Log:    $LOG_FILE"
        echo "Hourly Reports:  $HOURLY_DIR/hour_*.txt"
        echo "This Summary:    $SUMMARY_FILE"
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo ""

        if [ "$total_new_matches" -gt 0 ]; then
            echo "✅ SUCCESS! Fuzzy matching is working!"
            echo "   $(format_number $total_new_matches) new PreDB matches in ${hours}h ${minutes}m"
        else
            echo "⚠️  No new matches detected. Check:"
            echo "   - Is postprocessing running? (ps aux | grep postprocess)"
            echo "   - Are fuzzy matching settings enabled? (check .env)"
            echo "   - Run: cd /opt/nntmux && ./scripts/predb-status.sh"
        fi
        echo ""

    } | tee "$SUMMARY_FILE"

    echo "✓ Final summary saved to: $SUMMARY_FILE"
}

# Main monitoring loop
hour=0
while [ $(date +%s) -lt $END_TIME ]; do
    hour=$((hour + 1))

    echo -e "${CYAN}[Hour $hour/24]${NC} $(date '+%Y-%m-%d %H:%M:%S') - Collecting statistics..."

    # Get current stats
    CURRENT_STATS=$(get_stats)
    IFS=' ' read -r total matched unmatched match_rate nfo_pending files_pending <<< "$CURRENT_STATS"
    IFS=' ' read -r prev_total prev_matched prev_unmatched prev_rate prev_nfo prev_files <<< "$PREVIOUS_STATS"

    # Calculate deltas
    delta_matched=$((matched - prev_matched))
    delta_rate=$(echo "scale=2; $match_rate - $prev_rate" | bc)
    elapsed=$(($(date +%s) - START_TIME))

    # Log to CSV
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$hour,$elapsed,$total,$matched,$unmatched,$match_rate,$nfo_pending,$files_pending,$delta_matched,$delta_rate" >> "$LOG_FILE"

    # Display current status
    echo "  Total: $(format_number $total) | Matched: $(format_number $matched) (${match_rate}%) | New: +$(format_number $delta_matched)"

    # Save hourly report
    save_hourly_report "$hour" "$CURRENT_STATS" "$PREVIOUS_STATS"

    # Update previous stats
    PREVIOUS_STATS="$CURRENT_STATS"

    # Sleep for 1 hour (unless we're at the end)
    remaining=$((END_TIME - $(date +%s)))
    if [ $remaining -gt 0 ]; then
        if [ $remaining -lt $INTERVAL ]; then
            echo "  Sleeping for final $(($remaining / 60)) minutes..."
            sleep $remaining
        else
            echo "  Next check in 1 hour..."
            sleep $INTERVAL
        fi
    fi
done

echo ""
echo -e "${GREEN}✅ 24-hour monitoring complete!${NC}"
echo ""

# Generate final summary
generate_final_summary

echo ""
echo "To view results:"
echo "  Summary:        cat $SUMMARY_FILE"
echo "  Full CSV Log:   cat $LOG_FILE"
echo "  Hourly Reports: ls $HOURLY_DIR/"
echo ""
