#!/bin/bash
# PreDB Daily Update Script
# This script should be customized to download from your PreDB source

# Configuration
NNTMUX_PATH="/opt/nntmux"
PREDB_DUMP_URL="https://your-predb-source.com/daily.csv"
TEMP_FILE="/tmp/daily_predb_$(date +%Y%m%d).csv"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting PreDB daily update...${NC}"

# Download PreDB dump
echo "Downloading PreDB dump..."
if wget -O "$TEMP_FILE" "$PREDB_DUMP_URL"; then
    echo -e "${GREEN}✓ Download successful${NC}"
else
    echo -e "${RED}✗ Download failed${NC}"
    exit 1
fi

# Import PreDB data
echo "Importing PreDB data..."
cd "$NNTMUX_PATH" || exit 1

php artisan predb:import "$TEMP_FILE" \
    --skip-header \
    --truncate-staging \
    --no-interaction

# Check if import was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Import successful${NC}"
else
    echo -e "${RED}✗ Import failed${NC}"
    exit 1
fi

# Match releases against PreDB
echo "Matching releases against PreDB..."
php artisan predb:check 100000

# Cleanup
rm -f "$TEMP_FILE"

echo -e "${GREEN}PreDB update complete!${NC}"
