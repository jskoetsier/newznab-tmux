# NNTmux Development Guide

> **Last Updated**: November 21, 2025
> **Version**: 2.0.0

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Environment Setup](#development-environment-setup)
3. [Project Structure](#project-structure)
4. [Coding Standards](#coding-standards)
5. [Testing Guidelines](#testing-guidelines)
6. [Database Development](#database-development)
7. [API Development](#api-development)
8. [Frontend Development](#frontend-development)
9. [Debugging](#debugging)
10. [Contributing](#contributing)
11. [Release Process](#release-process)

---

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **PHP**: 8.3 or higher
- **Composer**: Latest version
- **Node.js**: 18.x or higher
- **npm**: 9.x or higher
- **MySQL/MariaDB**: 8.0+ / 10.11+
- **Redis**: 7.0+
- **Git**: Latest version

### Quick Start

```bash
# Clone the repository
git clone https://github.com/NNTmux/newznab-tmux.git
cd newznab-tmux

# Install PHP dependencies
composer install

# Install JavaScript dependencies
npm install

# Copy environment file
cp .env.example .env

# Generate application key
php artisan key:generate

# Configure your .env file with database credentials
# Then run migrations
php artisan migrate

# Seed the database (optional)
php artisan db:seed

# Start development server
php artisan serve

# In another terminal, start Vite
npm run dev
```

Visit `http://localhost:8000` to see your application.

---

## Development Environment Setup

### Recommended IDE Setup

#### VS Code (Recommended)

**Essential Extensions:**
```json
{
  "recommendations": [
    "bmewburn.vscode-intelephense-client",
    "xdebug.php-debug",
    "bradlc.vscode-tailwindcss",
    "vue.volar",
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode"
  ]
}
```

**Workspace Settings:**
```json
{
  "php.validate.executablePath": "/usr/bin/php",
  "php.suggest.basic": false,
  "intelephense.stubs": [
    "apache",
    "bcmath",
    "Core",
    "ctype",
    "curl",
    "date",
    "dom",
    "fileinfo",
    "filter",
    "gd",
    "hash",
    "iconv",
    "json",
    "libxml",
    "mbstring",
    "mysqli",
    "mysqlnd",
    "openssl",
    "pcre",
    "PDO",
    "pdo_mysql",
    "Phar",
    "redis",
    "Reflection",
    "session",
    "SimpleXML",
    "standard",
    "tokenizer",
    "xml",
    "xmlreader",
    "xmlwriter",
    "zip",
    "zlib"
  ]
}
```

#### PHPStorm

1. Install Laravel Idea plugin
2. Configure PHP interpreter
3. Enable Composer synchronization
4. Configure Node.js interpreter

### Docker Development Environment

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - .:/var/www/html
    ports:
      - "8000:8000"
    environment:
      - APP_ENV=local
      - APP_DEBUG=true
    depends_on:
      - mysql
      - redis

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: nntmux
      MYSQL_USER: nntmux
      MYSQL_PASSWORD: secret
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  mysql_data:
```

**Start Development Environment:**
```bash
docker-compose -f docker-compose.dev.yml up -d
docker-compose exec app php artisan migrate
docker-compose exec app npm run dev
```

---

## Project Structure

```
newznab-tmux/
├── app/                      # Application core
│   ├── Console/             # Artisan commands
│   │   └── Commands/        # Custom commands
│   ├── Events/              # Event classes
│   ├── Exceptions/          # Exception handlers
│   ├── Http/                # HTTP layer
│   │   ├── Controllers/     # Controllers
│   │   │   ├── Admin/      # Admin controllers
│   │   │   ├── Api/        # API controllers
│   │   │   └── Auth/       # Authentication controllers
│   │   ├── Middleware/      # Middleware
│   │   └── Requests/        # Form Requests
│   │       └── Admin/      # Admin form requests
│   ├── Jobs/                # Queued jobs
│   ├── Listeners/           # Event listeners
│   ├── Livewire/            # Livewire components
│   ├── Mail/                # Email classes
│   ├── Models/              # Eloquent models
│   ├── Observers/           # Model observers
│   ├── Policies/            # Authorization policies
│   ├── Providers/           # Service providers
│   ├── Rules/               # Validation rules
│   ├── Services/            # Business logic services
│   └── Transformers/        # API transformers
├── Blacklight/              # Legacy core (being refactored)
│   ├── NNTP.php            # NNTP functionality
│   ├── Binaries.php        # Binary processing
│   ├── Releases.php        # Release management
│   └── processing/         # Processing classes
├── bootstrap/               # Bootstrap files
├── config/                  # Configuration files
├── database/                # Database files
│   ├── factories/          # Model factories
│   ├── migrations/         # Database migrations
│   └── seeders/            # Database seeders
├── public/                  # Public web root
│   ├── assets/             # Static assets
│   └── index.php           # Entry point
├── resources/               # Frontend resources
│   ├── css/                # Stylesheets
│   ├── js/                 # JavaScript
│   └── views/              # Blade templates
│       ├── admin/          # Admin views
│       ├── auth/           # Auth views
│       ├── components/     # Blade components
│       ├── layouts/        # Layout templates
│       └── livewire/       # Livewire views
├── routes/                  # Route definitions
│   ├── api.php             # API routes
│   ├── console.php         # Console routes
│   └── web.php             # Web routes
├── scripts/                 # Utility scripts
├── storage/                 # Storage directory
│   ├── app/                # Application storage
│   ├── framework/          # Framework cache
│   └── logs/               # Log files
├── tests/                   # Test files
│   ├── Feature/            # Feature tests
│   └── Unit/               # Unit tests
├── .env.example            # Environment template
├── artisan                 # Artisan CLI
├── composer.json           # PHP dependencies
├── package.json            # Node dependencies
├── phpunit.xml             # PHPUnit configuration
├── rector.php              # Rector configuration
└── vite.config.js          # Vite configuration
```

---

## Coding Standards

### PHP Coding Standards

We follow **PSR-12** coding standards with Laravel conventions.

#### Code Style

**Use Laravel Pint for automatic formatting:**
```bash
# Format all files
./vendor/bin/pint

# Format specific files
./vendor/bin/pint app/Models/User.php

# Check without fixing
./vendor/bin/pint --test
```

#### Naming Conventions

```php
// Classes: PascalCase
class UserController extends Controller {}

// Methods: camelCase
public function getUserProfile() {}

// Variables: camelCase
$userEmail = 'user@example.com';

// Constants: SCREAMING_SNAKE_CASE
public const MAX_LOGIN_ATTEMPTS = 5;

// Database tables: snake_case (plural)
// Table: users, release_files, user_downloads

// Model properties: snake_case
protected $fillable = ['user_name', 'email_address'];

// Route names: kebab-case with dots
Route::get('/admin/user-list', [AdminUserController::class, 'index'])
    ->name('admin.users.index');
```

#### Type Declarations

Always use type declarations:

```php
// Good
public function createUser(string $username, string $email): User
{
    // ...
}

// Bad
public function createUser($username, $email)
{
    // ...
}
```

#### Documentation

Use PHPDoc blocks for all public methods:

```php
/**
 * Create a new user account.
 *
 * @param  string  $username  The username for the new account
 * @param  string  $email  The email address
 * @param  string  $password  The unhashed password
 * @return User The created user model
 *
 * @throws \InvalidArgumentException If username already exists
 */
public function createUser(string $username, string $email, string $password): User
{
    // Implementation
}
```

### Static Analysis

**Use PHPStan for static analysis:**
```bash
# Run PHPStan
./vendor/bin/phpstan analyse

# Run with specific level
./vendor/bin/phpstan analyse --level=5
```

### JavaScript Coding Standards

**Use ESLint and Prettier:**
```bash
# Lint JavaScript
npm run lint

# Fix linting issues
npm run lint:fix

# Format with Prettier
npm run format
```

---

## Testing Guidelines

### Test Structure

```
tests/
├── Feature/                 # Feature/Integration tests
│   ├── Admin/              # Admin feature tests
│   ├── Api/                # API feature tests
│   └── Auth/               # Authentication tests
└── Unit/                    # Unit tests
    ├── Models/             # Model unit tests
    ├── Services/           # Service unit tests
    └── Helpers/            # Helper unit tests
```

### Writing Tests

#### Feature Test Example

```php
<?php

namespace Tests\Feature\Admin;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class AdminCategoryControllerTest extends TestCase
{
    use RefreshDatabase;

    protected User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        // Create admin role
        Role::create(['name' => 'Admin']);

        // Create admin user
        $this->admin = User::factory()->create();
        $this->admin->assignRole('Admin');
    }

    public function test_admin_can_view_category_list(): void
    {
        $this->actingAs($this->admin)
            ->get('/admin/category-list')
            ->assertStatus(200)
            ->assertViewIs('admin.categories.index');
    }
}
```

#### Unit Test Example

```php
<?php

namespace Tests\Unit\Models;

use App\Models\Category;
use Tests\TestCase;

class CategoryTest extends TestCase
{
    public function test_category_has_correct_fillable_attributes(): void
    {
        $category = new Category();

        $this->assertEquals([
            'title',
            'root_categories_id',
            'description',
            'status',
        ], $category->getFillable());
    }

    public function test_category_belongs_to_root_category(): void
    {
        $category = Category::factory()->create();

        $this->assertInstanceOf(
            \App\Models\RootCategory::class,
            $category->parent
        );
    }
}
```

### Running Tests

```bash
# Run all tests
php artisan test

# Run specific test file
php artisan test tests/Feature/AdminCategoryControllerTest.php

# Run with coverage
php artisan test --coverage

# Run specific test method
php artisan test --filter=test_admin_can_view_category_list

# Run tests in parallel
php artisan test --parallel
```

### Test Database

**Configure test database in `phpunit.xml`:**
```xml
<php>
    <env name="DB_CONNECTION" value="sqlite"/>
    <env name="DB_DATABASE" value=":memory:"/>
</php>
```

---

## Database Development

### Creating Migrations

```bash
# Create migration
php artisan make:migration create_categories_table

# Create migration with model
php artisan make:model Category -m

# Create migration for adding column
php artisan make:migration add_status_to_categories_table
```

### Migration Structure

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->foreignId('root_categories_id')
                ->nullable()
                ->constrained('root_categories')
                ->nullOnDelete();
            $table->text('description')->nullable();
            $table->tinyInteger('status')->default(1);
            $table->timestamps();

            // Indexes
            $table->index('status');
            $table->index('root_categories_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
```

### Model Factories

```php
<?php

namespace Database\Factories;

use App\Models\RootCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

class CategoryFactory extends Factory
{
    public function definition(): array
    {
        return [
            'title' => fake()->words(3, true),
            'root_categories_id' => RootCategory::factory(),
            'description' => fake()->sentence(),
            'status' => 1,
        ];
    }
}
```

### Seeders

```php
<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['title' => 'Movies HD', 'root_categories_id' => 2000],
            ['title' => 'Movies SD', 'root_categories_id' => 2000],
            ['title' => 'TV HD', 'root_categories_id' => 5000],
        ];

        foreach ($categories as $category) {
            Category::create($category);
        }
    }
}
```

---

## API Development

### Creating API Controllers

```bash
php artisan make:controller Api/CategoryController --api
```

### API Controller Structure

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CategoryResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    /**
     * Display a listing of categories.
     */
    public function index(): JsonResponse
    {
        $categories = Category::with('parent')->paginate(20);

        return CategoryResource::collection($categories)
            ->response()
            ->setStatusCode(200);
    }

    /**
     * Display the specified category.
     */
    public function show(Category $category): JsonResponse
    {
        return (new CategoryResource($category))
            ->response()
            ->setStatusCode(200);
    }
}
```

### API Resources

```php
<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class CategoryResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     */
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'status' => $this->status,
            'parent' => new RootCategoryResource($this->whenLoaded('parent')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
```

### API Testing

```php
public function test_api_returns_category_list(): void
{
    Category::factory()->count(5)->create();

    $this->getJson('/api/v2/categories')
        ->assertStatus(200)
        ->assertJsonStructure([
            'data' => [
                '*' => ['id', 'title', 'description', 'status']
            ],
            'meta' => ['current_page', 'total']
        ]);
}
```

---

## Frontend Development

### Blade Components

```php
// resources/views/components/button.blade.php
@props(['type' => 'submit', 'variant' => 'primary'])

<button
    type="{{ $type }}"
    {{ $attributes->merge(['class' => "btn btn-{$variant}"]) }}
>
    {{ $slot }}
</button>
```

**Usage:**
```blade
<x-button variant="success">
    Save Changes
</x-button>
```

### Livewire Components

```bash
# Create Livewire component
php artisan make:livewire SearchReleases
```

```php
<?php

namespace App\Livewire;

use App\Models\Release;
use Livewire\Component;
use Livewire\WithPagination;

class SearchReleases extends Component
{
    use WithPagination;

    public string $search = '';

    public function updatingSearch(): void
    {
        $this->resetPage();
    }

    public function render()
    {
        return view('livewire.search-releases', [
            'releases' => Release::where('name', 'like', "%{$this->search}%")
                ->paginate(25),
        ]);
    }
}
```

### Tailwind CSS

**Custom Utilities:**
```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: '#3b82f6',
        secondary: '#64748b',
      },
    },
  },
}
```

### Vite Build Process

```bash
# Development
npm run dev

# Production build
npm run build

# Preview production build
npm run preview
```

---

## Debugging

### Laravel Telescope

```bash
# Install Telescope (dev only)
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate
```

Access at: `http://localhost:8000/telescope`

### Xdebug Configuration

**php.ini:**
```ini
[xdebug]
zend_extension=xdebug.so
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=127.0.0.1
xdebug.client_port=9003
```

### VS Code Launch Configuration

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for Xdebug",
      "type": "php",
      "request": "launch",
      "port": 9003
    }
  ]
}
```

### Debugging Commands

```bash
# Enable query logging
DB::enableQueryLog();
// Your queries
dd(DB::getQueryLog());

# Dump and die
dd($variable);

# Dump without dying
dump($variable);

# Ray debugging (if installed)
ray($variable);
```

---

## Contributing

### Git Workflow

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/my-new-feature
   ```
3. **Make your changes**
4. **Commit with conventional commits**
   ```bash
   git commit -m "feat: add category validation"
   ```
5. **Push to your fork**
   ```bash
   git push origin feature/my-new-feature
   ```
6. **Create a Pull Request**

### Commit Message Convention

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding tests
- `chore`: Maintenance tasks

**Example:**
```
feat(categories): add validation for category creation

- Add StoreCategoryRequest form request
- Implement authorization check
- Add custom error messages

Refs: ROADMAP.md #45
```

### Code Review Checklist

- [ ] Tests pass (`php artisan test`)
- [ ] Code is formatted (`./vendor/bin/pint`)
- [ ] Static analysis passes (`./vendor/bin/phpstan analyse`)
- [ ] Documentation updated
- [ ] No sensitive data in commits
- [ ] Follows coding standards
- [ ] Commit messages are clear

---

## Release Process

### Version Numbering

We follow **Semantic Versioning**:
- **Major**: Breaking changes (X.0.0)
- **Minor**: New features, backward compatible (x.X.0)
- **Patch**: Bug fixes, backward compatible (x.x.X)

### Creating a Release

1. **Update version in key files**
2. **Update CHANGELOG.md**
3. **Create git tag**
   ```bash
   git tag -a v2.1.0 -m "Release v2.1.0"
   git push origin v2.1.0
   ```
4. **Create GitHub release**
5. **Update documentation**

---

## Useful Commands

### Artisan Commands

```bash
# List all commands
php artisan list

# Clear all caches
php artisan optimize:clear

# Generate IDE helper files
php artisan ide-helper:generate
php artisan ide-helper:models
php artisan ide-helper:meta

# Run queue worker
php artisan queue:work

# Create new admin user
php artisan make:user

# Check system requirements
php artisan nntmux:system-check
```

### Composer Commands

```bash
# Update dependencies
composer update

# Update specific package
composer update vendor/package

# Show outdated packages
composer outdated

# Validate composer.json
composer validate
```

### NPM Commands

```bash
# Update dependencies
npm update

# Check for security vulnerabilities
npm audit

# Fix security vulnerabilities
npm audit fix

# Update specific package
npm update package-name
```

---

## Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [Livewire Documentation](https://laravel-livewire.com/docs)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)
- [PHPUnit Documentation](https://phpunit.de/documentation.html)
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [CONFIGURATION.md](CONFIGURATION.md) - Configuration guide
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines

---

<p align="center">
    <strong>Built with ❤️ by the NNTmux Community</strong>
</p>

<p align="center">
    <sub>Last Updated: November 21, 2025 | Version 2.0.0</sub>
</p>
