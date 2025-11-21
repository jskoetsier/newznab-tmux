<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateBookRequest extends FormRequest
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
            'id' => ['required', 'string', 'exists:bookinfo,id'],
            'title' => ['required', 'string', 'max:255'],
            'asin' => ['nullable', 'string', 'max:128'],
            'url' => ['nullable', 'url', 'max:1000'],
            'author' => ['nullable', 'string', 'max:255'],
            'publisher' => ['nullable', 'string', 'max:255'],
            'publishdate' => ['nullable', 'date'],
            'cover' => ['nullable', 'image', 'mimes:jpeg,jpg,png', 'max:2048'],
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
            'asin' => 'ASIN (Amazon Standard Identification Number)',
            'url' => 'book URL',
            'publishdate' => 'publish date',
            'cover' => 'cover image',
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
            'id.required' => 'The book ID is required.',
            'id.exists' => 'The specified book does not exist in the database.',
            'title.required' => 'The book title is required.',
            'url.url' => 'The URL must be a valid URL.',
            'publishdate.date' => 'The publish date must be a valid date.',
            'cover.image' => 'The cover must be a valid image file.',
            'cover.mimes' => 'The cover must be a JPEG or PNG file.',
            'cover.max' => 'The cover image must not exceed 2MB.',
        ];
    }
}
