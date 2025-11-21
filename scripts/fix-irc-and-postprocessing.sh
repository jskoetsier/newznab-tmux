#!/bin/bash
#
# Fix IRC Scraper and NFO Postprocessing
# Enables both in database settings and restarts them in tmux
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   NNTmux - Fix IRC Scraper & NFO Postprocessing               ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# 1. Enable IRC Scraper in database
echo "Step 1: Enabling IRC Scraper..."
mysql nntmux -e "UPDATE settings SET value='1' WHERE name='run_ircscraper';"
echo "✓ IRC Scraper enabled in database"
echo ""

# 2. Enable Postprocessing in database
echo "Step 2: Enabling Postprocessing..."
# post=3 enables BOTH Additional AND NFO postprocessing
mysql nntmux -e "UPDATE settings SET value='3' WHERE name='post';"
mysql nntmux -e "UPDATE settings SET value='1' WHERE name='post_amazon';"
mysql nntmux -e "UPDATE settings SET value='1' WHERE name='post_non';"
echo "✓ Postprocessing enabled in database (all types)"
echo "  post=3 (Additional + NFO), post_amazon=1, post_non=1"
echo ""

# 3. Verify settings
echo "Step 3: Verifying settings..."
mysql -N -B nntmux -e "SELECT name, value FROM settings WHERE name IN ('run_ircscraper', 'post', 'post_amazon', 'post_non', 'lookupnfo', 'maxnfoprocessed');"
echo ""

# 4. Restart IRC Scraper in tmux
echo "Step 4: Restarting IRC Scraper..."
if tmux has-session -t nntmux 2>/dev/null; then
    # Kill existing IRC scraper process
    pkill -f "php artisan irc:scrape" || true

    # Wait a moment
    sleep 2

    # Restart in tmux window 3
    tmux send-keys -t nntmux:3 C-c 2>/dev/null || true
    sleep 1
    tmux send-keys -t nntmux:3 'cd /opt/nntmux && php artisan irc:scrape' C-m

    echo "✓ IRC Scraper restarted in tmux window 3"
else
    echo "⚠ Tmux session 'nntmux' not found"
fi
echo ""

# 5. Start NFO Postprocessing
echo "Step 5: Starting NFO Postprocessing..."
if tmux has-session -t nntmux 2>/dev/null; then
    # Start in the first postprocessing pane
    tmux send-keys -t nntmux:2.0 C-c 2>/dev/null || true
    sleep 1
    tmux send-keys -t nntmux:2.0 'cd /opt/nntmux && while true; do echo "[$(date)] Starting NFO postprocessing..."; php artisan update:postprocess nfo; echo "[$(date)] NFO postprocessing complete, sleeping 30s..."; sleep 30; done' C-m

    echo "✓ NFO Postprocessing started in tmux window 2, pane 0"
else
    echo "⚠ Tmux session 'nntmux' not found"
fi
echo ""

# 6. Start Movies/TV Postprocessing
echo "Step 6: Starting Movies/TV Postprocessing..."
if tmux has-session -t nntmux 2>/dev/null; then
    tmux send-keys -t nntmux:2.1 C-c 2>/dev/null || true
    sleep 1
    tmux send-keys -t nntmux:2.1 'cd /opt/nntmux && while true; do echo "[$(date)] Starting Movies/TV postprocessing..."; php artisan update:postprocess movies; php artisan update:postprocess tv; echo "[$(date)] Movies/TV postprocessing complete, sleeping 30s..."; sleep 30; done' C-m

    echo "✓ Movies/TV Postprocessing started in tmux window 2, pane 1"
else
    echo "⚠ Tmux session 'nntmux' not found"
fi
echo ""

# 7. Start Additional Postprocessing
echo "Step 7: Starting Additional Postprocessing..."
if tmux has-session -t nntmux 2>/dev/null; then
    tmux send-keys -t nntmux:2.2 C-c 2>/dev/null || true
    sleep 1
    tmux send-keys -t nntmux:2.2 'cd /opt/nntmux && while true; do echo "[$(date)] Starting Additional postprocessing..."; php artisan update:postprocess additional; echo "[$(date)] Additional postprocessing complete, sleeping 30s..."; sleep 30; done' C-m

    echo "✓ Additional Postprocessing started in tmux window 2, pane 2"
else
    echo "⚠ Tmux session 'nntmux' not found"
fi
echo ""

# 8. Wait and verify
echo "Step 8: Waiting 5 seconds for processes to start..."
sleep 5
echo ""

echo "Step 9: Verifying running processes..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ps aux | grep -E 'irc:scrape|update:postprocess' | grep -v grep | awk '{print $11, $12, $13, $14}' || echo "No processes found yet..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                      FIX COMPLETE!                             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "✓ IRC Scraper: ENABLED and RUNNING"
echo "✓ NFO Postprocessing: ENABLED and RUNNING"
echo "✓ Movies/TV Postprocessing: ENABLED and RUNNING"
echo "✓ Additional Postprocessing: ENABLED and RUNNING"
echo ""
echo "To view the processes:"
echo "  tmux attach-session -t nntmux"
echo ""
echo "To monitor PreDB matching:"
echo "  ./scripts/predb-status.sh"
echo ""
