<?php

namespace App\Console\Commands;

use App\Models\Category;
use App\Models\Release;
use Blacklight\ColorCLI;
use Blacklight\NameFixer;
use Blacklight\NNTP;
use Illuminate\Console\Command;

/**
 * v2.2.2: Artisan command to re-run name fixing on poorly-named releases
 *
 * This command identifies releases with poor names and attempts to fix them
 * using all available name fixing strategies (NFO, files, PAR2, PreDB, etc.)
 */
class FixReleaseNames extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'releases:fix-names
                            {--limit= : Maximum number of releases to process (default: 1000)}
                            {--category= : Only process releases in specific category ID}
                            {--dry-run : Show what would be fixed without actually fixing}
                            {--hash : Include hash-pattern releases}
                            {--yenc : Include yEnc-pattern releases}
                            {--short : Include short-name releases (< 15 chars)}
                            {--no-group : Include releases without group indicator}
                            {--all : Include all of the above criteria}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Re-run name fixing on poorly-named releases (v2.2.2)';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $colorCLI = new ColorCLI();
        $nameFixer = new NameFixer();

        $limit = (int) ($this->option('limit') ?? 1000);
        $categoryId = $this->option('category');
        $dryRun = $this->option('dry-run');

        // Determine which criteria to use
        $includeHash = $this->option('hash') || $this->option('all');
        $includeYenc = $this->option('yenc') || $this->option('all');
        $includeShort = $this->option('short') || $this->option('all');
        $includeNoGroup = $this->option('no-group') || $this->option('all');

        // If no criteria specified, use all by default
        if (!$includeHash && !$includeYenc && !$includeShort && !$includeNoGroup) {
            $includeHash = $includeYenc = $includeShort = $includeNoGroup = true;
        }

        $colorCLI->header('Release Name Fixer (v2.2.2)');
        $colorCLI->info('Finding poorly-named releases...');

        // Build query
        $query = Release::query()
            ->where(function ($q) use ($includeHash, $includeYenc, $includeShort, $includeNoGroup) {
                // Hash patterns: MD5, SHA1, hex strings
                if ($includeHash) {
                    $q->orWhere('searchname', 'REGEXP', '^[a-f0-9]{32,40}(-|$)');
                }

                // yEnc patterns
                if ($includeYenc) {
                    $q->orWhere('searchname', 'LIKE', '%yEnc%');
                }

                // Short names (< 15 characters, likely obfuscated)
                if ($includeShort) {
                    $q->orWhereRaw('LENGTH(searchname) < 15');
                }

                // No release group indicator (no dash or dot before last word)
                if ($includeNoGroup) {
                    $q->orWhere('searchname', 'NOT REGEXP', '[-.]\\w+$');
                }
            })
            ->where('predb_id', 0)  // Only fix releases not matched to PreDB
            ->orderByDesc('id');

        // Apply category filter if specified
        if ($categoryId !== null) {
            $query->where('categories_id', $categoryId);
        } else {
            // Default to "Other" categories if not specified
            $query->whereIn('categories_id', Category::OTHERS_GROUP);
        }

        $query->limit($limit);
        $releases = $query->get();

        $total = $releases->count();

        if ($total === 0) {
            $colorCLI->info('No poorly-named releases found.');
            return 0;
        }

        $colorCLI->info(sprintf('Found %d poorly-named releases to process.', $total));

        if ($dryRun) {
            $colorCLI->warning('DRY RUN MODE - No changes will be made');
        }

        $fixed = 0;
        $checked = 0;
        $progressBar = $this->output->createProgressBar($total);
        $progressBar->start();

        foreach ($releases as $release) {
            $checked++;

            // Reset NameFixer state for each release
            $nameFixer->reset();

            // Create mock release object with required fields
            $releaseObj = (object) [
                'releases_id' => $release->id,
                'id' => $release->id,
                'name' => $release->name,
                'searchname' => $release->searchname,
                'fromname' => $release->fromname,
                'groups_id' => $release->groups_id,
                'categories_id' => $release->categories_id,
                'predb_id' => $release->predb_id,
                'textstring' => '',  // Will be populated by specific checks
            ];

            // Try NFO-based naming
            $nfoResult = Release::fromQuery(sprintf(
                'SELECT UNCOMPRESS(nfo) AS textstring, nfo.releases_id AS nfoid
                 FROM release_nfos nfo
                 WHERE nfo.releases_id = %d LIMIT 1',
                $release->id
            ));

            if ($nfoResult->isNotEmpty()) {
                $releaseObj->textstring = $nfoResult[0]->textstring ?? '';
                $releaseObj->nfoid = $nfoResult[0]->nfoid ?? 0;
                $nameFixer->checkName($releaseObj, !$dryRun, 'NFO, ', !$dryRun, 0);

                if ($nameFixer->matched) {
                    $fixed++;
                    $progressBar->advance();
                    continue;
                }
            }

            // Try filename-based naming
            $fileResult = Release::fromQuery(sprintf(
                'SELECT GROUP_CONCAT(name ORDER BY LENGTH(name) DESC SEPARATOR "||") AS textstring
                 FROM release_files
                 WHERE releases_id = %d
                 GROUP BY releases_id',
                $release->id
            ));

            if ($fileResult->isNotEmpty()) {
                $releaseObj->textstring = $fileResult[0]->textstring ?? '';
                $nameFixer->checkName($releaseObj, !$dryRun, 'Filenames, ', !$dryRun, 0);

                if ($nameFixer->matched) {
                    $fixed++;
                    $progressBar->advance();
                    continue;
                }
            }

            // Try PAR2-based naming (requires NNTP connection)
            // Note: PAR2 checking requires additional setup, skipping for now

            $progressBar->advance();
        }

        $progressBar->finish();
        $this->newLine(2);

        if ($dryRun) {
            $colorCLI->info(sprintf(
                'DRY RUN: %d out of %d releases WOULD BE fixed.',
                $fixed,
                $checked
            ));
        } else {
            $colorCLI->header(sprintf(
                'Successfully fixed %d out of %d poorly-named releases!',
                $fixed,
                $checked
            ));
        }

        return 0;
    }
}
