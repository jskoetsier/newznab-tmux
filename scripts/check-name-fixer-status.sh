#!/bin/bash
# Monitor Release Name Fixer Progress

NNTMUX_PATH="/opt/nntmux"

echo "========================================="
echo "Release Name Fixer - Status Check"
echo "========================================="
echo ""

# Check if process is running
if pgrep -f "fix-release-names.sh" > /dev/null; then
    echo "✓ Process Status: RUNNING"
    echo "  PIDs: $(pgrep -f 'fix-release-names.sh' | tr '\n' ' ')"
else
    echo "✗ Process Status: NOT RUNNING"
fi

echo ""
echo "========================================="
echo "Database Statistics"
echo "========================================="

cd "$NNTMUX_PATH" || exit 1

php artisan tinker --execute='
$total = \App\Models\Release::count();
$renamed = \App\Models\Release::where("isrenamed", 1)->count();
$matched = \App\Models\Release::where("predb_id", ">", 0)->count();
$withNfo = \DB::table("release_nfos")->count();

echo "Total Releases:     " . number_format($total) . PHP_EOL;
echo "Renamed Releases:   " . number_format($renamed) . " (" . round($renamed/$total*100, 2) . "%)" . PHP_EOL;
echo "Matched to PreDB:   " . number_format($matched) . " (" . round($matched/$total*100, 2) . "%)" . PHP_EOL;
echo "Releases with NFO:  " . number_format($withNfo) . PHP_EOL;
echo "" . PHP_EOL;
echo "PreDB Records:      " . number_format(\App\Models\Predb::count()) . PHP_EOL;
' 2>/dev/null

echo ""
echo "========================================="
echo "Recent Log Entries"
echo "========================================="
tail -15 /var/log/nntmux-name-fixer.log 2>/dev/null || echo "Log file not found"

echo ""
echo "========================================="
echo "To monitor live: tail -f /var/log/nntmux-name-fixer.log"
echo "========================================="
