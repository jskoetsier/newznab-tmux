#!/bin/bash
# NNTmux PreDB Daily Update Script
# Fetches PreDB data from srrDB and imports it

set -e

# Configuration
NNTMUX_PATH="/opt/nntmux"
TEMP_DIR="/tmp"
LOG_FILE="/var/log/nntmux-predb-update.log"
PREDB_FILE="$TEMP_DIR/predb_dump_$(date +%Y%m%d_%H%M%S).csv"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting PreDB update..."

# Create PHP script to fetch from srrDB
cat > "$TEMP_DIR/fetch_predb_srrdb.php" << 'EOFPHP'
<?php
// Fetch PreDB data from srrDB API

$outputFile = $argv[1] ?? "/tmp/predb_dump.csv";
$categories = ["tv", "movies", "music", "games", "apps", "xxx"];
$recordsPerCategory = 500; // Fetch up to 500 per category

$fp = fopen($outputFile, "w");
fputcsv($fp, ["title", "nfo", "size", "category", "predate", "source", "requestid", "groups_id", "nuked", "nukereason", "files", "filename"]);

$totalRecords = 0;
echo "Fetching PreDB data from srrDB...\n";

foreach ($categories as $category) {
    echo "Fetching category: $category... ";

    $offset = 0;
    $count = 0;

    while ($count < $recordsPerCategory) {
        $url = "https://api.srrdb.com/v1/search/category:$category/p:" . floor($offset / 25);
        $response = @file_get_contents($url, false, stream_context_create([
            'http' => [
                'timeout' => 10,
                'user_agent' => 'NNTmux PreDB Importer'
            ]
        ]));

        if ($response === false) {
            break;
        }

        $data = json_decode($response, true);

        if (!isset($data["results"]) || empty($data["results"])) {
            break;
        }

        foreach ($data["results"] as $release) {
            $title = $release["release"] ?? "";
            if (empty($title)) continue;

            $predate = isset($release["archived-datetime"]) ?
                date("Y-m-d H:i:s", strtotime($release["archived-datetime"])) :
                date("Y-m-d H:i:s");

            fputcsv($fp, [
                $title,
                null,
                $release["size"] ?? null,
                strtoupper($category),
                $predate,
                "srrdb",
                0,
                0,
                isset($release["nuked"]) && $release["nuked"] ? 2 : 0,
                $release["nuke-reason"] ?? null,
                $release["files"] ?? null,
                $title
            ]);

            $count++;
            $totalRecords++;

            if ($count >= $recordsPerCategory) break;
        }

        $offset += count($data["results"]);

        if (count($data["results"]) < 25) break;

        usleep(500000); // 0.5 second delay between requests
    }

    echo "$count records\n";
    sleep(1);
}

fclose($fp);
echo "Total records fetched: $totalRecords\n";
echo "Output file: $outputFile\n";
EOFPHP

# Run the PHP script to fetch data
log "Fetching PreDB data from srrDB..."
if php "$TEMP_DIR/fetch_predb_srrdb.php" "$PREDB_FILE" >> "$LOG_FILE" 2>&1; then
    log "Successfully fetched PreDB data"
else
    log "ERROR: Failed to fetch PreDB data"
    exit 1
fi

# Check if file exists and has data
if [ ! -f "$PREDB_FILE" ]; then
    log "ERROR: PreDB file not created"
    exit 1
fi

RECORD_COUNT=$(wc -l < "$PREDB_FILE")
log "PreDB file contains $RECORD_COUNT lines"

if [ "$RECORD_COUNT" -lt 2 ]; then
    log "ERROR: PreDB file is empty or only has header"
    exit 1
fi

# Import PreDB data
log "Importing PreDB data into database..."
cd "$NNTMUX_PATH" || exit 1

if php artisan predb:import "$PREDB_FILE" \
    --skip-header \
    --truncate-staging \
    --no-interaction >> "$LOG_FILE" 2>&1; then
    log "Successfully imported PreDB data"
else
    log "ERROR: Failed to import PreDB data"
    exit 1
fi

# Match releases against PreDB
log "Matching releases against PreDB..."
if php artisan predb:check 100000 >> "$LOG_FILE" 2>&1; then
    log "Successfully matched releases"
else
    log "WARNING: PreDB check had issues (may be expected if no matches)"
fi

# Cleanup old temp files (keep last 7 days)
find "$TEMP_DIR" -name "predb_dump_*.csv" -mtime +7 -delete 2>/dev/null || true

# Cleanup old logs (keep last 30 days)
if [ -f "$LOG_FILE" ]; then
    # Keep only last 10000 lines to prevent log from growing too large
    tail -n 10000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

log "PreDB update complete!"

# Display summary
TOTAL_PREDB=$(cd "$NNTMUX_PATH" && php artisan tinker --execute='echo \App\Models\Predb::count();' 2>/dev/null || echo "unknown")
MATCHED_RELEASES=$(cd "$NNTMUX_PATH" && php artisan tinker --execute='echo \App\Models\Release::where("predb_id", ">", 0)->count();' 2>/dev/null || echo "unknown")

log "Summary: PreDB records: $TOTAL_PREDB, Matched releases: $MATCHED_RELEASES"
