<?php

namespace App\Console\Commands;

use App\Models\Release;
use Blacklight\NameFixer;
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
                            {--reset-flags : Reset proc_nfo and proc_files flags before reprocessing}
                            {--unmatched-only : Only reprocess releases with predb_id = 0}
                            {--category= : Specific category ID to reprocess}
                            {--limit=1000 : Maximum number of releases to process}
                            {--batch=100 : Number of releases to process per batch}
                            {--dry-run : Show what would be reprocessed without making changes}
                            {--show-details : Show detailed progress information}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Reprocess releases with new fuzzy PreDB matching (v2.2.2)';

    protected NameFixer $nameFixer;
    protected int $processed = 0;
    protected int $matched = 0;
    protected int $unchanged = 0;
    protected int $errors = 0;

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->nameFixer = new NameFixer(['Settings' => null]);

        $resetFlags = $this->option('reset-flags');
        $unmatchedOnly = $this->option('unmatched-only');
        $categoryId = $this->option('category');
        $limit = (int) $this->option('limit');
        $batchSize = (int) $this->option('batch');
        $dryRun = $this->option('dry-run');
        $showDetails = $this->option('show-details');

        // Display configuration
        $this->info('=== Reprocess Releases Configuration ===');
        $this->info('Reset Flags: ' . ($resetFlags ? 'YES' : 'NO'));
        $this->info('Unmatched Only: ' . ($unmatchedOnly ? 'YES' : 'NO'));
        $this->info('Category Filter: ' . ($categoryId ?: 'ALL'));
        $this->info('Limit: ' . number_format($limit));
        $this->info('Batch Size: ' . number_format($batchSize));
        $this->info('Mode: ' . ($dryRun ? 'DRY RUN' : 'LIVE'));
        $this->newLine();

        if ($dryRun) {
            $this->warn('⚠️  DRY RUN MODE - No changes will be made');
            $this->newLine();
        }

        // Build query
        $query = Release::query()
            ->select(['id', 'name', 'searchname', 'categories_id', 'predb_id', 'proc_nfo', 'proc_files'])
            ->orderBy('id', 'DESC');

        // Apply filters
        if ($unmatchedOnly) {
            $query->where('predb_id', 0);
            $this->info('Filter: Only releases without PreDB match (predb_id = 0)');
        }

        if ($categoryId) {
            $query->where('categories_id', $categoryId);
            $this->info('Filter: Category ID = ' . $categoryId);
        }

        $query->limit($limit);

        // Get total count
        $totalReleases = $query->count();
        $this->info('Found ' . number_format($totalReleases) . ' releases to reprocess');
        $this->newLine();

        if ($totalReleases === 0) {
            $this->warn('No releases found matching criteria. Exiting.');
            return self::SUCCESS;
        }

        // Confirm before proceeding
        if (!$dryRun && !$this->confirm('Do you want to proceed with reprocessing?', true)) {
            $this->warn('Reprocessing cancelled.');
            return self::SUCCESS;
        }

        // Step 1: Reset flags if requested
        if ($resetFlags && !$dryRun) {
            $this->info('Step 1: Resetting processing flags...');

            $resetQuery = Release::query();
            if ($unmatchedOnly) {
                $resetQuery->where('predb_id', 0);
            }
            if ($categoryId) {
                $resetQuery->where('categories_id', $categoryId);
            }
            $resetQuery->limit($limit);

            $resetCount = $resetQuery->update([
                'proc_nfo' => 0,
                'proc_files' => 0,
            ]);

            $this->info("Reset proc_nfo and proc_files flags for {$resetCount} releases");
            $this->newLine();
        } elseif ($resetFlags && $dryRun) {
            $this->info('Step 1: Would reset proc_nfo and proc_files flags (DRY RUN)');
            $this->newLine();
        }

        // Step 2: Process releases in batches
        $this->info('Step 2: Reprocessing releases with fuzzy PreDB matching...');
        $this->newLine();

        $progressBar = $this->output->createProgressBar($totalReleases);
        $progressBar->setFormat(' %current%/%max% [%bar%] %percent:3s%% %elapsed:6s% %memory:6s% | Matched: %matched% | Unchanged: %unchanged% | Errors: %errors%');
        $progressBar->setMessage('0', 'matched');
        $progressBar->setMessage('0', 'unchanged');
        $progressBar->setMessage('0', 'errors');
        $progressBar->start();

        // Process in chunks
        $releases = $query->get();

        foreach ($releases->chunk($batchSize) as $chunk) {
            foreach ($chunk as $release) {
                try {
                    $originalPredbId = $release->predb_id;
                    $originalName = $release->searchname;

                    if (!$dryRun) {
                        // Run name fixing with new fuzzy matching
                        $result = $this->nameFixer->fixNamesWithNfo(
                            $release->name,
                            $release->id,
                            0, // Use default echo level
                            $release->searchname
                        );

                        // Reload release to check if it was updated
                        $release->refresh();

                        // Check if PreDB match was found
                        if ($release->predb_id > 0 && $originalPredbId === 0) {
                            $this->matched++;

                            if ($showDetails) {
                                $this->newLine();
                                $this->line("  ✓ ID {$release->id}: Matched to PreDB #{$release->predb_id}");
                                $this->line("    Old: {$originalName}");
                                $this->line("    New: {$release->searchname}");
                            }
                        } elseif ($release->predb_id === $originalPredbId) {
                            $this->unchanged++;
                        }
                    } else {
                        // Dry run - just count what would be processed
                        $this->unchanged++;
                    }

                    $this->processed++;

                } catch (\Exception $e) {
                    $this->errors++;

                    if ($showDetails) {
                        $this->newLine();
                        $this->error("  ✗ ID {$release->id}: Error - " . $e->getMessage());
                    }
                }

                // Update progress bar
                $progressBar->setMessage((string) $this->matched, 'matched');
                $progressBar->setMessage((string) $this->unchanged, 'unchanged');
                $progressBar->setMessage((string) $this->errors, 'errors');
                $progressBar->advance();
            }
        }

        $progressBar->finish();
        $this->newLine(2);

        // Display results
        $this->info('=== Reprocessing Results ===');
        $this->info('Total Processed: ' . number_format($this->processed));
        $this->info('New PreDB Matches: ' . number_format($this->matched));
        $this->info('Unchanged: ' . number_format($this->unchanged));
        $this->info('Errors: ' . number_format($this->errors));
        $this->newLine();

        if ($this->matched > 0) {
            $matchRate = ($this->matched / $this->processed) * 100;
            $this->info(sprintf('Match Rate: %.2f%%', $matchRate));
            $this->newLine();

            if (!$dryRun) {
                $this->info('✓ Fuzzy PreDB matching successfully improved ' . number_format($this->matched) . ' releases!');
            }
        } elseif (!$dryRun) {
            $this->warn('No new PreDB matches found. Possible reasons:');
            $this->warn('  • Releases may already be matched');
            $this->warn('  • PreDB database may not contain matching entries');
            $this->warn('  • Fuzzy matching thresholds may need adjustment');
            $this->warn('');
            $this->info('Try adjusting config/nntmux.php:');
            $this->info('  • predb_fuzzy_min_similarity (default: 85)');
            $this->info('  • predb_fuzzy_max_distance (default: 5)');
        }

        if ($dryRun) {
            $this->newLine();
            $this->warn('DRY RUN COMPLETE - No changes were made');
            $this->info('Run without --dry-run to actually reprocess releases');
        }

        return self::SUCCESS;
    }
}
