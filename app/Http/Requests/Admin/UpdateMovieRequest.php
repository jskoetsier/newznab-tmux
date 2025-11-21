<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateMovieRequest extends FormRequest
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
            'id' => ['required', 'integer', 'exists:movieinfo,imdbid'],
            'title' => ['required', 'string', 'max:255'],
            'year' => ['nullable', 'integer', 'min:1800', 'max:'.(date('Y') + 5)],
            'tagline' => ['nullable', 'string', 'max:500'],
            'plot' => ['nullable', 'string', 'max:5000'],
            'rating' => ['nullable', 'numeric', 'min:0', 'max:10'],
            'genre' => ['nullable', 'string', 'max:255'],
            'director' => ['nullable', 'string', 'max:255'],
            'actors' => ['nullable', 'string', 'max:2000'],
            'language' => ['nullable', 'string', 'max:50'],
            'cover' => ['nullable', 'image', 'mimes:jpeg,jpg,png', 'max:2048'],
            'backdrop' => ['nullable', 'image', 'mimes:jpeg,jpg,png', 'max:4096'],
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
            'id' => 'IMDB ID',
            'plot' => 'plot summary',
            'rating' => 'IMDB rating',
            'cover' => 'cover image',
            'backdrop' => 'backdrop image',
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
            'id.required' => 'The IMDB ID is required.',
            'id.exists' => 'The specified movie does not exist in the database.',
            'title.required' => 'The movie title is required.',
            'year.min' => 'The year must be a valid year (1800 or later).',
            'year.max' => 'The year cannot be more than 5 years in the future.',
            'rating.min' => 'The rating must be between 0 and 10.',
            'rating.max' => 'The rating must be between 0 and 10.',
            'cover.image' => 'The cover must be a valid image file.',
            'cover.mimes' => 'The cover must be a JPEG or PNG file.',
            'cover.max' => 'The cover image must not exceed 2MB.',
            'backdrop.image' => 'The backdrop must be a valid image file.',
            'backdrop.mimes' => 'The backdrop must be a JPEG or PNG file.',
            'backdrop.max' => 'The backdrop image must not exceed 4MB.',
        ];
    }
}
