<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateAnidbRequest extends FormRequest
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
            'id' => ['required', 'integer', 'exists:anidb_info,anidbid'],
            'type' => ['nullable', 'string', 'max:50'],
            'startdate' => ['nullable', 'date'],
            'enddate' => ['nullable', 'date', 'after_or_equal:startdate'],
            'rating' => ['nullable', 'string', 'max:10'],
            'title' => ['nullable', 'string', 'max:255'],
            'creators' => ['nullable', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:5000'],
            'url' => ['nullable', 'url', 'max:1000'],
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
            'anidbid' => 'AniDB ID',
            'startdate' => 'start date',
            'enddate' => 'end date',
            'url' => 'AniDB URL',
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
            'id.required' => 'The AniDB ID is required.',
            'id.exists' => 'The specified anime does not exist in the database.',
            'startdate.date' => 'The start date must be a valid date.',
            'enddate.date' => 'The end date must be a valid date.',
            'enddate.after_or_equal' => 'The end date must be after or equal to the start date.',
            'url.url' => 'The URL must be a valid URL.',
        ];
    }
}
