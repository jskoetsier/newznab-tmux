<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreGroupRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize(): bool
    {
        return $this->user()?->hasRole('Admin') ?? false;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255|unique:usenet_groups,name',
            'description' => 'nullable|string|max:1000',
            'minfilestoformrelease' => 'nullable|integer|min:0',
            'active' => 'nullable|boolean',
            'backfill' => 'nullable|boolean',
            'minsizetoformrelease' => 'nullable|integer|min:0',
            'backfill_target' => 'nullable|integer|min:0',
        ];
    }

    /**
     * Get custom messages for validator errors.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'name.required' => 'Group name is required',
            'name.unique' => 'This newsgroup already exists',
            'minfilestoformrelease.min' => 'Minimum files must be 0 or greater',
            'minsizetoformrelease.min' => 'Minimum size must be 0 or greater',
            'backfill_target.min' => 'Backfill target must be 0 or greater',
        ];
    }
}
