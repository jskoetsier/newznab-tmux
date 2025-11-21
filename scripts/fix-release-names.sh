#!/bin/bash
# NNTmux Release Name Fixer Script
# Runs post-processing and name fixing on all releases

set -e

# Configuration
NNTMUX_PATH="/opt/nntmux"
LOG_FILE="/var/log/nntmux-name-fixer.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

cd "$NNTMUX_PATH" || exit 1

log "========================================="
log "Starting Release Name Fixing Process"
log "========================================="

# Step 1: Run post-processing to extract NFO and metadata
log "Step 1: Processing NFO files..."
php artisan update:postprocess nfo >> "$LOG_FILE" 2>&1 || log "NFO processing completed with warnings"

log "Step 2: Processing additional metadata (mediainfo, previews)..."
php artisan update:postprocess additional >> "$LOG_FILE" 2>&1 || log "Additional processing completed with warnings"

# Step 3: Run all name fixers
log "Step 3: Running name fixers..."

# Fix using NFO files (all releases)
log "  - Fixing names using NFO files..."
php artisan releases:fix-names 4 --update --set-status >> "$LOG_FILE" 2>&1 || log "    NFO fixer completed with warnings"

# Fix misc categories using file names
log "  - Fixing misc category names using file names..."
php artisan releases:fix-names 6 --update --set-status >> "$LOG_FILE" 2>&1 || log "    File name fixer completed with warnings"

# Fix using PAR2 files
log "  - Fixing names using PAR2 files..."
php artisan releases:fix-names 8 --update --set-status >> "$LOG_FILE" 2>&1 || log "    PAR2 fixer completed with warnings"

# Fix using SRR files
log "  - Fixing names using SRR files..."
php artisan releases:fix-names 14 --update --set-status >> "$LOG_FILE" 2>&1 || log "    SRR fixer completed with warnings"

# Fix using PAR2 hash
log "  - Fixing names using PAR2 hash..."
php artisan releases:fix-names 16 --update --set-status >> "$LOG_FILE" 2>&1 || log "    PAR2 hash fixer completed with warnings"

# Fix using Mediainfo
log "  - Fixing names using Mediainfo..."
php artisan releases:fix-names 18 --update --set-status >> "$LOG_FILE" 2>&1 || log "    Mediainfo fixer completed with warnings"

# Fix using CRC32
log "  - Fixing names using CRC32..."
php artisan releases:fix-names 20 --update --set-status >> "$LOG_FILE" 2>&1 || log "    CRC32 fixer completed with warnings"

# Step 4: Match releases against PreDB
log "Step 4: Matching releases against PreDB..."
php artisan predb:check >> "$LOG_FILE" 2>&1 || log "PreDB check completed with warnings"

# Step 5: Match prefiles
log "Step 5: Matching prefiles..."
php artisan match:prefiles >> "$LOG_FILE" 2>&1 || log "Prefiles matching completed with warnings"

# Generate summary
log "========================================="
log "Generating Summary..."
log "========================================="

TOTAL_RELEASES=$(php artisan tinker --execute='echo \App\Models\Release::count();' 2>/dev/null || echo "unknown")
RENAMED_RELEASES=$(php artisan tinker --execute='echo \App\Models\Release::where("isrenamed", 1)->count();' 2>/dev/null || echo "unknown")
MATCHED_RELEASES=$(php artisan tinker --execute='echo \App\Models\Release::where("predb_id", ">", 0)->count();' 2>/dev/null || echo "unknown")

log "Total releases: $TOTAL_RELEASES"
log "Renamed releases: $RENAMED_RELEASES"
log "Matched to PreDB: $MATCHED_RELEASES"
log "========================================="
log "Release Name Fixing Complete!"
log "========================================="

# Keep log file manageable
tail -n 20000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
