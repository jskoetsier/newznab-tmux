<?php

namespace App\Console\Commands;

use App\Models\Predb;
use App\Models\PredbImport;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class ImportPredbDump extends Command
{
    /**
     * The name and signature of the console command.
     */
    protected $signature = 'predb:import
                            {file : Path to the predb dump file (CSV or TSV format)}
                            {--type=csv : File type (csv or tsv)}
                            {--skip-header : Skip the first line if it contains column headers}
                            {--batch=10000 : Batch size for inserting records}
                            {--truncate-staging : Truncate predb_imports table before import}';

    /**
     * The console command description.
     */
    protected $description = 'Import predb data from CSV/TSV dump file';

    /**
     * Execute the console command.
     */
    public function handle(): int
    {
        $filePath = $this->argument('file');
        $fileType = $this->option('type');
        $skipHeader = $this->option('skip-header');
        $batchSize = (int) $this->option('batch');
        $truncateStaging = $this->option('truncate-staging');

        // Validate file exists
        if (! File::exists($filePath)) {
            $this->error("File not found: {$filePath}");

            return self::FAILURE;
        }

        // Validate file type
        if (! in_array($fileType, ['csv', 'tsv'])) {
            $this->error('Invalid file type. Must be csv or tsv');

            return self::FAILURE;
        }

        $this->info('Starting PreDB import from: '.$filePath);
        $this->info('File type: '.$fileType);

        // Truncate staging table if requested
        if ($truncateStaging) {
            $this->info('Truncating predb_imports staging table...');
            PredbImport::truncate();
        }

        $delimiter = $fileType === 'tsv' ? "\t" : ',';
        $startTime = now();
        $totalProcessed = 0;
        $totalInserted = 0;
        $batch = [];

        // Open the file for reading
        $handle = fopen($filePath, 'r');
        if (! $handle) {
            $this->error('Unable to open file for reading');

            return self::FAILURE;
        }

        // Skip header if requested
        if ($skipHeader) {
            fgets($handle);
        }

        $this->info('Processing records...');
        $bar = $this->output->createProgressBar();

        try {
            DB::beginTransaction();

            while (($line = fgets($handle)) !== false) {
                $totalProcessed++;

                // Parse the line
                $fields = str_getcsv($line, $delimiter);

                // Skip empty lines
                if (empty($fields) || (count($fields) === 1 && empty($fields[0]))) {
                    continue;
                }

                // Map fields to predb structure
                // Expected format: title, nfo, size, category, predate, source, requestid, groups_id, nuked, nukereason, files, filename
                $record = $this->parseRecord($fields);

                if ($record) {
                    $batch[] = $record;
                }

                // Insert batch when it reaches the batch size
                if (count($batch) >= $batchSize) {
                    $inserted = $this->insertBatch($batch);
                    $totalInserted += $inserted;
                    $batch = [];
                    $bar->advance($batchSize);
                }
            }

            // Insert remaining records
            if (! empty($batch)) {
                $inserted = $this->insertBatch($batch);
                $totalInserted += $inserted;
                $bar->advance(count($batch));
            }

            DB::commit();
            $bar->finish();
            $this->newLine();

            fclose($handle);

            $duration = now()->diffInSeconds($startTime);

            $this->info('Import complete!');
            $this->info("Total lines processed: {$totalProcessed}");
            $this->info("Total records inserted: {$totalInserted}");
            $this->info("Duration: {$duration} seconds");

            // Ask if user wants to migrate from staging to main table
            if ($this->confirm('Do you want to migrate data from predb_imports to predb table now?', true)) {
                return $this->migrateToMainTable();
            }

            $this->info('You can migrate the data later using: php artisan predb:migrate-staging');

            return self::SUCCESS;
        } catch (\Exception $e) {
            DB::rollBack();
            fclose($handle);
            $this->error('Import failed: '.$e->getMessage());
            $this->error($e->getTraceAsString());

            return self::FAILURE;
        }
    }

    /**
     * Parse a record from CSV fields.
     */
    protected function parseRecord(array $fields): ?array
    {
        // Handle different formats
        // Format 1: title, nfo, size, category, predate, source, requestid, groups_id, nuked, nukereason, files, filename
        // Format 2 (minimal): title, category, predate, source, filename

        $title = trim($fields[0] ?? '');

        if (empty($title)) {
            return null;
        }

        // Build record based on available fields
        $record = [
            'title' => $title,
            'nfo' => isset($fields[1]) && ! empty(trim($fields[1])) ? trim($fields[1]) : null,
            'size' => isset($fields[2]) && ! empty(trim($fields[2])) ? trim($fields[2]) : null,
            'category' => isset($fields[3]) && ! empty(trim($fields[3])) ? trim($fields[3]) : null,
            'predate' => $this->parseDate($fields[4] ?? null),
            'source' => isset($fields[5]) && ! empty(trim($fields[5])) ? trim($fields[5]) : 'import',
            'requestid' => isset($fields[6]) && is_numeric($fields[6]) ? (int) $fields[6] : 0,
            'groups_id' => isset($fields[7]) && is_numeric($fields[7]) ? (int) $fields[7] : 0,
            'nuked' => isset($fields[8]) && is_numeric($fields[8]) ? (int) $fields[8] : 0,
            'nukereason' => isset($fields[9]) && ! empty(trim($fields[9])) ? trim($fields[9]) : null,
            'files' => isset($fields[10]) && ! empty(trim($fields[10])) ? trim($fields[10]) : null,
            'filename' => isset($fields[11]) && ! empty(trim($fields[11])) ? trim($fields[11]) : $title,
            'searched' => 0,
            'groupname' => isset($fields[12]) && ! empty(trim($fields[12])) ? trim($fields[12]) : null,
        ];

        return $record;
    }

    /**
     * Parse date from various formats.
     */
    protected function parseDate(?string $dateString): ?string
    {
        if (empty($dateString)) {
            return null;
        }

        $dateString = trim($dateString);

        try {
            // Try to parse the date
            $date = new \DateTime($dateString);

            return $date->format('Y-m-d H:i:s');
        } catch (\Exception $e) {
            // If parsing fails, return null
            return null;
        }
    }

    /**
     * Insert a batch of records into predb_imports.
     */
    protected function insertBatch(array $batch): int
    {
        try {
            // Use insert ignore to skip duplicates
            DB::table('predb_imports')->insert($batch);

            return count($batch);
        } catch (\Exception $e) {
            $this->warn('Error inserting batch: '.$e->getMessage());

            return 0;
        }
    }

    /**
     * Migrate data from predb_imports to predb table.
     */
    protected function migrateToMainTable(): int
    {
        $this->info('Migrating data from predb_imports to predb table...');
        $startTime = now();

        try {
            // Count records in staging
            $stagingCount = DB::table('predb_imports')->count();
            $this->info("Records in predb_imports: {$stagingCount}");

            // Insert records that don't already exist in predb (based on title)
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
                $newCount = DB::table('predb')->count();
                $this->info("Total records in predb table: {$newCount}");

                // Ask if user wants to truncate staging table
                if ($this->confirm('Do you want to truncate the predb_imports staging table?', true)) {
                    PredbImport::truncate();
                    $this->info('Staging table truncated.');
                }

                // Ask if user wants to update search indexes
                if ($this->confirm('Do you want to update search indexes now?', true)) {
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
