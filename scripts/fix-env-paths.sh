#!/bin/bash
#
# Fix .env Tool Paths
# Automatically detects and updates paths for required tools in .env
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          NNTmux - Fix .env Tool Paths                         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found at $ENV_FILE"
    exit 1
fi

echo "📁 Using .env file: $ENV_FILE"
echo ""

# Function to find and set path in .env
update_env_path() {
    local var_name=$1
    local command_name=$2
    local path=""
    
    # Try to find the command
    if command -v "$command_name" &> /dev/null; then
        path=$(which "$command_name")
        echo "✓ Found $command_name: $path"
        
        # Update in .env file
        if grep -q "^${var_name}=" "$ENV_FILE"; then
            sed -i.bak "s|^${var_name}=.*|${var_name}=${path}|" "$ENV_FILE"
        else
            echo "${var_name}=${path}" >> "$ENV_FILE"
        fi
    else
        echo "⚠ $command_name not found - leaving empty"
    fi
}

# Function to find magic file
find_magic_file() {
    local magic_paths=(
        "/usr/share/file/magic.mgc"
        "/usr/share/misc/magic.mgc"
        "/usr/share/file/magic"
        "/usr/share/misc/magic"
    )
    
    for path in "${magic_paths[@]}"; do
        if [ -f "$path" ]; then
            echo "✓ Found magic file: $path"
            
            if grep -q "^MAGIC_FILE_PATH=" "$ENV_FILE"; then
                sed -i.bak "s|^MAGIC_FILE_PATH=.*|MAGIC_FILE_PATH=${path}|" "$ENV_FILE"
            else
                echo "MAGIC_FILE_PATH=${path}" >> "$ENV_FILE"
            fi
            return 0
        fi
    done
    
    echo "⚠ Magic file not found - leaving empty"
    return 1
}

# Function to set NZB and Covers paths
set_storage_paths() {
    local nzb_path="$SCRIPT_DIR/../resources/nzb"
    local covers_path="$SCRIPT_DIR/../public/covers"
    
    # Create directories if they don't exist
    mkdir -p "$nzb_path"
    mkdir -p "$covers_path"
    
    echo "✓ NZB path: $nzb_path"
    echo "✓ Covers path: $covers_path"
    
    # Update in .env
    if grep -q "^PATH_TO_NZBS=" "$ENV_FILE"; then
        sed -i.bak "s|^PATH_TO_NZBS=.*|PATH_TO_NZBS=${nzb_path}|" "$ENV_FILE"
    else
        echo "PATH_TO_NZBS=${nzb_path}" >> "$ENV_FILE"
    fi
    
    if grep -q "^COVERS_PATH=" "$ENV_FILE"; then
        sed -i.bak "s|^COVERS_PATH=.*|COVERS_PATH=${covers_path}|" "$ENV_FILE"
    else
        echo "COVERS_PATH=${covers_path}" >> "$ENV_FILE"
    fi
}

echo "Step 1: Detecting tool paths..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Update each tool path
update_env_path "UNRAR_PATH" "unrar"
update_env_path "UNZIP_PATH" "unzip"

# Try 7z, 7za, or p7zip
if command -v 7z &> /dev/null; then
    update_env_path "S7ZIP_PATH" "7z"
elif command -v 7za &> /dev/null; then
    update_env_path "S7ZIP_PATH" "7za"
elif command -v p7zip &> /dev/null; then
    update_env_path "S7ZIP_PATH" "p7zip"
else
    echo "⚠ 7zip not found - leaving empty"
fi

update_env_path "FFMPEG_PATH" "ffmpeg"
update_env_path "LAME_PATH" "lame"
update_env_path "MEDIAINFO_PATH" "mediainfo"
update_env_path "TIMEOUT_PATH" "timeout"

echo ""
echo "Step 2: Finding magic file..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
find_magic_file

echo ""
echo "Step 3: Setting storage paths..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
set_storage_paths

echo ""
echo "Step 4: Summary of updates..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
grep -E "^(UNRAR_PATH|UNZIP_PATH|S7ZIP_PATH|PATH_TO_NZBS|FFMPEG_PATH|LAME_PATH|MEDIAINFO_PATH|TIMEOUT_PATH|MAGIC_FILE_PATH|COVERS_PATH)=" "$ENV_FILE" || echo "No paths found in .env"

# Clean up backup file
rm -f "${ENV_FILE}.bak"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    UPDATE COMPLETE!                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "✓ Tool paths have been updated in .env"
echo ""
echo "📝 Note: If any tools are missing, install them:"
echo "  sudo apt install unrar unzip p7zip-full ffmpeg lame mediainfo"
echo ""
echo "🔄 After installing new tools, run this script again to update paths"
echo ""
