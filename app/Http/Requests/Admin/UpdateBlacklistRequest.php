<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateBlacklistRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->hasRole('Admin');
    }

    public function rules(): array
    {
        return [
            'id' => ['required', 'integer', 'exists:binaryblacklist,id'],
            'groupname' => ['required', 'string', 'max:255'],
            'regex' => ['required', 'string', 'max:2000'],
            'status' => ['required', 'boolean'],
            'description' => ['nullable', 'string', 'max:1000'],
            'optype' => ['required', 'integer', 'in:1,2'],
            'msgcol' => ['required', 'integer', 'in:1,2,3'],
        ];
    }

    public function attributes(): array
    {
        return [
            'groupname' => 'usenet group',
            'optype' => 'operation type',
            'msgcol' => 'message column',
        ];
    }

    public function messages(): array
    {
        return [
            'id.required' => 'The blacklist ID is required.',
            'id.exists' => 'The specified blacklist entry does not exist.',
            'groupname.required' => 'The usenet group name is required.',
            'regex.required' => 'The regex pattern is required.',
            'status.required' => 'The status must be selected.',
            'optype.required' => 'The operation type must be selected (Black or White).',
            'optype.in' => 'Invalid operation type. Must be Black or White.',
            'msgcol.required' => 'The message column must be selected.',
            'msgcol.in' => 'Invalid message column. Must be Subject, Poster, or MessageId.',
        ];
    }
}
