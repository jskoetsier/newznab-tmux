<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateReleaseRequest extends FormRequest
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
            'id' => ['required', 'integer', 'exists:releases,id'],
            'name' => ['required', 'string', 'max:255'],
            'searchname' => ['required', 'string', 'max:255'],
            'fromname' => ['nullable', 'string', 'max:255'],
            'categories_id' => ['required', 'integer', 'exists:categories,id'],
            'size' => ['nullable', 'integer', 'min:0'],
            'totalpart' => ['nullable', 'integer', 'min:0'],
            'completion' => ['nullable', 'numeric', 'min:0', 'max:100'],
            'grabs' => ['nullable', 'integer', 'min:0'],
            'passwordstatus' => ['nullable', 'integer', 'in:-1,0,1,2,10'],
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
            'categories_id' => 'category',
            'totalpart' => 'total parts',
            'passwordstatus' => 'password status',
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
            'id.required' => 'The release ID is required.',
            'id.exists' => 'The specified release does not exist in the database.',
            'name.required' => 'The release name is required.',
            'searchname.required' => 'The search name is required.',
            'categories_id.required' => 'A category must be selected.',
            'categories_id.exists' => 'The selected category does not exist.',
            'size.min' => 'The size must be a positive number.',
            'totalpart.min' => 'The total parts must be a positive number.',
            'completion.min' => 'The completion percentage must be between 0 and 100.',
            'completion.max' => 'The completion percentage must be between 0 and 100.',
            'grabs.min' => 'The grabs count must be a positive number.',
            'passwordstatus.in' => 'Invalid password status value.',
        ];
    }
}
