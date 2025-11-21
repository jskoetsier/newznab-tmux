<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * App\Models\Part.
 *
 * @property int $binaries_id
 * @property string $messageid
 * @property int $number
 * @property int $partnumber
 * @property int $size
 *
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Part whereBinariesId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Part whereMessageid($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Part whereNumber($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Part wherePartnumber($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Part whereSize($value)
 *
 * @mixin \Eloquent
 *
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Part newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Part newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\Part query()
 */
class Part extends Model
{
    /**
     * Indicates if the model should be timestamped.
     *
     * @var bool
     */
    public $timestamps = false;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'binaries_id',
        'messageid',
        'number',
        'partnumber',
        'size',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'binaries_id' => 'integer',
        'number' => 'integer',
        'partnumber' => 'integer',
        'size' => 'integer',
    ];
}
