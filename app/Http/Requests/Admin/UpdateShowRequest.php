<?php

namespace App\Http\Requests\Admin;

use Illuminate\Foundation\Http\FormRequest;

class UpdateShowRequest extends FormRequest
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
            'id' => ['required', 'integer', 'exists:tv_info,id'],
            'title' => ['nullable', 'string', 'max:255'],
            'country' => ['nullable', 'string', 'max:2'],
            'started' => ['nullable', 'date'],
            'ended' => ['nullable', 'date', 'after_or_equal:started'],
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
            'started' => 'start date',
            'ended' => 'end date',
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
            'id.required' => 'The TV show ID is required.',
            'id.exists' => 'The specified TV show does not exist in the database.',
            'country.max' => 'The country code must be 2 characters (e.g., US, UK).',
            'started.date' => 'The start date must be a valid date.',
            'ended.date' => 'The end date must be a valid date.',
            'ended.after_or_equal' => 'The end date must be after or equal to the start date.',
        ];
    }
}
