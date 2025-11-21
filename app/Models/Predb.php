<?php

namespace App\Models;

use Blacklight\ColorCLI;
use Blacklight\ConsoleTools;
use Blacklight\ElasticSearchSiteSearch;
use Blacklight\ManticoreSearch;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Cache;
use Laravel\Scout\Searchable;

/**
 * App\Models\Predb.
 *
 * @property mixed $release
 * @property mixed $hash
 * @property int $id Primary key
 * @property string $title
 * @property string|null $nfo
 * @property string|null $size
 * @property string|null $category
 * @property string|null $predate
 * @property string $source
 * @property int $requestid
 * @property int $groups_id FK to groups
 * @property bool $nuked Is this pre nuked? 0 no 2 yes 1 un nuked 3 mod nuked
 * @property string|null $nukereason If this pre is nuked, what is the reason?
 * @property string|null $files How many files does this pre have ?
 * @property string $filename
 * @property bool $searched
 *
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereCategory($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereFilename($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereFiles($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereGroupsId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereNfo($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereNuked($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereNukereason($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb wherePredate($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereRequestid($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereSearched($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereSize($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereSource($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb whereTitle($value)
 *
 * @mixin \Eloquent
 *
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Predb query()
 */
class Predb extends Model
{
    use Searchable;

    // Nuke status.
    public const PRE_NONUKE = 0; // Pre is not nuked.

    public const PRE_UNNUKED = 1; // Pre was un nuked.

    public const PRE_NUKED = 2; // Pre is nuked.

    public const PRE_MODNUKE = 3; // Nuke reason was modified.

    public const PRE_RENUKED = 4; // Pre was re nuked.

    public const PRE_OLDNUKE = 5; // Pre is nuked for being old.

    /**
     * @var string
     */
    protected $table = 'predb';

    /**
     * @var bool
     */
    public $timestamps = false;

    /**
     * @var bool
     */
    protected $dateFormat = false;

    /**
     * @var array
     */
    protected $guarded = [];

    public function hash(): HasMany
    {
        return $this->hasMany(PredbHash::class, 'predb_id');
    }

    public function release(): HasMany
    {
        return $this->hasMany(Release::class, 'predb_id');
    }

    /**
     * Attempts to match PreDB titles to releases.
     *
     *
     * @throws \RuntimeException
     */
    public static function checkPre(bool|int|string $dateLimit = false): void
    {
        $consoleTools = new ConsoleTools;

        if (config('nntmux.echocli')) {
            (new ColorCLI)->header('Querying DB for release search names not matched with PreDB titles.');
        }

        $query = self::query()
            ->where('releases.predb_id', '<', 1)
            ->join('releases', 'predb.title', '=', 'releases.searchname')
            ->select(['predb.id as predb_id', 'releases.id as releases_id']);
        if ($dateLimit !== false && (int) $dateLimit > 0) {
            $query->where('adddate', '>', now()->subDays((int) $dateLimit));
        }

        $res = $query->get();

        if ($res !== null && $res->count() > 0) {
            $total = $res->count();
            (new ColorCLI)->primary(number_format($total).' releases to match.');

            // Batch update for better performance
            $batchSize = 1000;
            $batches = $res->chunk($batchSize);
            $updated = 0;

            foreach ($batches as $batch) {
                // Build case statement for batch update
                $cases = [];
                $ids = [];

                foreach ($batch as $row) {
                    $cases[] = "WHEN {$row->releases_id} THEN {$row->predb_id}";
                    $ids[] = $row->releases_id;
                }

                if (! empty($ids)) {
                    $idsString = implode(',', $ids);
                    $caseString = implode(' ', $cases);

                    // Perform batch update using a single query
                    \DB::update("
                        UPDATE releases
                        SET predb_id = CASE id {$caseString} END
                        WHERE id IN ({$idsString})
                    ");

                    $updated += count($ids);

                    if (config('nntmux.echocli')) {
                        $consoleTools->overWritePrimary(
                            'Matching up preDB titles with release searchnames: '.$consoleTools->percentString($updated, $total)
                        );
                    }
                }
            }

            if (config('nntmux.echocli')) {
                echo PHP_EOL;
                (new ColorCLI)->header(
                    'Matched '.number_format($updated).' PreDB titles to release search names.'
                );
            }
        } else {
            if (config('nntmux.echocli')) {
                (new ColorCLI)->primary('No releases found to match against PreDB.');
            }
        }
    }

    /**
     * Try to match a single release to a PreDB title when the release is created.
     *
     * @return array|false Array with title/id from PreDB if found, false if not found.
     */
    public static function matchPre(string $cleanerName)
    {
        if (empty($cleanerName)) {
            return false;
        }

        // v2.2.2: Phase 1 - Exact title match
        $titleCheck = self::query()->where('title', $cleanerName)->first(['id']);

        if ($titleCheck !== null) {
            return [
                'title' => $cleanerName,
                'predb_id' => $titleCheck['id'],
            ];
        }

        // v2.2.2: Phase 2 - Exact filename match
        $fileCheck = self::query()->where('filename', $cleanerName)->first(['id', 'title']);

        if ($fileCheck !== null) {
            return [
                'title' => $fileCheck['title'],
                'predb_id' => $fileCheck['id'],
            ];
        }

        // v2.2.2: Phase 3 - Normalized matching (dots to spaces)
        $normalizedName = str_replace('.', ' ', $cleanerName);
        if ($normalizedName !== $cleanerName) {
            $normalizedCheck = self::query()->where('title', $normalizedName)->first(['id']);

            if ($normalizedCheck !== null) {
                return [
                    'title' => $normalizedName,
                    'predb_id' => $normalizedCheck['id'],
                ];
            }
        }

        // v2.2.2: Phase 4 - Fuzzy matching (similarity-based)
        if (config('nntmux.predb_fuzzy_matching_enabled', true)) {
            $fuzzyMatch = self::fuzzyMatchPre($cleanerName);
            if ($fuzzyMatch !== false) {
                return $fuzzyMatch;
            }
        }

        return false;
    }

    /**
     * v2.2.2: Perform fuzzy matching using Levenshtein distance and similarity scores.
     *
     * @param string $searchName The release name to search for
     * @return array|false Array with title/id from PreDB if found, false if not found.
     */
    private static function fuzzyMatchPre(string $searchName)
    {
        if (empty($searchName)) {
            return false;
        }

        // Configuration: Minimum similarity threshold (0-100)
        $minSimilarity = config('nntmux.predb_fuzzy_min_similarity', 85);

        // Configuration: Maximum Levenshtein distance
        $maxLevenshtein = config('nntmux.predb_fuzzy_max_distance', 5);

        // Extract key components from search name for better matching
        // Remove common noise: dots, underscores, excessive spaces
        $cleanSearch = preg_replace('/[._]+/', ' ', $searchName);
        $cleanSearch = preg_replace('/\s+/', ' ', $cleanSearch);
        $cleanSearch = trim($cleanSearch);

        // Get potential candidates - search for titles with similar length
        $searchLen = strlen($searchName);
        $lenRange = max(5, (int)($searchLen * 0.2)); // 20% length variance

        // Query PreDB for candidates within reasonable length range
        $candidates = self::query()
            ->whereRaw('CHAR_LENGTH(title) BETWEEN ? AND ?', [
                $searchLen - $lenRange,
                $searchLen + $lenRange
            ])
            ->limit(100)
            ->get(['id', 'title']);

        $bestMatch = null;
        $bestScore = 0;

        foreach ($candidates as $candidate) {
            $candidateTitle = $candidate->title;

            // Calculate similarity percentage
            similar_text($searchName, $candidateTitle, $similarityPercent);

            if ($similarityPercent >= $minSimilarity) {
                // Calculate Levenshtein distance for additional validation
                $distance = levenshtein(
                    substr($searchName, 0, 255),
                    substr($candidateTitle, 0, 255)
                );

                if ($distance <= $maxLevenshtein && $similarityPercent > $bestScore) {
                    $bestMatch = $candidate;
                    $bestScore = $similarityPercent;
                }
            }
        }

        if ($bestMatch !== null) {
            return [
                'title' => $bestMatch->title,
                'predb_id' => $bestMatch->id,
            ];
        }

        return false;
    }

    /**
     * @return mixed
     *
     * @throws \Exception
     */
    public static function getAll(string $search = '')
    {
        $expiresAt = now()->addMinutes(config('nntmux.cache_expiry_medium'));
        $predb = Cache::get(md5($search));
        if ($predb !== null) {
            return $predb;
        }
        $sql = self::query()
            ->leftJoin('releases', 'releases.predb_id', '=', 'predb.id')
            ->select('predb.*', 'releases.guid')
            ->orderByDesc('predb.predate');
        if (! empty($search)) {
            if (config('nntmux.elasticsearch_enabled') === true) {
                $ids = (new ElasticSearchSiteSearch)->predbIndexSearch($search);
            } else {
                $manticore = new ManticoreSearch;
                $ids = Arr::get($manticore->searchIndexes('predb_rt', $search, ['title']), 'id');
            }
            $sql->whereIn('predb.id', $ids);
        }

        $predb = $sql->paginate(config('nntmux.items_per_page'));
        $predb->withPath(url('admin/predb'));
        Cache::put(md5($search), $predb, $expiresAt);

        return $predb;
    }

    /**
     * Get all PRE's for a release.
     *
     *
     * @return \Illuminate\Database\Eloquent\Collection|static[]
     */
    public static function getForRelease($preID)
    {
        return self::query()->where('id', $preID)->get();
    }

    /**
     * Return a single PRE for a release.
     *
     *
     * @return Model|null|static
     */
    public static function getOne($preID)
    {
        return self::query()->where('id', $preID)->first();
    }

    public function searchableAs(): string
    {
        return 'ft_predb_filename';
    }

    public function toSearchableArray(): array
    {
        return [
            'filename' => $this->filename,
        ];
    }
}
