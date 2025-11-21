<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreContentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->hasRole('Admin');
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'url' => ['nullable', 'string', 'max:2000'],
            'body' => ['nullable', 'string'],
            'metadescription' => ['nullable', 'string', 'max:1000'],
            'metakeywords' => ['nullable', 'string', 'max:1000'],
            'contenttype' => ['required', 'integer', 'in:1,2,3'],
            'status' => ['required', 'boolean'],
            'ordinal' => ['nullable', 'integer', 'min:0'],
            'role' => ['required', 'integer', 'in:1,2,3'],
        ];
    }

    public function attributes(): array
    {
        return [
            'metadescription' => 'meta description',
            'metakeywords' => 'meta keywords',
            'contenttype' => 'content type',
        ];
    }

    public function messages(): array
    {
        return [
            'title.required' => 'The content title is required.',
            'contenttype.required' => 'The content type must be selected.',
            'contenttype.in' => 'Invalid content type. Must be Useful Link, Article, or Homepage.',
            'status.required' => 'The status must be selected.',
            'role.required' => 'The access role must be selected.',
            'role.in' => 'Invalid role. Must be Everyone, Logged in Users, or Admins.',
            'ordinal.min' => 'The ordinal must be 0 or higher.',
        ];
    }
}
