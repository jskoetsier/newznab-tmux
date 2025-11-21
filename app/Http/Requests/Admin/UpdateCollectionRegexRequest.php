<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateCollectionRegexRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->hasRole('Admin');
    }

    public function rules(): array
    {
        return [
            'id' => ['required', 'integer', 'exists:collection_regexes,id'],
            'group_regex' => ['required', 'string', 'max:255'],
            'regex' => ['required', 'string', 'max:5000'],
            'status' => ['required', 'boolean'],
            'description' => ['nullable', 'string', 'max:1000'],
            'ordinal' => ['required', 'integer', 'min:0'],
        ];
    }

    public function attributes(): array
    {
        return [
            'group_regex' => 'group regex pattern',
        ];
    }

    public function messages(): array
    {
        return [
            'id.required' => 'The collection regex ID is required.',
            'id.exists' => 'The specified collection regex does not exist.',
            'group_regex.required' => 'The group regex pattern is required.',
            'regex.required' => 'The regex pattern is required.',
            'ordinal.min' => 'The ordinal must be 0 or higher.',
        ];
    }
}
