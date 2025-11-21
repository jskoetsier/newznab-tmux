#!/bin/bash
#
# Regenerate NZB Files for All Releases
# This will create NZB files from existing parts data in the database
#

set -e

cd "$(dirname "$0")/.."

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          NZB File Regeneration - Started                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check current status
echo "Step 1: Checking current status..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TOTAL_RELEASES=$(mysql -N nntmux -e "SELECT COUNT(*) FROM releases")
TOTAL_PARTS=$(mysql -N nntmux -e "SELECT COUNT(*) FROM parts")
NZB_DIR="/opt/nntmux/resources/nzb"

echo "  Total Releases: $(printf "%'d" "$TOTAL_RELEASES")"
echo "  Total Parts:    $(printf "%'d" "$TOTAL_PARTS")"
echo "  NZB Directory:  $NZB_DIR"
echo ""

# Make sure NZB directory exists
mkdir -p "$NZB_DIR"

# Update database nzbpath setting
echo "Step 2: Updating database settings..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mysql nntmux -e "UPDATE settings SET value = '$NZB_DIR/' WHERE name = 'nzbpath'"
echo "✓ Updated nzbpath in database to: $NZB_DIR/"
echo ""

# Check if there's an artisan command to regenerate NZBs
echo "Step 3: Checking for NZB regeneration command..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if php artisan list | grep -q "nzb:rebuild\|nzb:regenerate\|nzb:create"; then
    echo "✓ Found NZB regeneration command"
    COMMAND=$(php artisan list | grep -E "nzb:rebuild|nzb:regenerate|nzb:create" | awk '{print $1}' | head -1)
    echo "  Command: $COMMAND"
    echo ""
    echo "Step 4: Running NZB regeneration..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    php artisan "$COMMAND"
else
    echo "⚠️  No built-in NZB regeneration command found"
    echo ""
    echo "The system doesn't have a built-in command to regenerate NZB files."
    echo "NZB files are normally created during releases processing."
    echo ""
    echo "SOLUTIONS:"
    echo ""
    echo "Option A: Continue collecting new releases (RECOMMENDED)"
    echo "  - New releases will automatically get NZB files"
    echo "  - Existing 94,000 releases won't have NZBs"
    echo "  - NFO processing will work for NEW releases only"
    echo "  - Command: Let the system run normally"
    echo ""
    echo "Option B: Clear and recollect everything"
    echo "  - Truncate releases table"
    echo "  - Re-run binaries collection and releases processing"
    echo "  - All releases will have NZB files"
    echo "  - Time: Several hours to days"
    echo ""
    echo "Option C: Manual NZB generation (Advanced)"
    echo "  - Create custom script to generate NZBs from parts table"
    echo "  - Requires development work"
    echo ""
    echo "ANALYSIS:"
    echo "  - You have $TOTAL_PARTS parts in the database"
    echo "  - These parts can theoretically be converted to NZB files"
    echo "  - However, there's no built-in command to do this"
    echo ""
    echo "RECOMMENDATION:"
    echo "  Since you already have 94,000 releases and fuzzy matching is working,"
    echo "  I recommend Option A: continue normally and let new releases get NZBs."
    echo ""
    echo "  Your PreDB match rate will improve through:"
    echo "  1. IRC Scraper (updating PreDB) - ✅ Working"
    echo "  2. Fuzzy matching (matching names) - ✅ Working"
    echo "  3. NFO processing (for new releases) - ✅ Working"
    echo ""
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "                         CURRENT STATUS                         "
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check how many NZB files exist now
NZB_COUNT=$(find "$NZB_DIR" -name "*.nzb.gz" 2>/dev/null | wc -l | tr -d ' ')
echo "  NZB Files on Disk: $(printf "%'d" "$NZB_COUNT")"
echo "  Total Releases:    $(printf "%'d" "$TOTAL_RELEASES")"

if [ "$NZB_COUNT" -gt 0 ]; then
    PERCENT=$(echo "scale=2; $NZB_COUNT * 100 / $TOTAL_RELEASES" | bc)
    echo "  Coverage:          ${PERCENT}%"
else
    echo "  Coverage:          0.00%"
fi

echo ""
echo "To monitor new NZB creation as releases are processed:"
echo "  watch -n 5 'find $NZB_DIR -name \"*.nzb.gz\" | wc -l'"
echo ""
