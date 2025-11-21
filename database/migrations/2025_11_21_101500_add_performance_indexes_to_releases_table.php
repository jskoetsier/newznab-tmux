<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Adds performance indexes to frequently queried columns in the releases table.
     * These indexes significantly improve query performance for:
     * - Release searches by name/searchname
     * - Category filtering
     * - Group filtering
     * - Date range queries
     * - PreDB matching
     *
     * @return void
     */
    public function up(): void
    {
        Schema::table('releases', function (Blueprint $table) {
            // Add index for searchname (used in searches)
            if (! $this->indexExists('releases', 'ix_releases_searchname')) {
                $table->index('searchname', 'ix_releases_searchname');
            }

            // Add composite index for category + postdate (used in category browsing)
            if (! $this->indexExists('releases', 'ix_releases_categories_postdate')) {
                $table->index(['categories_id', 'postdate'], 'ix_releases_categories_postdate');
            }

            // Add composite index for group + postdate (used in group browsing)
            if (! $this->indexExists('releases', 'ix_releases_groups_postdate')) {
                $table->index(['groups_id', 'postdate'], 'ix_releases_groups_postdate');
            }

            // Add index for adddate (used in recent releases queries)
            if (! $this->indexExists('releases', 'ix_releases_adddate')) {
                $table->index('adddate', 'ix_releases_adddate');
            }

            // Add index for predb_id (used in PreDB matching)
            if (! $this->indexExists('releases', 'ix_releases_predb_id')) {
                $table->index('predb_id', 'ix_releases_predb_id');
            }

            // Add composite index for size + postdate (used in size filtering)
            if (! $this->indexExists('releases', 'ix_releases_size_postdate')) {
                $table->index(['size', 'postdate'], 'ix_releases_size_postdate');
            }

            // Add index for grabs (used in popular releases)
            if (! $this->indexExists('releases', 'ix_releases_grabs')) {
                $table->index('grabs', 'ix_releases_grabs');
            }
        });

        // Add indexes to collections table for performance
        Schema::table('collections', function (Blueprint $table) {
            // Add composite index for group + date
            if (! $this->indexExists('collections', 'ix_collections_groups_date')) {
                $table->index(['groups_id', 'dateadded'], 'ix_collections_groups_date');
            }

            // Add index for collectionhash (used in deduplication)
            if (! $this->indexExists('collections', 'ix_collections_hash')) {
                $table->index('collectionhash', 'ix_collections_hash');
            }

            // Add index for releases_id (used in joining)
            if (! $this->indexExists('collections', 'ix_collections_releases_id')) {
                $table->index('releases_id', 'ix_collections_releases_id');
            }
        });

        // Add indexes to binaries table for performance
        Schema::table('binaries', function (Blueprint $table) {
            // Add composite index for collection + filecheck
            if (! $this->indexExists('binaries', 'ix_binaries_collections_filecheck')) {
                $table->index(['collections_id', 'partcheck'], 'ix_binaries_collections_filecheck');
            }

            // Add index for binaryhash (used in deduplication)
            if (! $this->indexExists('binaries', 'ix_binaries_hash')) {
                $table->index('binaryhash', 'ix_binaries_hash');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down(): void
    {
        Schema::table('releases', function (Blueprint $table) {
            $table->dropIndex('ix_releases_searchname');
            $table->dropIndex('ix_releases_categories_postdate');
            $table->dropIndex('ix_releases_groups_postdate');
            $table->dropIndex('ix_releases_adddate');
            $table->dropIndex('ix_releases_predb_id');
            $table->dropIndex('ix_releases_size_postdate');
            $table->dropIndex('ix_releases_grabs');
        });

        Schema::table('collections', function (Blueprint $table) {
            $table->dropIndex('ix_collections_groups_date');
            $table->dropIndex('ix_collections_hash');
            $table->dropIndex('ix_collections_releases_id');
        });

        Schema::table('binaries', function (Blueprint $table) {
            $table->dropIndex('ix_binaries_collections_filecheck');
            $table->dropIndex('ix_binaries_hash');
        });
    }

    /**
     * Check if an index exists on a table.
     *
     * @param  string  $table  The table name
     * @param  string  $index  The index name
     * @return bool
     */
    private function indexExists(string $table, string $index): bool
    {
        $connection = Schema::getConnection();
        $dbSchemaManager = $connection->getDoctrineSchemaManager();
        $doctrineTable = $dbSchemaManager->listTableDetails($table);

        return $doctrineTable->hasIndex($index);
    }
};
