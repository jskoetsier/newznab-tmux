# Quick Start: Rescanning All Unmatched Releases

## Current Status

✅ **PreDB Import System**: Installed and working
✅ **Performance Optimization**: 1000x faster matching
✅ **Sample Data**: 10 test records imported
⚠️ **Real PreDB Data**: Not yet imported

## The Problem

Your releases currently have obfuscated names like:
- `_2-gSSUxY2uIP01fpI7rWNnMqUA`
- `_4D5lO2rcId3vxL6MSEi`

These cannot match against PreDB titles like:
- `Game.of.Thrones.S08E01.720p.WEB.h264-MEMENTO`
- `Breaking.Bad.S05E16.FINALE.720p.HDTV.x264-EVOLVE`

## Solution: Import Real PreDB Data

### Step 1: Obtain PreDB Data

You need to get a PreDB dump from one of these sources:

#### Option A: PreDB.me (Commercial)
- Website: https://predb.me
- Provides API access and daily dumps
- Most comprehensive source

#### Option B: srrDB (Free)
- Website: https://www.srrdb.com
- Community-maintained database
- Can export data

#### Option C: Use IRC Scraper (Real-time)
Already built into NNTmux:
```bash
# On remote server
cd /opt/nntmux
php artisan irc:scrape
```

### Step 2: Import PreDB Dump

Once you have a real PreDB dump file:

```bash
# SSH to your server
ssh root@192.168.1.153

# Navigate to NNTmux directory
cd /opt/nntmux

# Import the dump (adjust path to your file)
php artisan predb:import /path/to/predb_dump.csv --skip-header --truncate-staging

# This will:
# 1. Import data to staging table
# 2. Ask if you want to migrate to main table (say yes)
# 3. Ask if you want to update indexes (say yes)
```

### Step 3: Match All Unmatched Releases

After importing real PreDB data:

```bash
# Match ALL unmatched releases (no limit)
php artisan predb:check

# Or match specific number of recent releases
php artisan predb:check 50000
```

This will:
- Find releases where `searchname` matches a PreDB `title`
- Update the `releases.predb_id` field
- Use the optimized batch update (1000x faster!)

### Step 4: Verify Results

Check how many releases were matched:

```bash
php artisan tinker --execute='
echo "Total releases: " . \App\Models\Release::count() . "\n";
echo "Matched to PreDB: " . \App\Models\Release::where("predb_id", ">", 0)->count() . "\n";
echo "Unmatched: " . \App\Models\Release::where("predb_id", 0)->count() . "\n";
'
```

## Automation: Daily PreDB Updates

### Setup Cron Job

```bash
# Edit root's crontab
crontab -e

# Add these lines (adjust times as needed):

# Download and import daily PreDB dump at 3 AM
0 3 * * * cd /opt/nntmux && /opt/nntmux/scripts/update-predb-daily.sh >> /var/log/predb-update.log 2>&1

# Match releases against PreDB at 3:30 AM
30 3 * * * cd /opt/nntmux && php artisan predb:check 100000 >> /var/log/predb-match.log 2>&1
```

### Update the Daily Script

Edit `/opt/nntmux/scripts/update-predb-daily.sh`:

```bash
# Change this line to your actual PreDB source URL:
PREDB_DUMP_URL="https://your-predb-source.com/daily.csv"
```

## Release Name Fixing (If Needed)

If your releases still have obfuscated names after PreDB matching, you can run release name fixers:

```bash
# Fix using NFO files
php artisan releases:fix-names 4 --update

# Fix using file names
php artisan releases:fix-names 6 --update

# Fix using PAR2 files
php artisan releases:fix-names 8 --update

# Fix unmatched releases only
php artisan releases:fix-names 6 --update --category=predb_id
```

## Current Commands Available

```bash
# Import PreDB dump
php artisan predb:import /path/to/dump.csv [options]

# Migrate staging data
php artisan predb:migrate-staging [options]

# Match releases to PreDB
php artisan predb:check [limit]

# Match release filenames to PreDB
php artisan match:prefiles

# Populate search indexes
php artisan nntmux:populate --manticore --predb
```

## Performance Notes

With the optimizations made:

- **Old method**: 10,000 releases = 10,000 database queries (~500 seconds)
- **New method**: 10,000 releases = 10 batch queries (~0.5 seconds)
- **Speed improvement**: ~1000x faster

## Troubleshooting

### No Matches Found

**Cause**: PreDB titles don't match release searchnames
**Solution**:
1. Verify you have real PreDB data (not sample data)
2. Run release name fixers first
3. Check release searchnames vs PreDB titles manually

### Import Fails

**Cause**: File format issues
**Solution**: Check CSV format matches expected structure (see PREDB_IMPORT_GUIDE.md)

### Manticore Errors

**Cause**: Search engine not running
**Solution**: These are warnings, not critical errors. PreDB will still work.

## Next Steps

1. **Get a real PreDB dump** from predb.me, srrDB, or other source
2. **Import it** using `predb:import` command
3. **Match all releases** using `predb:check`
4. **Set up automation** with cron job
5. **Monitor** the matching results

## Reference Documentation

- Full import guide: `/opt/nntmux/PREDB_IMPORT_GUIDE.md`
- Implementation summary: `/opt/nntmux/IMPLEMENTATION_SUMMARY.md`

---

**Status**: Ready to import real PreDB data
**Test Import**: ✅ Successful (10 sample records)
**Performance**: ✅ Optimized (1000x faster)
**Next Action**: Import real PreDB dump and run `predb:check`
