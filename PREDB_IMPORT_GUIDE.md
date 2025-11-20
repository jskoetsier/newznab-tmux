# PreDB Import Guide

This guide explains how to import PreDB data into NNTmux using the new import commands.

## Overview

NNTmux provides two methods for importing PreDB data:

1. **Live IRC Scraping** (Primary Method) - Real-time updates from IRC channels
2. **Bulk Import from Dumps** (Secondary Method) - Import large datasets from CSV/TSV files

## Method 1: Live IRC Scraping (Recommended)

The IRC scraper connects to IRC channels and receives real-time PRE announcements.

### Setup

1. Edit your `.env` file:
```bash
SCRAPE_IRC_USERNAME=your_unique_username
SCRAPE_IRC_SERVER=irc.synirc.net
SCRAPE_IRC_PORT=6667
SCRAPE_IRC_TLS=false
SCRAPE_IRC_PASSWORD=  # Optional, for ZNC bouncer
```

2. Start the IRC scraper:
```bash
php artisan irc:scrape
```

3. For debugging:
```bash
php artisan irc:scrape --debug
```

## Method 2: Bulk Import from Dumps

Use this method when you have a large PreDB dump file (daily dumps, historical data, etc.).

### Supported File Formats

- **CSV** (Comma-separated values)
- **TSV** (Tab-separated values)

### Expected Data Format

The import command expects the following column order (optional fields can be empty):

1. **title** (required) - The release name
2. **nfo** (optional) - NFO information
3. **size** (optional) - Size string (e.g., "1.5GB")
4. **category** (optional) - Category (e.g., "X264", "TV", "MP3")
5. **predate** (optional) - Pre date (any standard date format)
6. **source** (optional) - Source channel/site (defaults to "import")
7. **requestid** (optional) - Request ID (numeric, defaults to 0)
8. **groups_id** (optional) - Group ID (numeric, defaults to 0)
9. **nuked** (optional) - Nuke status (0=no, 1=unnuked, 2=nuked, defaults to 0)
10. **nukereason** (optional) - Reason for nuke
11. **files** (optional) - Number of files
12. **filename** (optional) - Filename (defaults to title)

### Import Commands

#### Basic CSV Import

```bash
php artisan predb:import /path/to/predb_dump.csv
```

#### TSV Import

```bash
php artisan predb:import /path/to/predb_dump.tsv --type=tsv
```

#### Import with Options

```bash
# Skip first line if it contains headers
php artisan predb:import /path/to/dump.csv --skip-header

# Truncate staging table before import
php artisan predb:import /path/to/dump.csv --truncate-staging

# Custom batch size (default: 10000)
php artisan predb:import /path/to/dump.csv --batch=50000

# All options combined
php artisan predb:import /path/to/dump.csv --type=csv --skip-header --truncate-staging --batch=50000
```

### Two-Stage Import Process

The import uses a two-stage process:

1. **Stage 1**: Import data into `predb_imports` staging table
   - Fast bulk insert without indexes
   - No duplicate checking during import

2. **Stage 2**: Migrate from staging to main `predb` table
   - Duplicate checking based on title
   - Existing records are skipped
   - Can be done immediately or later

#### Option 1: Import and Migrate in One Step

The command will ask if you want to migrate after import:

```bash
php artisan predb:import /path/to/dump.csv
# Answer "yes" when asked to migrate
```

#### Option 2: Import Now, Migrate Later

```bash
# Import to staging
php artisan predb:import /path/to/dump.csv
# Answer "no" when asked to migrate

# Later, migrate from staging to main table
php artisan predb:migrate-staging --truncate-staging --update-indexes
```

### Migrate Staging Command

```bash
# Basic migration
php artisan predb:migrate-staging

# Truncate staging table after migration
php artisan predb:migrate-staging --truncate-staging

# Update search indexes after migration
php artisan predb:migrate-staging --update-indexes

# Both options
php artisan predb:migrate-staging --truncate-staging --update-indexes
```

## Post-Import Tasks

### 1. Update Search Indexes

After importing PreDB data, update the search indexes:

```bash
# For Manticore
php artisan nntmux:populate --manticore --predb

# For Elasticsearch
php artisan nntmux:populate --elastic --predb
```

### 2. Match Releases to PreDB

Match your existing releases against the newly imported PreDB data:

```bash
# Check all releases
php artisan predb:check

# Check last N releases
php artisan predb:check 10000
```

### 3. Match Prefiles

Match release filenames to PreDB:

```bash
php artisan match:prefiles
```

## Finding PreDB Dumps

You can obtain PreDB dumps from:

1. **predb.me** - Provides daily dumps and API access
2. **srrDB** - Scene release database with dumps
3. **Community sources** - Various Usenet communities share PreDB dumps

## Example CSV Format

```csv
title,nfo,size,category,predate,source,requestid,groups_id,nuked,nukereason,files,filename
Some.Release.Name.2024.1080p.WEB-DL-GROUP,,3.5GB,X264,2024-01-15 10:30:00,predb.me,0,0,0,,47,Some.Release.Name.2024.1080p.WEB-DL-GROUP
Another.Release.PROPER.720p.HDTV-GROUP,,1.2GB,TV,2024-01-15 11:45:00,srrdb,0,0,0,,23,Another.Release.PROPER.720p.HDTV-GROUP
Nuked.Release.XXX.DVDRip-GROUP,,700MB,XXX,2024-01-15 12:00:00,predb.me,0,0,2,bad.ivtc,1,Nuked.Release.XXX.DVDRip-GROUP
```

## Troubleshooting

### Import Fails with "File not found"

Ensure the file path is absolute and the file exists:

```bash
# Use absolute path
php artisan predb:import /opt/nntmux/predb_dump.csv

# Check file exists
ls -lh /opt/nntmux/predb_dump.csv
```

### Import is Slow

Try increasing the batch size:

```bash
php artisan predb:import /path/to/dump.csv --batch=50000
```

### Out of Memory

Reduce the batch size:

```bash
php artisan predb:import /path/to/dump.csv --batch=5000
```

### Duplicate Key Errors

The staging table doesn't have unique constraints, but the main table does. Duplicates will be automatically skipped during migration.

### No Records Matched

After importing PreDB data, run:

```bash
# Check releases against PreDB
php artisan predb:check

# Verify PreDB count
php artisan tinker --execute='echo "PreDB count: " . \App\Models\Predb::count(); echo "\n";'
```

## Automation

### Daily PreDB Updates

Add to your crontab or task scheduler:

```bash
# Download daily dump (example, adjust URL)
0 3 * * * cd /opt/nntmux && wget -O /tmp/daily_predb.csv https://example.com/predb_daily.csv

# Import daily dump
5 3 * * * cd /opt/nntmux && php artisan predb:import /tmp/daily_predb.csv --truncate-staging && php artisan predb:migrate-staging --truncate-staging --update-indexes

# Match releases
10 3 * * * cd /opt/nntmux && php artisan predb:check 50000
```

## Performance Tips

1. **Use staging table for bulk imports** - Much faster than direct insert into main table
2. **Import during low traffic** - Database-intensive operation
3. **Adjust batch size** - Balance between memory usage and speed
4. **Disable search index updates during import** - Update indexes once at the end
5. **Use local files** - Don't stream from network during import

## Database Schema

The PreDB tables are located in the database:

- `predb` - Main PreDB table with indexes
- `predb_imports` - Staging table for bulk imports (no indexes)
- `predb_crcs` - Hash table for matching

## Support

For issues or questions:
- Check the logs: `storage/logs/laravel.log`
- Join Discord: https://discord.gg/GjgGSzkrjh
- GitHub Issues: https://github.com/NNTmux/newznab-tmux/issues
