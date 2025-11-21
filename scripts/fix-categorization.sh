#!/bin/bash
#
# Fix Release Categorization
# Re-categorizes miscategorized releases using postprocessing and lookups
#

set -e

cd "$(dirname "$0")/.."

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          Release Categorization Fixer                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Check current categorization
echo "Step 1: Analyzing current categorization..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mysql nntmux -e "
SELECT
    c.title as category,
    COUNT(r.id) as releases,
    ROUND(COUNT(r.id) * 100.0 / (SELECT COUNT(*) FROM releases), 2) as percentage
FROM categories c
LEFT JOIN releases r ON c.id = r.categories_id
GROUP BY c.id, c.title
HAVING releases > 0
ORDER BY releases DESC
LIMIT 15;
"

echo ""

MISC_COUNT=$(mysql -N nntmux -e "SELECT COUNT(*) FROM releases WHERE categories_id = 10")
HASHED_COUNT=$(mysql -N nntmux -e "SELECT COUNT(*) FROM releases WHERE categories_id = 20")
TOTAL=$(mysql -N nntmux -e "SELECT COUNT(*) FROM releases")

echo "  Misc category:     $MISC_COUNT releases"
echo "  Hashed category:   $HASHED_COUNT releases"
echo "  Total releases:    $TOTAL"
echo "  Problem releases:  $((MISC_COUNT + HASHED_COUNT)) ($((($MISC_COUNT + $HASHED_COUNT) * 100 / $TOTAL))%)"
echo ""

# Step 2: Enable recategorization settings
echo "Step 2: Enabling recategorization settings..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mysql nntmux <<SQL
-- Enable all lookup types
UPDATE settings SET value = '1' WHERE name = 'lookuptv';
UPDATE settings SET value = '1' WHERE name = 'lookupimdb';
UPDATE settings SET value = '1' WHERE name = 'lookupmusic';
UPDATE settings SET value = '1' WHERE name = 'lookupgames';
UPDATE settings SET value = '1' WHERE name = 'lookupbooks';
UPDATE settings SET value = '1' WHERE name = 'lookuppar2';
UPDATE settings SET value = '1' WHERE name = 'lookupnfo';

-- Enable WebDL categorization
UPDATE settings SET value = '1' WHERE name = 'catwebdl';

-- Enable foreign categorization
UPDATE settings SET value = '1' WHERE name = 'categorize_foreign';

-- Increase processing limits
UPDATE settings SET value = '500' WHERE name = 'maxnfoprocessed';
UPDATE settings SET value = '2000' WHERE name = 'maxaddprocessed';

SELECT
    name,
    value,
    CASE WHEN value = '1' THEN '✓' ELSE '✗' END as status
FROM settings
WHERE name IN ('lookuptv', 'lookupimdb', 'lookupmusic', 'lookupgames',
               'lookupbooks', 'lookuppar2', 'lookupnfo', 'catwebdl', 'categorize_foreign')
ORDER BY name;
SQL

echo ""

# Step 3: Reset processing status for miscategorized releases
echo "Step 3: Resetting processing status for miscategorized releases..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mysql nntmux <<SQL
-- Reset Misc and Hashed releases to be reprocessed
UPDATE releases
SET nfostatus = -1,
    proc_files = 0,
    proc_par2 = 0,
    adddate = NOW()
WHERE categories_id IN (10, 20);  -- Misc and Hashed

SELECT CONCAT('✓ Reset ', ROW_COUNT(), ' releases for reprocessing') as result;
SQL

echo ""

# Step 4: Run postprocessing to recategorize
echo "Step 4: Running postprocessing to recategorize releases..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  This will process NFO, files, and apply lookups to fix categories"
echo ""

# Run NFO processing (downloads NFO files and categorizes)
echo "  → Processing NFOs (downloads from usenet)..."
timeout 300 php artisan update:postprocess nfo true || echo "  (NFO processing timeout after 5 minutes)"
echo ""

# Run additional postprocessing (movies, TV, music, etc.)
echo "  → Running additional postprocessing..."
timeout 300 php artisan update:postprocess additional true || echo "  (Additional processing timeout after 5 minutes)"
echo ""

# Step 5: Check improved categorization
echo "Step 5: Checking improved categorization..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mysql nntmux -e "
SELECT
    c.title as category,
    COUNT(r.id) as releases,
    ROUND(COUNT(r.id) * 100.0 / (SELECT COUNT(*) FROM releases), 2) as percentage
FROM categories c
LEFT JOIN releases r ON c.id = r.categories_id
GROUP BY c.id, c.title
HAVING releases > 0
ORDER BY releases DESC
LIMIT 15;
"

echo ""

MISC_COUNT_AFTER=$(mysql -N nntmux -e "SELECT COUNT(*) FROM releases WHERE categories_id = 10")
HASHED_COUNT_AFTER=$(mysql -N nntmux -e "SELECT COUNT(*) FROM releases WHERE categories_id = 20")

MISC_FIXED=$((MISC_COUNT - MISC_COUNT_AFTER))
HASHED_FIXED=$((HASHED_COUNT - HASHED_COUNT_AFTER))
TOTAL_FIXED=$((MISC_FIXED + HASHED_FIXED))

echo "Results:"
echo "  Misc:    $MISC_COUNT → $MISC_COUNT_AFTER (fixed $MISC_FIXED)"
echo "  Hashed:  $HASHED_COUNT → $HASHED_COUNT_AFTER (fixed $HASHED_FIXED)"
echo "  Total:   Fixed $TOTAL_FIXED releases"
echo ""

# Step 6: Check specific category breakdowns
echo "Step 6: Category breakdown by type..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mysql nntmux -e "
SELECT
    'TV Shows' as type,
    COUNT(*) as count
FROM releases
WHERE categories_id BETWEEN 5000 AND 5999
UNION ALL
SELECT
    'Movies' as type,
    COUNT(*)
FROM releases
WHERE categories_id BETWEEN 2000 AND 2999
UNION ALL
SELECT
    'Music' as type,
    COUNT(*)
FROM releases
WHERE categories_id BETWEEN 3000 AND 3999
UNION ALL
SELECT
    'PC/Games' as type,
    COUNT(*)
FROM releases
WHERE categories_id BETWEEN 4000 AND 4999
UNION ALL
SELECT
    'Books' as type,
    COUNT(*)
FROM releases
WHERE categories_id BETWEEN 7000 AND 7999;
"

echo ""

# Step 7: Recommendations
echo "════════════════════════════════════════════════════════════════"
echo "                    CATEGORIZATION STATUS                       "
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$TOTAL_FIXED" -gt 0 ]; then
    echo "✅ Successfully recategorized $TOTAL_FIXED releases!"
else
    echo "⚠️  No releases recategorized yet"
    echo ""
    echo "REASONS & SOLUTIONS:"
    echo ""
    echo "1. NFO files not downloaded yet"
    echo "   → NFO processing runs automatically in tmux"
    echo "   → Downloads NFO files from usenet for categorization"
    echo "   → Check: find /opt/nntmux/resources/nzb -name '*.nzb.gz' | wc -l"
    echo ""
    echo "2. Release names are too generic (yEnc patterns)"
    echo "   → Run: php artisan releases:fix-names --limit=5000"
    echo "   → This extracts better names from NFO/files"
    echo ""
    echo "3. No metadata from external APIs yet"
    echo "   → IMDB/TVDB/etc lookups need valid release names"
    echo "   → Fix names first, then recategorization will work"
    echo ""
    echo "4. PreDB not populated enough"
    echo "   → IRC scraper is updating PreDB"
    echo "   → Current PreDB: $(mysql -N nntmux -e 'SELECT COUNT(*) FROM predb') entries"
    echo "   → Needs 10,000+ for good matching"
fi

echo ""
echo "AUTOMATIC FIX:"
echo "  Postprocessing runs automatically in tmux every few minutes"
echo "  As NFO files are downloaded, categorization will improve"
echo ""
echo "MANUAL RECATEGORIZATION (run again in 1-2 hours):"
echo "  ./scripts/fix-categorization.sh"
echo ""
echo "MONITOR PROGRESS:"
echo "  watch -n 30 'mysql -N nntmux -e \"SELECT COUNT(*) FROM releases WHERE categories_id = 10\"'"
echo ""
