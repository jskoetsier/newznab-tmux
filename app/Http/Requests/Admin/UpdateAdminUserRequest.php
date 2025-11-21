<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateAdminUserRequest extends FormRequest
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
        $userId = $this->input('id');

        return [
            'id' => 'required|integer|exists:users,id',
            'username' => [
                'required',
                'string',
                'max:255',
                Rule::unique('users', 'username')->ignore($userId),
            ],
            'email' => [
                'required',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($userId),
            ],
            'password' => 'nullable|string|min:8',
            'role' => 'required|integer|exists:roles,id',
            'notes' => 'nullable|string|max:1000',
            'invites' => 'nullable|integer|min:0',
            'grabs' => 'nullable|integer|min:0',
            'rolechangedate' => 'nullable|date',
            'rate_limit' => 'nullable|integer|min:0|max:1000',
            'movieview' => 'nullable|boolean',
            'musicview' => 'nullable|boolean',
            'gameview' => 'nullable|boolean',
            'xxxview' => 'nullable|boolean',
            'consoleview' => 'nullable|boolean',
            'bookview' => 'nullable|boolean',
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
            'id.required' => 'User ID is required',
            'id.exists' => 'User not found',
            'username.required' => 'Username is required',
            'username.unique' => 'Username is already taken',
            'email.required' => 'Email address is required',
            'email.email' => 'Please provide a valid email address',
            'email.unique' => 'Email is already in use',
            'password.min' => 'Password must be at least 8 characters',
            'role.required' => 'Role is required',
            'role.exists' => 'Selected role does not exist',
        ];
    }
}
