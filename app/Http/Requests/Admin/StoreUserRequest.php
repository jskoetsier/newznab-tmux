<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreUserRequest extends FormRequest
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
            'username' => 'required|string|max:255|unique:users,username',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => 'required|string|min:8',
            'role' => 'required|integer|exists:roles,id',
            'notes' => 'nullable|string|max:1000',
            'invites' => 'nullable|integer|min:0',
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
            'username.required' => 'Username is required',
            'username.unique' => 'Username is already taken',
            'email.required' => 'Email address is required',
            'email.email' => 'Please provide a valid email address',
            'email.unique' => 'Email is already in use',
            'password.required' => 'Password is required',
            'password.min' => 'Password must be at least 8 characters',
            'role.required' => 'Role is required',
            'role.exists' => 'Selected role does not exist',
        ];
    }
}
