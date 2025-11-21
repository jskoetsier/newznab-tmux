#!/bin/bash
#
# Check 24-Hour Monitoring Progress
# Shows current progress and latest hourly report
#

LOG_DIR="/tmp/predb_24h_monitoring"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        24-Hour Monitoring - Progress Check                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Find the latest monitoring session
if [ ! -d "$LOG_DIR" ]; then
    echo "❌ No monitoring session found"
    echo "   Start monitoring with: ./scripts/monitor-24h.sh"
    exit 1
fi

LATEST_LOG=$(ls -t ${LOG_DIR}/monitoring_*.csv 2>/dev/null | head -1)
LATEST_SESSION=$(ls -t ${LOG_DIR}/summary_*.txt 2>/dev/null | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo "❌ No active monitoring session found"
    exit 1
fi

SESSION_ID=$(basename "$LATEST_LOG" .csv | sed 's/monitoring_//')

echo "📊 Session ID: $SESSION_ID"
echo ""

# Check if monitoring is still running
if pgrep -f "monitor-24h.sh" > /dev/null; then
    echo "✅ Monitoring is ACTIVE"
else
    echo "⚠️  Monitoring process not detected"
    if [ -f "$LATEST_SESSION" ]; then
        echo "   (Session completed - summary available)"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                    CURRENT PROGRESS                             "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Read first and last line from CSV (skip header)
FIRST_LINE=$(sed -n '2p' "$LATEST_LOG")
LAST_LINE=$(tail -1 "$LATEST_LOG")

if [ "$FIRST_LINE" = "$LAST_LINE" ]; then
    echo "⏳ Just started - waiting for first hourly check..."
    IFS=',' read -r timestamp hour elapsed total matched unmatched rate nfo files delta delta_rate <<< "$FIRST_LINE"
    echo ""
    echo "Baseline (Hour 0):"
    echo "  Total Releases:  $(printf "%'d" "$total")"
    echo "  Matched (PreDB): $(printf "%'d" "$matched") (${rate}%)"
    echo "  Unmatched:       $(printf "%'d" "$unmatched")"
else
    IFS=',' read -r start_time start_hour start_elapsed start_total start_matched start_unmatched start_rate start_nfo start_files start_delta start_delta_rate <<< "$FIRST_LINE"
    IFS=',' read -r curr_time curr_hour curr_elapsed curr_total curr_matched curr_unmatched curr_rate curr_nfo curr_files curr_delta curr_delta_rate <<< "$LAST_LINE"

    total_new=$((curr_matched - start_matched))
    total_rate_change=$(echo "scale=2; $curr_rate - $start_rate" | bc)
    hours_elapsed=$((curr_elapsed / 3600))
    avg_per_hour=$(echo "scale=2; $total_new / $hours_elapsed" | bc)

    echo "📅 Started:  $start_time"
    echo "⏰ Latest:   $curr_time"
    echo "⌛ Elapsed:  ${hours_elapsed} hours (of 24)"
    echo ""
    echo "                    BASELINE      CURRENT        CHANGE"
    echo "Total Releases:     $(printf '%10s' "$(printf "%'d" "$start_total")")  $(printf '%10s' "$(printf "%'d" "$curr_total")")  +$(printf "%'d" $((curr_total - start_total)))"
    echo "Matched (PreDB):    $(printf '%10s' "$(printf "%'d" "$start_matched")")  $(printf '%10s' "$(printf "%'d" "$curr_matched")")  +$(printf "%'d" "$total_new")"
    echo "Match Rate:         $(printf '%9s' "${start_rate}%")  $(printf '%9s' "${curr_rate}%")  +${total_rate_change}%"
    echo ""
    echo "Performance:"
    echo "  Total New Matches:    $(printf "%'d" "$total_new")"
    echo "  Average/Hour:         ${avg_per_hour}"
    echo "  Last Hour Delta:      +$(printf "%'d" "$curr_delta")"
    echo ""

    # Progress bar
    progress=$((curr_hour * 100 / 24))
    filled=$((progress / 5))
    empty=$((20 - filled))
    printf "Progress: ["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%% (Hour %d/24)\n" "$progress" "$curr_hour"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                    LATEST HOURLY REPORT                         "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

LATEST_HOURLY=$(ls -t ${LOG_DIR}/hourly/hour_*.txt 2>/dev/null | head -1)
if [ -n "$LATEST_HOURLY" ]; then
    cat "$LATEST_HOURLY"
else
    echo "No hourly reports yet - waiting for first hour..."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show files
echo "📁 Files:"
echo "  Log:             $LATEST_LOG"
echo "  Hourly Reports:  ${LOG_DIR}/hourly/"
if [ -f "$LATEST_SESSION" ]; then
    echo "  Final Summary:   $LATEST_SESSION"
fi

echo ""
echo "Commands:"
echo "  View CSV:        cat $LATEST_LOG"
echo "  View Summary:    cat $LATEST_SESSION"
echo "  List Reports:    ls ${LOG_DIR}/hourly/"
echo "  Check Progress:  ./scripts/check-24h-progress.sh"
echo ""
