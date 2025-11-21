<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreRoleRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return $this->user()->hasRole('Admin');
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255', 'unique:roles,name'],
            'apirequests' => ['required', 'integer', 'min:0'],
            'downloadrequests' => ['required', 'integer', 'min:0'],
            'defaultinvites' => ['required', 'integer', 'min:0'],
            'donation' => ['nullable', 'numeric', 'min:0'],
            'addyears' => ['nullable', 'integer', 'min:0'],
            'rate_limit' => ['required', 'integer', 'min:0'],
            'canpreview' => ['nullable', 'boolean'],
            'hideads' => ['nullable', 'boolean'],
            'editrelease' => ['nullable', 'boolean'],
            'viewconsole' => ['nullable', 'boolean'],
            'viewmovies' => ['nullable', 'boolean'],
            'viewaudio' => ['nullable', 'boolean'],
            'viewpc' => ['nullable', 'boolean'],
            'viewtv' => ['nullable', 'boolean'],
            'viewadult' => ['nullable', 'boolean'],
            'viewbooks' => ['nullable', 'boolean'],
            'viewother' => ['nullable', 'boolean'],
        ];
    }

    /**
     * Get custom attributes for validator errors.
     *
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'apirequests' => 'API requests limit',
            'downloadrequests' => 'download requests limit',
            'defaultinvites' => 'default invites',
            'canpreview' => 'preview permission',
            'hideads' => 'hide ads permission',
            'editrelease' => 'edit release permission',
            'viewconsole' => 'view console permission',
            'viewmovies' => 'view movies permission',
            'viewaudio' => 'view audio permission',
            'viewpc' => 'view PC permission',
            'viewtv' => 'view TV permission',
            'viewadult' => 'view adult permission',
            'viewbooks' => 'view books permission',
            'viewother' => 'view other permission',
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
            'name.required' => 'The role name is required.',
            'name.unique' => 'A role with this name already exists.',
            'apirequests.required' => 'The API requests limit is required.',
            'downloadrequests.required' => 'The download requests limit is required.',
            'rate_limit.required' => 'The rate limit is required.',
        ];
    }
}
