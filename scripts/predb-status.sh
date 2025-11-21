#!/bin/bash
#
# Quick PreDB Match Rate Status
# Shows current stats and recent improvements
#

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          NNTmux PreDB Match Rate - Current Status              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Time:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Query current stats
read -r total matched unmatched match_rate <<< $(mysql -N -B nntmux -e "
SELECT
    COUNT(*) as total,
    SUM(CASE WHEN predb_id > 0 THEN 1 ELSE 0 END) as matched,
    SUM(CASE WHEN predb_id = 0 THEN 1 ELSE 0 END) as unmatched,
    ROUND(SUM(CASE WHEN predb_id > 0 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) as match_rate
FROM releases;
")

# Format numbers with commas
total_fmt=$(printf "%'d" "$total")
matched_fmt=$(printf "%'d" "$matched")
unmatched_fmt=$(printf "%'d" "$unmatched")

echo -e "${CYAN}Current Statistics:${NC}"
echo -e "  Total Releases:     $total_fmt"
echo -e "  ${GREEN}✓ Matched (PreDB):${NC}  $matched_fmt (${match_rate}%)"
echo -e "  ${YELLOW}✗ Unmatched:${NC}        $unmatched_fmt"
echo ""

# Check processing queue
read -r nfo_pending files_pending <<< $(mysql -N -B nntmux -e "
SELECT
    SUM(CASE WHEN proc_nfo = 0 THEN 1 ELSE 0 END) as nfo_pending,
    SUM(CASE WHEN proc_files = 0 THEN 1 ELSE 0 END) as files_pending
FROM releases;
")

nfo_fmt=$(printf "%'d" "$nfo_pending")
files_fmt=$(printf "%'d" "$files_pending")

echo -e "${CYAN}Processing Queue:${NC}"
echo -e "  NFO pending:        $nfo_fmt"
echo -e "  Files pending:      $files_fmt"
echo ""

# Check if postprocessing is running
if ps aux | grep -E 'releases:fix-names|update:postprocess' | grep -v grep > /dev/null; then
    echo -e "${GREEN}✓ Postprocessing is ACTIVE${NC}"
    echo ""
    echo -e "${CYAN}Active Processes:${NC}"
    ps aux | grep -E 'releases:fix-names|update:postprocess' | grep -v grep | awk '{print "  •", $11, $12, $13, $14, $15}'
else
    echo -e "${YELLOW}⚠ No postprocessing detected${NC}"
    echo ""
    echo -e "Start postprocessing with:"
    echo -e "  ${CYAN}php artisan update:postprocess nfo${NC}"
fi

echo ""

# Check monitoring log if exists
if ls /tmp/predb_monitoring_*.log 1> /dev/null 2>&1; then
    latest_log=$(ls -t /tmp/predb_monitoring_*.log | head -1)
    echo -e "${CYAN}Recent History (from monitoring log):${NC}"
    tail -5 "$latest_log" | awk -F',' 'NR>1 {
        printf "  %s  Matched: %s (%.2f%%)  Queue: NFO=%s Files=%s\n",
        $1, $4, $8, $6, $7
    }'
    echo ""
fi

echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
