<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateUserRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Only admins can update users
        return $this->user()?->hasRole('Admin') ?? false;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        $userId = $this->route('id') ?? $this->input('id');

        return [
            'id' => ['required', 'integer', 'exists:users,id'],
            'username' => [
                'required',
                'string',
                'min:5',
                'max:255',
                Rule::unique('users')->ignore($userId),
            ],
            'email' => [
                'required',
                'string',
                'email',
                'max:255',
                Rule::unique('users')->ignore($userId),
            ],
            'grabs' => ['required', 'integer', 'min:0'],
            'roles_id' => ['required', 'integer', 'exists:roles,id'],
            'notes' => ['nullable', 'string', 'max:255'],
            'invites' => ['required', 'integer', 'min:0'],
            'movieview' => ['required', 'boolean'],
            'musicview' => ['required', 'boolean'],
            'gameview' => ['required', 'boolean'],
            'xxxview' => ['required', 'boolean'],
            'consoleview' => ['required', 'boolean'],
            'bookview' => ['required', 'boolean'],
            'style' => ['nullable', 'string', 'max:50'],
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
            'username.required' => 'A username is required.',
            'username.min' => 'Username must be at least 5 characters.',
            'username.unique' => 'This username is already taken.',
            'email.required' => 'An email address is required.',
            'email.email' => 'Please provide a valid email address.',
            'email.unique' => 'This email address is already in use.',
            'roles_id.exists' => 'The selected role does not exist.',
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
            'roles_id' => 'role',
            'movieview' => 'movie view',
            'musicview' => 'music view',
            'gameview' => 'game view',
            'xxxview' => 'adult content view',
            'consoleview' => 'console view',
            'bookview' => 'book view',
        ];
    }
}
