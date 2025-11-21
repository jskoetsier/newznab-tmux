<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Illuminate\Support\Facades\Hash;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AdminUserControllerTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected User $admin;
    protected User $regularUser;
    protected Role $adminRole;
    protected Role $userRole;

    protected function setUp(): void
    {
        parent::setUp();

        // Create roles
        $this->adminRole = Role::create(['name' => 'Admin', 'isdefault' => 0]);
        $this->userRole = Role::create(['name' => 'User', 'isdefault' => 1, 'defaultinvites' => 5]);

        // Create admin user
        $this->admin = User::factory()->create([
            'username' => 'admin',
            'email' => 'admin@example.com',
        ]);
        $this->admin->assignRole('Admin');

        // Create regular user
        $this->regularUser = User::factory()->create([
            'username' => 'testuser',
            'email' => 'user@example.com',
        ]);
        $this->regularUser->assignRole('User');
    }

    /**
     * Test that admin can view user list
     *
     * @return void
     */
    public function test_admin_can_view_user_list(): void
    {
        $this->actingAs($this->admin)
            ->get('/admin/user-list')
            ->assertStatus(200)
            ->assertViewIs('admin.users.index')
            ->assertViewHas('userlist')
            ->assertViewHas('role_ids')
            ->assertViewHas('role_names')
            ->assertViewHas('title', 'User List');
    }

    /**
     * Test that non-admin cannot view user list
     *
     * @return void
     */
    public function test_non_admin_cannot_view_user_list(): void
    {
        $this->actingAs($this->regularUser)
            ->get('/admin/user-list')
            ->assertStatus(403);
    }

    /**
     * Test that unauthenticated user cannot view user list
     *
     * @return void
     */
    public function test_unauthenticated_cannot_view_user_list(): void
    {
        $this->get('/admin/user-list')
            ->assertRedirect('/login');
    }

    /**
     * Test user list with username filter
     *
     * @return void
     */
    public function test_user_list_filters_by_username(): void
    {
        User::factory()->create(['username' => 'searchable']);

        $this->actingAs($this->admin)
            ->get('/admin/user-list?username=searchable')
            ->assertStatus(200)
            ->assertViewHas('username', 'searchable');
    }

    /**
     * Test user list with email filter
     *
     * @return void
     */
    public function test_user_list_filters_by_email(): void
    {
        User::factory()->create(['email' => 'test@search.com']);

        $this->actingAs($this->admin)
            ->get('/admin/user-list?email=test@search.com')
            ->assertStatus(200)
            ->assertViewHas('email', 'test@search.com');
    }

    /**
     * Test user list with role filter
     *
     * @return void
     */
    public function test_user_list_filters_by_role(): void
    {
        $this->actingAs($this->admin)
            ->get('/admin/user-list?role='.$this->userRole->id)
            ->assertStatus(200)
            ->assertViewHas('role', (string) $this->userRole->id);
    }

    /**
     * Test user list pagination
     *
     * @return void
     */
    public function test_user_list_pagination_works(): void
    {
        $this->actingAs($this->admin)
            ->get('/admin/user-list?page=1')
            ->assertStatus(200);
    }

    /**
     * Test admin can view user edit form
     *
     * @return void
     */
    public function test_admin_can_view_user_edit_form(): void
    {
        $this->actingAs($this->admin)
            ->get('/admin/user-edit?id='.$this->regularUser->id)
            ->assertStatus(200)
            ->assertViewIs('admin.users.edit')
            ->assertViewHas('user')
            ->assertViewHas('role_ids')
            ->assertViewHas('role_names');
    }

    /**
     * Test admin can view add user form
     *
     * @return void
     */
    public function test_admin_can_view_add_user_form(): void
    {
        $this->actingAs($this->admin)
            ->get('/admin/user-edit?action=add')
            ->assertStatus(200)
            ->assertViewIs('admin.users.edit')
            ->assertViewHas('user');
    }

    /**
     * Test admin can create a new user
     *
     * @return void
     */
    public function test_admin_can_create_user(): void
    {
        $userData = [
            'action' => 'submit',
            'username' => 'newuser',
            'email' => 'newuser@example.com',
            'password' => 'Password123!',
            'role' => $this->userRole->id,
            'notes' => 'Test user notes',
        ];

        $this->actingAs($this->admin)
            ->post('/admin/user-edit', $userData)
            ->assertRedirect('/admin/user-list');

        $this->assertDatabaseHas('users', [
            'username' => 'newuser',
            'email' => 'newuser@example.com',
        ]);
    }

    /**
     * Test admin cannot create user with existing username
     *
     * @return void
     */
    public function test_admin_cannot_create_user_with_existing_username(): void
    {
        $userData = [
            'action' => 'submit',
            'username' => $this->regularUser->username,
            'email' => 'different@example.com',
            'password' => 'Password123!',
            'role' => $this->userRole->id,
            'notes' => '',
        ];

        $this->actingAs($this->admin)
            ->post('/admin/user-edit', $userData)
            ->assertStatus(200)
            ->assertViewHas('error');
    }

    /**
     * Test admin cannot create user with existing email
     *
     * @return void
     */
    public function test_admin_cannot_create_user_with_existing_email(): void
    {
        $userData = [
            'action' => 'submit',
            'username' => 'differentuser',
            'email' => $this->regularUser->email,
            'password' => 'Password123!',
            'role' => $this->userRole->id,
            'notes' => '',
        ];

        $this->actingAs($this->admin)
            ->post('/admin/user-edit', $userData)
            ->assertStatus(200)
            ->assertViewHas('error');
    }

    /**
     * Test admin can update existing user
     *
     * @return void
     */
    public function test_admin_can_update_user(): void
    {
        $userData = [
            'action' => 'submit',
            'id' => $this->regularUser->id,
            'username' => 'updatedusername',
            'email' => 'updated@example.com',
            'role' => $this->userRole->id,
            'notes' => 'Updated notes',
            'invites' => 10,
            'grabs' => 50,
            'movieview' => 1,
            'musicview' => 1,
            'gameview' => 0,
            'xxxview' => 0,
            'consoleview' => 1,
            'bookview' => 1,
        ];

        $this->actingAs($this->admin)
            ->post('/admin/user-edit', $userData)
            ->assertRedirect('/admin/user-list');

        $this->assertDatabaseHas('users', [
            'id' => $this->regularUser->id,
            'username' => 'updatedusername',
            'email' => 'updated@example.com',
            'movieview' => 1,
            'musicview' => 1,
            'consoleview' => 1,
            'bookview' => 1,
        ]);
    }

    /**
     * Test admin can update user password
     *
     * @return void
     */
    public function test_admin_can_update_user_password(): void
    {
        $newPassword = 'NewPassword123!';

        $userData = [
            'action' => 'submit',
            'id' => $this->regularUser->id,
            'username' => $this->regularUser->username,
            'email' => $this->regularUser->email,
            'password' => $newPassword,
            'role' => $this->userRole->id,
            'notes' => '',
            'invites' => 5,
            'grabs' => 0,
        ];

        $this->actingAs($this->admin)
            ->post('/admin/user-edit', $userData)
            ->assertRedirect('/admin/user-list');

        $this->regularUser->refresh();
        $this->assertTrue(Hash::check($newPassword, $this->regularUser->password));
    }

    /**
     * Test admin can set user role change date
     *
     * @return void
     */
    public function test_admin_can_set_user_role_change_date(): void
    {
        $roleChangeDate = now()->addDays(30)->format('Y-m-d H:i:s');

        $userData = [
            'action' => 'submit',
            'id' => $this->regularUser->id,
            'username' => $this->regularUser->username,
            'email' => $this->regularUser->email,
            'role' => $this->userRole->id,
            'rolechangedate' => $roleChangeDate,
            'notes' => '',
            'invites' => 5,
            'grabs' => 0,
        ];

        $this->actingAs($this->admin)
            ->post('/admin/user-edit', $userData)
            ->assertRedirect('/admin/user-list');

        $this->assertDatabaseHas('users', [
            'id' => $this->regularUser->id,
            'rolechangedate' => $roleChangeDate,
        ]);
    }

    /**
     * Test admin can clear user role change date
     *
     * @return void
     */
    public function test_admin_can_clear_user_role_change_date(): void
    {
        // First set a role change date
        $this->regularUser->update(['rolechangedate' => now()->addDays(30)]);

        $userData = [
            'action' => 'submit',
            'id' => $this->regularUser->id,
            'username' => $this->regularUser->username,
            'email' => $this->regularUser->email,
            'role' => $this->userRole->id,
            'rolechangedate' => '',
            'notes' => '',
            'invites' => 5,
            'grabs' => 0,
        ];

        $this->actingAs($this->admin)
            ->post('/admin/user-edit', $userData)
            ->assertRedirect('/admin/user-list');

        $this->assertDatabaseHas('users', [
            'id' => $this->regularUser->id,
            'rolechangedate' => null,
        ]);
    }

    /**
     * Test admin can delete user
     *
     * @return void
     */
    public function test_admin_can_delete_user(): void
    {
        $userToDelete = User::factory()->create(['username' => 'tobedeleted']);

        $this->actingAs($this->admin)
            ->post('/admin/user-delete', ['id' => $userToDelete->id])
            ->assertRedirect()
            ->assertRedirect('/admin/user-list?deleted=1&username=tobedeleted');

        $this->assertSoftDeleted('users', [
            'id' => $userToDelete->id,
        ]);
    }

    /**
     * Test delete redirects correctly when redir parameter provided
     *
     * @return void
     */
    public function test_delete_redirects_to_specified_location(): void
    {
        $userToDelete = User::factory()->create();

        $this->actingAs($this->admin)
            ->post('/admin/user-delete', [
                'id' => $userToDelete->id,
                'redir' => '/admin/custom-location',
            ])
            ->assertRedirect('/admin/custom-location');
    }

    /**
     * Test delete redirects to referer when no parameters
     *
     * @return void
     */
    public function test_delete_redirects_to_referer_when_no_params(): void
    {
        $this->actingAs($this->admin)
            ->from('/admin/user-list')
            ->post('/admin/user-delete', [])
            ->assertRedirect('/admin/user-list');
    }

    /**
     * Test admin can resend verification email
     *
     * @return void
     */
    public function test_admin_can_resend_verification_email(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/user-resend-verification', ['id' => $this->regularUser->id])
            ->assertRedirect()
            ->assertSessionHas('success');
    }

    /**
     * Test resend verification fails without user id
     *
     * @return void
     */
    public function test_resend_verification_fails_without_user_id(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/user-resend-verification', [])
            ->assertRedirect()
            ->assertSessionHas('error', 'User is invalid');
    }

    /**
     * Test admin can verify user email
     *
     * @return void
     */
    public function test_admin_can_verify_user_email(): void
    {
        $unverifiedUser = User::factory()->create([
            'verified' => 0,
            'email_verified_at' => null,
        ]);

        $this->actingAs($this->admin)
            ->post('/admin/user-verify', ['id' => $unverifiedUser->id])
            ->assertRedirect()
            ->assertSessionHas('success');

        $this->assertDatabaseHas('users', [
            'id' => $unverifiedUser->id,
            'verified' => 1,
        ]);

        $unverifiedUser->refresh();
        $this->assertNotNull($unverifiedUser->email_verified_at);
    }

    /**
     * Test verify fails without user id
     *
     * @return void
     */
    public function test_verify_fails_without_user_id(): void
    {
        $this->actingAs($this->admin)
            ->post('/admin/user-verify', [])
            ->assertRedirect()
            ->assertSessionHas('error', 'User is invalid');
    }

    /**
     * Test non-admin cannot edit users
     *
     * @return void
     */
    public function test_non_admin_cannot_edit_users(): void
    {
        $this->actingAs($this->regularUser)
            ->get('/admin/user-edit?id='.$this->admin->id)
            ->assertStatus(403);
    }

    /**
     * Test non-admin cannot delete users
     *
     * @return void
     */
    public function test_non_admin_cannot_delete_users(): void
    {
        $this->actingAs($this->regularUser)
            ->post('/admin/user-delete', ['id' => $this->admin->id])
            ->assertStatus(403);
    }

    /**
     * Test user edit form displays error messages
     *
     * @return void
     */
    public function test_user_edit_displays_error_messages(): void
    {
        $userData = [
            'action' => 'submit',
            'username' => 'ab', // Too short
            'email' => 'invalid-email',
            'password' => '123', // Too short
            'role' => $this->userRole->id,
            'notes' => '',
        ];

        $this->actingAs($this->admin)
            ->post('/admin/user-edit', $userData)
            ->assertStatus(200)
            ->assertViewHas('error');
    }

    /**
     * Test user list ordering works
     *
     * @return void
     */
    public function test_user_list_ordering_works(): void
    {
        $this->actingAs($this->admin)
            ->get('/admin/user-list?ob=username_asc')
            ->assertStatus(200);

        $this->actingAs($this->admin)
            ->get('/admin/user-list?ob=email_desc')
            ->assertStatus(200);
    }

    /**
     * Test admin can update user views preferences
     *
     * @return void
     */
    public function test_admin_can_update_user_view_preferences(): void
    {
        $userData = [
            'action' => 'submit',
            'id' => $this->regularUser->id,
            'username' => $this->regularUser->username,
            'email' => $this->regularUser->email,
            'role' => $this->userRole->id,
            'notes' => '',
            'invites' => 5,
            'grabs' => 0,
            'movieview' => 1,
            'musicview' => 0,
            'gameview' => 1,
            'xxxview' => 0,
            'consoleview' => 0,
            'bookview' => 1,
        ];

        $this->actingAs($this->admin)
            ->post('/admin/user-edit', $userData)
            ->assertRedirect('/admin/user-list');

        $this->assertDatabaseHas('users', [
            'id' => $this->regularUser->id,
            'movieview' => 1,
            'musicview' => 0,
            'gameview' => 1,
            'xxxview' => 0,
            'consoleview' => 0,
            'bookview' => 1,
        ]);
    }

    /**
     * Test created_from and created_to date filters
     *
     * @return void
     */
    public function test_user_list_filters_by_created_date_range(): void
    {
        $this->actingAs($this->admin)
            ->get('/admin/user-list?created_from=2024-01-01&created_to=2024-12-31')
            ->assertStatus(200)
            ->assertViewHas('created_from', '2024-01-01')
            ->assertViewHas('created_to', '2024-12-31');
    }
}
