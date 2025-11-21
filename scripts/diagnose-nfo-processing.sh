#!/bin/bash
#
# Diagnose NFO Processing Issues
# Checks why NFO processing isn't finding any NFO files
#

set -e

cd "$(dirname "$0")/.."

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          NFO Processing Diagnostic Report                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

echo "Step 1: Database NFO Statistics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mysql -N nntmux -e "
SELECT
    '  Total Releases:' as metric,
    FORMAT(COUNT(*), 0) as value
FROM releases
UNION ALL
SELECT
    '  NFOs Found (nfostatus=1):',
    FORMAT(SUM(CASE WHEN nfostatus = 1 THEN 1 ELSE 0 END), 0)
FROM releases
UNION ALL
SELECT
    '  No NFO (nfostatus=0):',
    FORMAT(SUM(CASE WHEN nfostatus = 0 THEN 1 ELSE 0 END), 0)
FROM releases
UNION ALL
SELECT
    '  Unprocessed (nfostatus=-1):',
    FORMAT(SUM(CASE WHEN nfostatus = -1 THEN 1 ELSE 0 END), 0)
FROM releases
UNION ALL
SELECT
    '  Failed (nfostatus < -1):',
    FORMAT(SUM(CASE WHEN nfostatus < -1 THEN 1 ELSE 0 END), 0)
FROM releases
"
echo ""

echo "Step 2: NZB File Storage Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check database nzbpath setting
DB_NZBPATH=$(mysql -N nntmux -e "SELECT value FROM settings WHERE name = 'nzbpath'")
echo "  Database nzbpath:  $DB_NZBPATH"

# Check .env PATH_TO_NZBS setting
if [ -f .env ]; then
    ENV_NZBPATH=$(grep "^PATH_TO_NZBS=" .env | cut -d= -f2)
    echo "  .env PATH_TO_NZBS: $ENV_NZBPATH"
fi

# Check if NZB files exist
NZB_COUNT=$(find /opt/nntmux/resources/nzb/ -name "*.nzb.gz" 2>/dev/null | wc -l)
echo "  NZB files on disk: $NZB_COUNT"

if [ "$NZB_COUNT" -eq 0 ]; then
    echo ""
    echo "  ⚠️  CRITICAL: No NZB files found on disk!"
    echo "     NFO processing REQUIRES NZB files to:"
    echo "     1. Parse the NZB XML to find NFO article message IDs"
    echo "     2. Download those specific articles from usenet"
    echo "     3. Verify and save the NFO content"
fi

echo ""

echo "Step 3: NZB Storage Setting"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
STORE_NZB=$(mysql -N nntmux -e "SELECT value FROM settings WHERE name = 'storenzbpath'" 2>/dev/null || echo "NULL")
if [ "$STORE_NZB" = "NULL" ] || [ -z "$STORE_NZB" ]; then
    echo "  ⚠️  storenzbpath setting not found in database"
    echo "     This might be why NZBs weren't stored during collection"
else
    echo "  storenzbpath: $STORE_NZB"
fi

# Check if write enabled
WRITE_NZB=$(mysql -N nntmux -e "SELECT value FROM settings WHERE name = 'writenzbs'" 2>/dev/null || echo "NULL")
if [ "$WRITE_NZB" = "NULL" ] || [ -z "$WRITE_NZB" ]; then
    echo "  ⚠️  writenzbs setting not found - might be a config issue"
else
    echo "  writenzbs: $WRITE_NZB"
fi

echo ""

echo "Step 4: Recent NFO Processing Attempts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Testing NFO processing for 10 seconds..."
RESULT=$(cd /opt/nntmux && timeout 10 php artisan update:postprocess nfo true 2>&1 | head -20)
echo "$RESULT"
echo ""

# Count the result indicators
PLUS_COUNT=$(echo "$RESULT" | grep -o '+' | wc -l)
DASH_COUNT=$(echo "$RESULT" | grep -o '\-' | wc -l | tr -d ' ')
STAR_COUNT=$(echo "$RESULT" | grep -o '*' | wc -l)
F_COUNT=$(echo "$RESULT" | grep -o 'f' | wc -l)

echo "  Results:"
echo "    + (NFO found):           $PLUS_COUNT"
echo "    * (hidden NFO found):    $STAR_COUNT"
echo "    - (no NFO):              $DASH_COUNT"
echo "    f (download failed):     $F_COUNT"

echo ""

echo "Step 5: NNTP Connection Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
NNTP_SERVER=$(grep "^NNTP_SERVER=" .env 2>/dev/null | cut -d= -f2 || echo "Not found")
NNTP_PORT=$(grep "^NNTP_PORT=" .env 2>/dev/null | cut -d= -f2 || echo "Not found")
echo "  NNTP Server: $NNTP_SERVER"
echo "  NNTP Port:   $NNTP_PORT"
echo ""

echo "Step 6: Sample Release Analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mysql nntmux -e "
SELECT
    id,
    LEFT(name, 60) as name,
    nfostatus,
    CASE
        WHEN nfostatus = 1 THEN 'NFO Found'
        WHEN nfostatus = 0 THEN 'No NFO'
        WHEN nfostatus = -1 THEN 'Unprocessed'
        ELSE CONCAT('Failed (', nfostatus, ')')
    END as status
FROM releases
WHERE nfostatus >= -1
ORDER BY adddate DESC
LIMIT 5
" | head -10

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                         SUMMARY                                "
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ "$NZB_COUNT" -eq 0 ]; then
    echo "🔴 CRITICAL ISSUE FOUND:"
    echo ""
    echo "   No NZB files are stored on disk!"
    echo ""
    echo "   NFO processing CANNOT work without NZB files because:"
    echo "   1. NFO article message IDs are stored inside NZB files"
    echo "   2. The system needs to parse NZBs to find these IDs"
    echo "   3. Then it downloads those specific articles from usenet"
    echo ""
    echo "   SOLUTIONS:"
    echo ""
    echo "   Option A: Backfill NZBs (RECOMMENDED)"
    echo "     The system must re-download all releases to generate NZB files"
    echo "     Command: php artisan backfill:all"
    echo "     Time: Several hours to days depending on release count"
    echo ""
    echo "   Option B: Fresh Start"
    echo "     Clear releases and re-collect with NZB storage enabled"
    echo "     Faster but loses existing release data"
    echo ""
    echo "   Root Cause: NZB storage was not enabled during initial collection"
    echo ""
else
    echo "✅ NZB files found: $NZB_COUNT"
    if [ "$PLUS_COUNT" -gt 0 ] || [ "$STAR_COUNT" -gt 0 ]; then
        echo "✅ NFO processing is working!"
        echo "   Found $((PLUS_COUNT + STAR_COUNT)) NFO(s) in test run"
    else
        echo "⚠️  NFO processing runs but finds no NFOs"
        echo "   This might be normal if releases don't contain NFO files"
    fi
fi

echo ""
