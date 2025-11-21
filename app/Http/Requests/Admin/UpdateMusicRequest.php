<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateMusicRequest extends FormRequest
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
            'id' => ['required', 'integer', 'exists:musicinfo,id'],
            'title' => ['required', 'string', 'max:255'],
            'asin' => ['nullable', 'string', 'max:128'],
            'url' => ['nullable', 'url', 'max:1000'],
            'publisher' => ['nullable', 'string', 'max:255'],
            'releasedate' => ['nullable', 'date'],
            'year' => ['nullable', 'integer', 'min:1900', 'max:'.(date('Y') + 2)],
            'genre' => ['nullable', 'integer', 'exists:genres,id'],
            'tracks' => ['nullable', 'string', 'max:5000'],
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
            'asin' => 'ASIN',
            'url' => 'album URL',
            'releasedate' => 'release date',
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
            'id.required' => 'The music album ID is required.',
            'id.exists' => 'The specified music album does not exist in the database.',
            'title.required' => 'The album title is required.',
            'url.url' => 'The URL must be a valid URL.',
            'releasedate.date' => 'The release date must be a valid date.',
            'year.min' => 'The year must be 1900 or later.',
            'year.max' => 'The year cannot be more than 2 years in the future.',
            'genre.exists' => 'The selected genre does not exist.',
            'cover.image' => 'The cover must be a valid image file.',
            'cover.mimes' => 'The cover must be a JPEG or PNG file.',
            'cover.max' => 'The cover image must not exceed 2MB.',
        ];
    }
}
