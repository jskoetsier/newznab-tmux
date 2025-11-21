<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * App\Models\RoleExpirationEmail.
 *
 * @property int $id
 * @property int $users_id
 * @property \Illuminate\Support\Carbon|null $created_at
 * @property \Illuminate\Support\Carbon|null $updated_at
 * @property int $day
 * @property int $week
 * @property int $month
 * @property-read User $user
 *
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\RoleExpirationEmail newModelQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\RoleExpirationEmail newQuery()
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\RoleExpirationEmail query()
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\RoleExpirationEmail whereCreatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\RoleExpirationEmail whereDay($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\RoleExpirationEmail whereId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\RoleExpirationEmail whereMonth($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\RoleExpirationEmail whereUpdatedAt($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\RoleExpirationEmail whereUsersId($value)
 * @method static \Illuminate\Database\Eloquent\Builder|\App\Models\RoleExpirationEmail whereWeek($value)
 *
 * @mixin \Eloquent
 */
class RoleExpirationEmail extends Model
{
    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'users_id',
        'day',
        'week',
        'month',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'users_id' => 'integer',
        'day' => 'integer',
        'week' => 'integer',
        'month' => 'integer',
    ];

    public function user(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(User::class, 'users_id');
    }
}
