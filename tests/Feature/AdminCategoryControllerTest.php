<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\RootCategory;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AdminCategoryControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $admin;
    protected Role $adminRole;

    protected function setUp(): void
    {
        parent::setUp();

        // Create admin role
        $this->adminRole = Role::create(['name' => 'Admin']);

        // Create admin user
        $this->admin = User::factory()->create();
        $this->admin->assignRole('Admin');
    }

    /**
     * Test that admin can view category list
     *
     * @return void
     */
    public function test_admin_can_view_category_list(): void
    {
        $this->actingAs($this->admin)
            ->get('/admin/category-list')
            ->assertStatus(200)
            ->assertViewIs('admin.categories.index')
            ->assertViewHas('categorylist');
    }

    /**
     * Test that non-admin cannot view category list
     *
     * @return void
     */
    public function test_non_admin_cannot_view_category_list(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->get('/admin/category-list')
            ->assertStatus(403);
    }

    /**
     * Test that admin can create a category
     *
     * @return void
     */
    public function test_admin_can_create_category(): void
    {
        $rootCategory = RootCategory::factory()->create();

        $data = [
            'action' => 'submit',
            'title' => 'Test Category',
            'root_categories_id' => $rootCategory->id,
            'description' => 'Test description',
        ];

        $this->actingAs($this->admin)
            ->post('/admin/category-add', $data)
            ->assertRedirect('/admin/category-list')
            ->assertSessionHas('success');

        $this->assertDatabaseHas('categories', [
            'title' => 'Test Category',
            'root_categories_id' => $rootCategory->id,
        ]);
    }

    /**
     * Test that category creation requires title
     *
     * @return void
     */
    public function test_category_creation_requires_title(): void
    {
        $data = [
            'action' => 'submit',
            'root_categories_id' => 1,
        ];

        $this->actingAs($this->admin)
            ->post('/admin/category-add', $data)
            ->assertSessionHasErrors('title');
    }

    /**
     * Test that admin can update a category
     *
     * @return void
     */
    public function test_admin_can_update_category(): void
    {
        $rootCategory = RootCategory::factory()->create();
        $category = Category::factory()->create([
            'root_categories_id' => $rootCategory->id,
        ]);

        $data = [
            'action' => 'submit',
            'id' => $category->id,
            'description' => 'Updated description',
            'root_categories_id' => $rootCategory->id,
        ];

        $this->actingAs($this->admin)
            ->post('/admin/category-edit', $data)
            ->assertRedirect('/admin/category-list')
            ->assertSessionHas('success');

        $this->assertDatabaseHas('categories', [
            'id' => $category->id,
            'description' => 'Updated description',
        ]);
    }

    /**
     * Test that category cannot have duplicate custom ID
     *
     * @return void
     */
    public function test_category_cannot_have_duplicate_custom_id(): void
    {
        $existingCategory = Category::factory()->create(['id' => 9999]);

        $data = [
            'action' => 'submit',
            'id' => 9999,
            'title' => 'Another Category',
            'root_categories_id' => 1,
        ];

        $this->actingAs($this->admin)
            ->post('/admin/category-add', $data)
            ->assertRedirect()
            ->assertSessionHasErrors();
    }
}
