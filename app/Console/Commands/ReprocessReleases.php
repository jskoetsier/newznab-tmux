<?php

namespace App\Console\Commands;

use App\Models\Release;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class ReprocessReleases extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'releases:reprocess
                            {--unmatched-only : Only reprocess releases with predb_id = 0}
                            {--category= : Specific category ID to reprocess}
                            {--limit=1000 : Maximum number of releases to reset}
                            {--dry-run : Show what would be reset without making changes}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Reset processing flags to allow reprocessing with new fuzzy PreDB matching (v2.2.2)';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $unmatchedOnly = $this->option('unmatched-only');
        $categoryId = $this->option('category');
        $limit = (int) $this->option('limit');
        $dryRun = $this->option('dry-run');

        // Display configuration
        $this->info('=== Reset Release Processing Flags ===');
        $this->info('Unmatched Only: ' . ($unmatchedOnly ? 'YES' : 'NO'));
        $this->info('Category Filter: ' . ($categoryId ?: 'ALL'));
        $this->info('Limit: ' . number_format($limit));
        $this->info('Mode: ' . ($dryRun ? 'DRY RUN' : 'LIVE'));
        $this->newLine();

        if ($dryRun) {
            $this->warn('⚠️  DRY RUN MODE - No changes will be made');
            $this->newLine();
        }

        // Build query
        $query = Release::query();

        // Apply filters
        if ($unmatchedOnly) {
            $query->where('predb_id', 0);
            $this->info('Filter: Only releases without PreDB match (predb_id = 0)');
        }

        if ($categoryId) {
            $query->where('categories_id', $categoryId);
            $this->info('Filter: Category ID = ' . $categoryId);
        }

        // Get count before applying limit
        $totalCount = $query->count();
        $this->info('Total matching releases: ' . number_format($totalCount));
        
        // Apply limit
        $query->limit($limit);
        $affectedCount = min($limit, $totalCount);
        
        $this->info('Releases to reset: ' . number_format($affectedCount));
        $this->newLine();

        if ($affectedCount === 0) {
            $this->warn('No releases found matching criteria. Exiting.');
            return self::SUCCESS;
        }

        if ($dryRun) {
            $this->info('Would reset proc_nfo and proc_files flags for ' . number_format($affectedCount) . ' releases');
            $this->newLine();
            $this->warn('DRY RUN COMPLETE - No changes were made');
            $this->info('Run without --dry-run to actually reset processing flags');
            $this->newLine();
            $this->info('After resetting, run postprocessing to reprocess these releases:');
            $this->comment('  php artisan update:postprocess nfo');
            return self::SUCCESS;
        }

        // Confirm before proceeding
        if (!$this->confirm('Do you want to proceed with resetting processing flags?', true)) {
            $this->warn('Operation cancelled.');
            return self::SUCCESS;
        }

        // Reset the flags
        $this->info('Resetting processing flags...');
        $progressBar = $this->output->createProgressBar($affectedCount);
        
        $resetQuery = Release::query();
        if ($unmatchedOnly) {
            $resetQuery->where('predb_id', 0);
        }
        if ($categoryId) {
            $resetQuery->where('categories_id', $categoryId);
        }
        $resetQuery->limit($limit);
        
        $updated = $resetQuery->update([
            'proc_nfo' => 0,
            'proc_files' => 0,
        ]);
        
        $progressBar->finish();
        $this->newLine(2);

        // Display results
        $this->info('=== Reset Complete ===');
        $this->info('Releases updated: ' . number_format($updated));
        $this->newLine();
        
        if ($updated > 0) {
            $this->info('✓ Processing flags reset successfully!');
            $this->newLine();
            $this->info('Next steps:');
            $this->comment('  1. Run NFO postprocessing:');
            $this->comment('     php artisan update:postprocess nfo');
            $this->newLine();
            $this->comment('  2. Or run specific postprocessing types:');
            $this->comment('     php artisan update:postprocess movies');
            $this->comment('     php artisan update:postprocess tv');
            $this->comment('     php artisan update:postprocess additional');
            $this->newLine();
            $this->info('The new fuzzy PreDB matching (v2.2.2) will be applied automatically!');
        }

        return self::SUCCESS;
    }
}
