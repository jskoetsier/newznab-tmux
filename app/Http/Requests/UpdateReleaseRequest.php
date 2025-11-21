<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateReleaseRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        // Only admins can update releases
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
            'id' => ['required', 'integer', 'exists:releases,id'],
            'name' => ['required', 'string', 'max:255'],
            'searchname' => ['required', 'string', 'max:255'],
            'fromname' => ['nullable', 'string', 'max:255'],
            'categories_id' => ['required', 'integer', 'exists:categories,id'],
            'totalpart' => ['nullable', 'integer', 'min:0'],
            'groups_id' => ['required', 'integer', 'exists:groups,id'],
            'adddate' => ['nullable', 'date'],
            'postdate' => ['nullable', 'date'],
            'dehashstatus' => ['nullable', 'integer', 'between:0,1'],
            'reqidstatus' => ['nullable', 'integer', 'between:0,1'],
            'passwordstatus' => ['nullable', 'integer', 'between:-1,10'],
            'rarinnerfilecount' => ['nullable', 'integer', 'min:0'],
            'haspreview' => ['nullable', 'integer', 'between:-1,2'],
            'nfostatus' => ['nullable', 'integer', 'between:0,1'],
            'jpgstatus' => ['nullable', 'integer', 'between:0,1'],
            'videostatus' => ['nullable', 'integer', 'between:0,2'],
            'audiostatus' => ['nullable', 'integer', 'between:0,1'],
            'musicinfoid' => ['nullable', 'integer'],
            'consoleinfoid' => ['nullable', 'integer'],
            'bookinfoid' => ['nullable', 'integer'],
            'videos_id' => ['nullable', 'integer'],
            'tv_episodes_id' => ['nullable', 'integer'],
            'imdbid' => ['nullable', 'integer'],
            'xxxinfo_id' => ['nullable', 'integer'],
            'size' => ['nullable', 'integer', 'min:0'],
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
            'name.required' => 'Release name is required.',
            'searchname.required' => 'Search name is required.',
            'categories_id.required' => 'Category is required.',
            'categories_id.exists' => 'The selected category does not exist.',
            'groups_id.required' => 'Group is required.',
            'groups_id.exists' => 'The selected group does not exist.',
            'passwordstatus.between' => 'Password status must be between -1 and 10.',
            'size.min' => 'Size must be a positive number.',
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
            'groups_id' => 'group',
            'totalpart' => 'total parts',
            'adddate' => 'add date',
            'postdate' => 'post date',
            'dehashstatus' => 'dehash status',
            'reqidstatus' => 'request ID status',
            'passwordstatus' => 'password status',
            'rarinnerfilecount' => 'RAR inner file count',
            'haspreview' => 'preview status',
            'nfostatus' => 'NFO status',
            'jpgstatus' => 'JPG status',
            'videostatus' => 'video status',
            'audiostatus' => 'audio status',
            'musicinfoid' => 'music info ID',
            'consoleinfoid' => 'console info ID',
            'bookinfoid' => 'book info ID',
            'videos_id' => 'video ID',
            'tv_episodes_id' => 'TV episode ID',
            'imdbid' => 'IMDB ID',
            'xxxinfo_id' => 'adult content info ID',
        ];
    }
}
