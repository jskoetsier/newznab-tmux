<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReleaseInform extends Model
{
    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'relOName',
        'relPName',
        'api_token',
    ];
}
