#!/bin/bash
#
# Watch NFO Processing in Real-Time
# Shows live statistics and output as NFOs are downloaded from usenet
#

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          NFO Processing - Real-Time Monitor                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Legend:"
echo "  + = NFO found and downloaded from usenet"
echo "  * = Hidden NFO found (single-segment file)"
echo "  - = No NFO in release"
echo "  f = Usenet download failed"
echo ""
echo "Press Ctrl+C to stop..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd /opt/nntmux

# Count statistics
TOTAL_PLUS=0
TOTAL_STAR=0
TOTAL_DASH=0
TOTAL_FAIL=0
START_TIME=$(date +%s)

# Run NFO processing and capture output
while true; do
    echo "[$(date '+%H:%M:%S')] Running NFO processing cycle..."

    # Capture output
    OUTPUT=$(timeout 30 php artisan update:postprocess nfo true 2>&1)

    # Count indicators in this cycle
    PLUS=$(echo "$OUTPUT" | grep -o '+' | wc -l)
    STAR=$(echo "$OUTPUT" | grep -o '\*' | wc -l)
    DASH=$(echo "$OUTPUT" | grep -o '\-' | wc -l | tr -d ' ')
    FAIL=$(echo "$OUTPUT" | grep -o 'f' | wc -l)

    # Update totals
    TOTAL_PLUS=$((TOTAL_PLUS + PLUS))
    TOTAL_STAR=$((TOTAL_STAR + STAR))
    TOTAL_DASH=$((TOTAL_DASH + DASH))
    TOTAL_FAIL=$((TOTAL_FAIL + FAIL))

    # Show output
    echo "$OUTPUT"

    # Show cycle summary
    ELAPSED=$(($(date +%s) - START_TIME))
    echo ""
    echo "Cycle Results: +${PLUS} *${STAR} -${DASH} f${FAIL}"
    echo ""
    echo "Total Since Start (${ELAPSED}s):"
    echo "  NFOs Downloaded:     +$TOTAL_PLUS (explicit) + *$TOTAL_STAR (hidden) = $((TOTAL_PLUS + TOTAL_STAR))"
    echo "  No NFO Found:        $TOTAL_DASH"
    echo "  Download Failures:   $TOTAL_FAIL"

    if [ $ELAPSED -gt 0 ]; then
        RATE=$(echo "scale=2; ($TOTAL_PLUS + $TOTAL_STAR) * 60 / $ELAPSED" | bc)
        echo "  Download Rate:       ${RATE} NFOs/minute"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check database progress
    DB_STATS=$(mysql -N nntmux -e "SELECT
        SUM(CASE WHEN nfostatus = 1 THEN 1 ELSE 0 END) as found,
        SUM(CASE WHEN nfostatus = -1 THEN 1 ELSE 0 END) as remaining
    FROM releases")

    FOUND=$(echo "$DB_STATS" | awk '{print $1}')
    REMAINING=$(echo "$DB_STATS" | awk '{print $2}')

    echo "Database Status:"
    echo "  NFOs in Database:    $FOUND"
    echo "  Remaining to Check:  $REMAINING"
    echo ""

    # Sleep 5 seconds before next cycle
    echo "Waiting 5 seconds before next cycle..."
    sleep 5
done
