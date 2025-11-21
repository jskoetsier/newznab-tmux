<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateGameRequest extends FormRequest
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
            'id' => ['required', 'integer', 'exists:gamesinfo,id'],
            'title' => ['required', 'string', 'max:255'],
            'asin' => ['nullable', 'string', 'max:128'],
            'url' => ['nullable', 'url', 'max:1000'],
            'publisher' => ['nullable', 'string', 'max:255'],
            'releasedate' => ['nullable', 'date'],
            'esrb' => ['nullable', 'string', 'max:50'],
            'trailerurl' => ['nullable', 'url', 'max:1000'],
            'genre' => ['nullable', 'integer', 'exists:genres,id'],
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
            'url' => 'game URL',
            'releasedate' => 'release date',
            'esrb' => 'ESRB rating',
            'trailerurl' => 'trailer URL',
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
            'id.required' => 'The game ID is required.',
            'id.exists' => 'The specified game does not exist in the database.',
            'title.required' => 'The game title is required.',
            'url.url' => 'The URL must be a valid URL.',
            'trailerurl.url' => 'The trailer URL must be a valid URL.',
            'releasedate.date' => 'The release date must be a valid date.',
            'genre.exists' => 'The selected genre does not exist.',
            'cover.image' => 'The cover must be a valid image file.',
            'cover.mimes' => 'The cover must be a JPEG or PNG file.',
            'cover.max' => 'The cover image must not exceed 2MB.',
        ];
    }
}
