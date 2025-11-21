<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * v2.2.2: Add attempt counters for name fixing processes
     * Allows retry logic instead of permanent "proc_*" flags
     *
     * @return void
     */
    public function up(): void
    {
        Schema::table('releases', function (Blueprint $table) {
            // Add attempt counter columns for each processing type
            $table->tinyInteger('proc_nfo_attempts')->default(0)->after('proc_nfo')
                ->comment('Number of NFO processing attempts (v2.2.2)');

            $table->tinyInteger('proc_files_attempts')->default(0)->after('proc_files')
                ->comment('Number of file processing attempts (v2.2.2)');

            $table->tinyInteger('proc_par2_attempts')->default(0)->after('proc_par2')
                ->comment('Number of PAR2 processing attempts (v2.2.2)');

            $table->tinyInteger('proc_uid_attempts')->default(0)->after('proc_uid')
                ->comment('Number of UID processing attempts (v2.2.2)');

            $table->tinyInteger('proc_hash16k_attempts')->default(0)->after('proc_hash16k')
                ->comment('Number of hash16k processing attempts (v2.2.2)');

            $table->tinyInteger('proc_srr_attempts')->default(0)->after('proc_srr')
                ->comment('Number of SRR processing attempts (v2.2.2)');

            $table->tinyInteger('proc_crc32_attempts')->default(0)->after('proc_crc32')
                ->comment('Number of CRC32 processing attempts (v2.2.2)');
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
            $table->dropColumn([
                'proc_nfo_attempts',
                'proc_files_attempts',
                'proc_par2_attempts',
                'proc_uid_attempts',
                'proc_hash16k_attempts',
                'proc_srr_attempts',
                'proc_crc32_attempts',
            ]);
        });
    }
};
