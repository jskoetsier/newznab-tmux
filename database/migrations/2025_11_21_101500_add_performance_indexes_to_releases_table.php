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
        // Add indexes to releases table for performance
        $this->addIndexIfNotExists('releases', 'ix_releases_searchname', function (Blueprint $table) {
            $table->index('searchname', 'ix_releases_searchname');
        });

        $this->addIndexIfNotExists('releases', 'ix_releases_categories_postdate', function (Blueprint $table) {
            $table->index(['categories_id', 'postdate'], 'ix_releases_categories_postdate');
        });

        $this->addIndexIfNotExists('releases', 'ix_releases_groups_postdate', function (Blueprint $table) {
            $table->index(['groups_id', 'postdate'], 'ix_releases_groups_postdate');
        });

        $this->addIndexIfNotExists('releases', 'ix_releases_adddate', function (Blueprint $table) {
            $table->index('adddate', 'ix_releases_adddate');
        });

        $this->addIndexIfNotExists('releases', 'ix_releases_predb_id', function (Blueprint $table) {
            $table->index('predb_id', 'ix_releases_predb_id');
        });

        $this->addIndexIfNotExists('releases', 'ix_releases_size_postdate', function (Blueprint $table) {
            $table->index(['size', 'postdate'], 'ix_releases_size_postdate');
        });

        $this->addIndexIfNotExists('releases', 'ix_releases_grabs', function (Blueprint $table) {
            $table->index('grabs', 'ix_releases_grabs');
        });

        // Add indexes to collections table for performance
        $this->addIndexIfNotExists('collections', 'ix_collections_groups_date', function (Blueprint $table) {
            $table->index(['groups_id', 'dateadded'], 'ix_collections_groups_date');
        });

        $this->addIndexIfNotExists('collections', 'ix_collections_hash', function (Blueprint $table) {
            $table->index('collectionhash', 'ix_collections_hash');
        });

        $this->addIndexIfNotExists('collections', 'ix_collections_releases_id', function (Blueprint $table) {
            $table->index('releases_id', 'ix_collections_releases_id');
        });

        // Add indexes to binaries table for performance
        $this->addIndexIfNotExists('binaries', 'ix_binaries_collections_filecheck', function (Blueprint $table) {
            $table->index(['collections_id', 'partcheck'], 'ix_binaries_collections_filecheck');
        });

        $this->addIndexIfNotExists('binaries', 'ix_binaries_hash', function (Blueprint $table) {
            $table->index('binaryhash', 'ix_binaries_hash');
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
     * Add an index to a table if it doesn't already exist.
     *
     * @param  string  $tableName  The table name
     * @param  string  $indexName  The index name
     * @param  callable  $callback  The schema builder callback
     * @return void
     */
    private function addIndexIfNotExists(string $tableName, string $indexName, callable $callback): void
    {
        if (! $this->indexExists($tableName, $indexName)) {
            Schema::table($tableName, $callback);
        }
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
        $indexes = Schema::getIndexes($table);

        foreach ($indexes as $indexInfo) {
            if ($indexInfo['name'] === $index) {
                return true;
            }
        }

        return false;
    }
};
