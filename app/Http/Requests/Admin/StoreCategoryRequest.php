<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class StoreCategoryRequest extends FormRequest
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
            'id' => 'sometimes|integer|unique:categories,id',
            'title' => 'required|string|max:255',
            'root_categories_id' => 'nullable|integer|exists:root_categories,id',
            'description' => 'nullable|string|max:1000',
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
            'title.required' => 'Category title is required',
            'title.max' => 'Category title cannot exceed 255 characters',
            'id.unique' => 'Category ID :input already exists. Please choose a different ID.',
            'root_categories_id.exists' => 'Selected root category does not exist',
        ];
    }
}
