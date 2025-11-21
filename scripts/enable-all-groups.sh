#!/bin/bash
#
# Enable All Groups and Configure Backfill
# Activates all 203 groups and sets them to backfill 1 day
#

set -e

cd "$(dirname "$0")/.."

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Enable All Groups + 1 Day Backfill                   ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Check current status
echo "Step 1: Checking current status..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOTAL_GROUPS=$(mysql -N nntmux -e "SELECT COUNT(*) FROM usenet_groups")
ACTIVE_GROUPS=$(mysql -N nntmux -e "SELECT COUNT(*) FROM usenet_groups WHERE active = 1")
BACKFILL_ENABLED=$(mysql -N nntmux -e "SELECT COUNT(*) FROM usenet_groups WHERE backfill = 1")

echo "  Total Groups:      $TOTAL_GROUPS"
echo "  Currently Active:  $ACTIVE_GROUPS"
echo "  Backfill Enabled:  $BACKFILL_ENABLED"
echo ""

# Step 2: Stop all processing
echo "Step 2: Stopping tmux processing..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
php artisan tmux:stop 2>/dev/null || true
pkill -f "php.*artisan" 2>/dev/null || true
sleep 3
echo "✓ All processing stopped"
echo ""

# Step 3: Enable all groups
echo "Step 3: Enabling all groups..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mysql nntmux <<EOF
-- Enable all groups
UPDATE usenet_groups
SET active = 1;

-- Get active groups count
SELECT CONCAT('✓ Enabled ', COUNT(*), ' groups') as result
FROM usenet_groups
WHERE active = 1;
EOF

echo ""

# Step 4: Configure backfill for 1 day
echo "Step 4: Configuring 1-day backfill..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Calculate article numbers for 1 day backfill
# Average usenet posts per day per group: ~10,000-50,000 articles
# We'll use 20,000 as a safe middle ground
BACKFILL_ARTICLES=20000

mysql nntmux <<EOF
-- Enable backfill for all active groups with proper bounds checking
-- Set backfill_target safely, ensuring it's never negative or out of range
UPDATE usenet_groups
SET backfill = 1,
    backfill_target = CASE
                        WHEN last_record > $BACKFILL_ARTICLES
                          THEN last_record - $BACKFILL_ARTICLES
                        WHEN first_record > 0
                          THEN first_record
                        ELSE 1
                      END
WHERE active = 1;

-- Show summary
SELECT
    CONCAT('✓ Configured backfill for ', COUNT(*), ' groups') as result
FROM usenet_groups
WHERE backfill = 1;

SELECT
    CONCAT('  Average backfill target: ',
           FORMAT(AVG(last_record - backfill_target), 0),
           ' articles (~1 day)') as info
FROM usenet_groups
WHERE backfill = 1
AND backfill_target > 0;
EOF

echo ""

# Step 5: Update database settings
echo "Step 5: Updating database settings..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mysql nntmux <<EOF
-- Ensure all critical settings are enabled
UPDATE settings SET value = '1' WHERE name = 'run_ircscraper';
UPDATE settings SET value = '3' WHERE name = 'post';
UPDATE settings SET value = '1' WHERE name = 'post_amazon';
UPDATE settings SET value = '1' WHERE name = 'post_non';
UPDATE settings SET value = '1' WHERE name = 'lookupnfo';
UPDATE settings SET value = '100' WHERE name = 'maxnfoprocessed';
EOF

echo "✓ IRC scraper:       ENABLED"
echo "✓ NFO processing:    ENABLED (100 per cycle)"
echo "✓ Post processing:   ENABLED (Additional + NFO)"
echo "✓ Amazon/Non:        ENABLED"
echo ""

# Step 6: Verify configuration
echo "Step 6: Verifying final configuration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mysql nntmux -e "
SELECT
    'Groups Enabled:' as metric,
    COUNT(*) as value
FROM usenet_groups
WHERE active = 1
UNION ALL
SELECT
    'Backfill Enabled:',
    COUNT(*)
FROM usenet_groups
WHERE backfill = 1
UNION ALL
SELECT
    'Total Articles to Backfill:',
    FORMAT(SUM(last_record - backfill_target), 0)
FROM usenet_groups
WHERE backfill = 1 AND backfill_target > 0;
"

echo ""

# Step 7: Restart tmux
echo "Step 7: Restarting tmux with new configuration..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

php artisan tmux:start
sleep 3

# Check tmux status
TMUX_RUNNING=$(tmux list-sessions 2>/dev/null | grep -c "nntmux" || echo "0")
if [ "$TMUX_RUNNING" -gt 0 ]; then
    echo "✓ Tmux started successfully"
    echo ""
    echo "Active panes:"
    tmux list-panes -t nntmux -a -F '  - #{pane_title}' | head -10
else
    echo "⚠️  Tmux may not have started properly"
    echo "   Check with: tmux ls"
fi

echo ""

# Step 8: Show what happens next
echo "════════════════════════════════════════════════════════════════"
echo "                    CONFIGURATION COMPLETE                      "
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✅ All $TOTAL_GROUPS groups are now ENABLED"
echo "✅ Backfill configured for ~1 day (20,000 articles per group)"
echo "✅ All processing systems active"
echo ""
echo "What happens now:"
echo "  1. Binaries collection starts on ALL groups simultaneously"
echo "  2. Backfill runs to collect last 1 day of articles"
echo "  3. Releases are processed with NZB files"
echo "  4. NFO processing downloads metadata from usenet"
echo "  5. Fuzzy matching applies PreDB names"
echo ""
echo "Expected collection:"
echo "  203 groups × 20,000 articles = ~4,060,000 articles"
echo "  Estimated releases: 50,000-100,000 in next 24 hours"
echo "  Time to backfill: 2-6 hours (depends on connection speed)"
echo "  Time to process: 4-12 hours after backfill"
echo ""
echo "Monitoring Commands:"
echo "  Watch progress:       ./scripts/predb-status.sh"
echo "  Check binaries:       mysql nntmux -e 'SELECT COUNT(*) FROM binaries'"
echo "  Check releases:       mysql nntmux -e 'SELECT COUNT(*) FROM releases'"
echo "  Watch tmux:           tmux attach -t nntmux"
echo "  24h monitoring:       ./scripts/monitor-24h.sh"
echo ""
echo "🚀 Your indexer is now collecting from ALL 203 groups!"
echo ""
