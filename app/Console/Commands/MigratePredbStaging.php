<?php

namespace App\Console\Commands;

use App\Models\PredbImport;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class MigratePredbStaging extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'predb:migrate-staging
                            {--truncate-staging : Truncate predb_imports after migration}
                            {--update-indexes : Update search indexes after migration}';

    /**
     * The console command description.
     */
    protected $description = 'Migrate predb data from predb_imports staging table to predb table';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $this->info('Migrating data from predb_imports to predb table...');
        $startTime = now();

        try {
            // Count records in staging
            $stagingCount = DB::table('predb_imports')->count();

            if ($stagingCount === 0) {
                $this->warn('No records found in predb_imports staging table.');

                return self::SUCCESS;
            }

            $this->info("Records in predb_imports: {$stagingCount}");

            // Count existing records in predb
            $predbCount = DB::table('predb')->count();
            $this->info("Records in predb before migration: {$predbCount}");

            // Insert records that don't already exist in predb (based on title)
            $this->info('Inserting new records...');

            $inserted = DB::statement("
                INSERT INTO predb (title, nfo, size, category, predate, source, requestid, groups_id, nuked, nukereason, files, filename, searched)
                SELECT DISTINCT pi.title, pi.nfo, pi.size, pi.category, pi.predate, pi.source, pi.requestid, pi.groups_id, pi.nuked, pi.nukereason, pi.files, pi.filename, pi.searched
                FROM predb_imports pi
                WHERE NOT EXISTS (
                    SELECT 1 FROM predb p WHERE p.title = pi.title
                )
            ");

            $duration = now()->diffInSeconds($startTime);

            if ($inserted) {
                $this->info('Migration complete!');
                $this->info("Duration: {$duration} seconds");

                // Count new records
                $newPredbCount = DB::table('predb')->count();
                $recordsAdded = $newPredbCount - $predbCount;
                $this->info("Records added: {$recordsAdded}");
                $this->info("Total records in predb table: {$newPredbCount}");

                // Truncate staging table if requested
                if ($this->option('truncate-staging')) {
                    $this->info('Truncating predb_imports staging table...');
                    PredbImport::truncate();
                    $this->info('Staging table truncated.');
                }

                // Update search indexes if requested
                if ($this->option('update-indexes')) {
                    $this->info('Updating search indexes...');
                    $engine = config('nntmux.elasticsearch_enabled') ? 'elastic' : 'manticore';
                    $this->call('nntmux:populate', ['--'.$engine => true, '--predb' => true]);
                }

                return self::SUCCESS;
            }

            $this->warn('No new records were inserted.');

            return self::SUCCESS;
        } catch (\Exception $e) {
            $this->error('Migration failed: '.$e->getMessage());
            $this->error($e->getTraceAsString());

            return self::FAILURE;
        }
    }
}
