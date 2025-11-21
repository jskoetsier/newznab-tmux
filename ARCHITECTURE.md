# NNTmux Architecture Documentation

> **Last Updated**: November 21, 2025
> **Version**: 2.0.0

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Technology Stack](#technology-stack)
4. [Application Layers](#application-layers)
5. [Core Components](#core-components)
6. [Database Schema](#database-schema)
7. [Data Flow](#data-flow)
8. [Caching Strategy](#caching-strategy)
9. [Queue System](#queue-system)
10. [Security Architecture](#security-architecture)
11. [API Architecture](#api-architecture)
12. [Frontend Architecture](#frontend-architecture)

---

## Overview

NNTmux is a Laravel-based Usenet indexing application that collects, processes, and categorizes binary files from Usenet newsgroups. The application follows a modular architecture with clear separation of concerns.

### Design Principles

- **Separation of Concerns**: Clear boundaries between presentation, business logic, and data access
- **Single Responsibility**: Each class and module has one well-defined purpose
- **Dependency Injection**: Loose coupling through Laravel's service container
- **Event-Driven**: Asynchronous processing using Laravel's event and queue system
- **Caching**: Aggressive caching strategy to reduce database load
- **Security**: Defense in depth with multiple security layers

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     EXTERNAL INTERFACES                      │
├─────────────┬─────────────┬─────────────┬──────────────────┤
│   Web UI    │  REST API   │  NNTP API   │  Console/CLI     │
└─────┬───────┴─────┬───────┴─────┬───────┴──────┬───────────┘
      │             │             │              │
┌─────▼─────────────▼─────────────▼──────────────▼───────────┐
│                   APPLICATION LAYER                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Controllers  │  │  Livewire    │  │   Commands   │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                 │               │
│  ┌──────▼─────────────────▼─────────────────▼─────────┐   │
│  │            FORM REQUESTS & VALIDATION              │   │
│  └──────────────────────┬─────────────────────────────┘   │
└─────────────────────────┼─────────────────────────────────┘
                          │
┌─────────────────────────▼─────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Services   │  │    Jobs      │  │   Events     │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         └──────────────────┼──────────────────┘            │
└────────────────────────────┼───────────────────────────────┘
                             │
┌────────────────────────────▼───────────────────────────────┐
│                    DATA ACCESS LAYER                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   Models     │  │ Repositories │  │   Cache      │    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         └──────────────────┼──────────────────┘            │
└────────────────────────────┼───────────────────────────────┘
                             │
┌────────────────────────────▼───────────────────────────────┐
│                   DATA STORAGE LAYER                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │   MySQL/     │  │    Redis     │  │  Elastic/    │    │
│  │   MariaDB    │  │              │  │  Manticore   │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
└────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Backend

- **Framework**: Laravel 11.x
- **Language**: PHP 8.3+
- **Database**: MySQL 8.0+ / MariaDB 10.11+
- **Cache**: Redis 7.0+
- **Search Engine**: ElasticSearch 8.x or Manticore Search 6.x
- **Queue**: Redis-based queue driver

### Frontend

- **Build Tool**: Vite
- **CSS Framework**: Tailwind CSS 3.x
- **JavaScript**: Alpine.js, Livewire 3.x
- **Icons**: Font Awesome

### Infrastructure

- **Web Server**: Nginx (recommended) or Apache
- **Process Manager**: Supervisor (for queue workers)
- **PHP Extensions**: Required extensions listed in composer.json

---

## Application Layers

### 1. Presentation Layer

**Location**: `/resources/views`, `/app/Http/Controllers`, `/app/Livewire`

Handles user interaction and data presentation.

- **Web Controllers**: Traditional HTTP request/response cycle
- **Livewire Components**: Real-time reactive components
- **API Controllers**: RESTful API endpoints
- **Views**: Blade templates with Tailwind CSS

### 2. Application Layer

**Location**: `/app/Http`

Orchestrates business logic and manages request flow.

- **Form Requests**: Input validation and authorization
- **Middleware**: Request filtering and transformation
- **Resources**: API response transformation
- **Policies**: Authorization logic

### 3. Business Logic Layer

**Location**: `/app/Services`, `/app/Jobs`, `/app/Events`

Contains core business logic and domain operations.

- **Services**: Reusable business logic components
- **Jobs**: Asynchronous task processing
- **Events/Listeners**: Event-driven architecture
- **Observers**: Model lifecycle hooks

### 4. Data Access Layer

**Location**: `/app/Models`, `/app/Repositories` (future)

Manages data persistence and retrieval.

- **Eloquent Models**: ORM for database interaction
- **Query Builders**: Complex database queries
- **Caching**: Query result caching

---

## Core Components

### 1. Usenet Processing Pipeline

```
NNTP Server → Header Collection → Binary Processing →
Release Formation → Categorization → NFO Processing →
Metadata Enhancement → Search Indexing
```

#### Header Collection
- **Component**: `Blacklight\NNTP`
- **Purpose**: Connects to NNTP servers and downloads article headers
- **Location**: `/Blacklight/NNTP.php`

#### Binary Processing
- **Component**: `Blacklight\Binaries`
- **Purpose**: Processes collected headers into binary files
- **Location**: `/Blacklight/Binaries.php`

#### Release Formation
- **Component**: `Blacklight\Releases`
- **Purpose**: Combines binaries into complete releases
- **Location**: `/Blacklight/Releases.php`

#### Categorization
- **Component**: `Blacklight\Categorize`
- **Purpose**: Automatically categorizes releases
- **Location**: `/Blacklight/processing/`

### 2. Metadata Processing

```
Release → TMDb/TVDb → PreDB Matching → NFO Parsing →
Music/Book APIs → Media Info Extraction
```

- **Movie Metadata**: TMDb API integration
- **TV Show Metadata**: TVDb and TMDb APIs
- **PreDB Matching**: Scene release database matching
- **Media Analysis**: FFprobe for video/audio analysis

### 3. Search System

Two search engine options:

#### ElasticSearch (Recommended)
- Full-text search capabilities
- Advanced querying and filtering
- Real-time indexing
- Scalable architecture

#### Manticore Search
- Lightweight alternative
- Real-time indexing
- Similar query capabilities
- Lower resource requirements

### 4. User Management

- **Authentication**: Laravel Breeze-based
- **Authorization**: Spatie Laravel Permission
- **Roles**: Admin, Moderator, User (customizable)
- **2FA**: Google Authenticator support
- **API Keys**: Personal access tokens

### 5. Queue System

Asynchronous processing for heavy operations:

- **Release Processing**: Background release formation
- **Metadata Fetching**: Parallel API requests
- **Email Notifications**: Non-blocking email sending
- **Maintenance Tasks**: Scheduled cleanup operations

---

## Database Schema

### Core Tables

#### `releases`
Primary release table containing all indexed content.

```sql
- id (bigint, PK)
- name (varchar)
- searchname (varchar) - Indexed search-friendly name
- totalpart (int)
- categories_id (int, FK)
- size (bigint)
- postdate (datetime)
- adddate (datetime)
- fromname (varchar)
- completion (decimal)
- grabs (int)
- videos_id (int)
- tv_episodes_id (int)
- imdbid (int)
- xxxinfo_id (int)
- musicinfo_id (int)
- bookinfo_id (int)
- gamesinfo_id (int)
```

#### `categories`
Hierarchical category structure.

```sql
- id (int, PK)
- title (varchar)
- root_categories_id (int, FK)
- description (text)
- status (tinyint)
```

#### `users`
User accounts and preferences.

```sql
- id (bigint, PK)
- username (varchar, unique)
- email (varchar, unique)
- password (varchar)
- api_token (varchar)
- grabs (int)
- role (int)
- created_at (timestamp)
- email_verified_at (timestamp)
```

#### `collections`
Temporary storage for incomplete binaries.

```sql
- id (bigint, PK)
- subject (varchar)
- fromname (varchar)
- date (datetime)
- totalfiles (int)
- groups_id (int, FK)
- collectionhash (varchar)
- filecheck (bool)
```

### Relationship Diagram

```
users ──┬──< user_downloads
        ├──< user_series
        └──< user_movies

categories ─< releases ──┬──< release_files
                         ├──< release_nfos
                         ├──< release_comments
                         ├──> videos
                         ├──> tv_episodes
                         ├──> musicinfo
                         └──> bookinfo

usenet_groups ─< collections ─< binaries
```

---

## Data Flow

### Release Processing Flow

1. **Header Collection**
   ```
   NNTP Server → Download Headers → Store in parts table
   ```

2. **Binary Formation**
   ```
   parts → Group by subject → Create binaries →
   Link to collections
   ```

3. **Release Creation**
   ```
   collections → Check completeness → Form release →
   Initial categorization
   ```

4. **Enhancement**
   ```
   release → NFO extraction → PreDB matching →
   Metadata fetching → Final categorization
   ```

5. **Indexing**
   ```
   enhanced release → Search index → Available for users
   ```

### User Search Flow

1. **Search Request**
   ```
   User Query → Controller → Search Service
   ```

2. **Query Processing**
   ```
   Parse query → Build search parameters →
   Execute ElasticSearch/Manticore query
   ```

3. **Result Processing**
   ```
   Search results → Database hydration →
   Authorization check → Response formatting
   ```

4. **Response Delivery**
   ```
   Formatted results → View rendering → User display
   ```

---

## Caching Strategy

### Cache Layers

1. **Application Cache** (Redis)
   - Configuration values
   - Category trees
   - User permissions
   - Frequently accessed data

2. **Query Cache** (Redis)
   - Complex query results
   - Aggregations and statistics
   - API responses

3. **Browser Cache** (HTTP Headers)
   - Static assets
   - Public images
   - CSS/JS bundles

### Cache Keys Convention

```php
// Format: {domain}:{entity}:{identifier}:{variant}
'categories:tree:all'
'user:settings:{userId}'
'release:details:{releaseId}'
'api:search:{hash}'
```

### Cache TTL Strategy

- **Long-lived** (24 hours): Static data (categories, settings)
- **Medium-lived** (1 hour): Semi-static data (user stats, counts)
- **Short-lived** (5 minutes): Dynamic data (recent releases, searches)

---

## Queue System

### Queue Configuration

- **Driver**: Redis
- **Workers**: Supervisor-managed
- **Retry Strategy**: 3 attempts with exponential backoff
- **Failed Job Handling**: Stored in `failed_jobs` table

### Queue Priorities

1. **High**: User-initiated actions (downloads, searches)
2. **Default**: Standard processing (releases, metadata)
3. **Low**: Background maintenance (cleanup, optimization)

### Common Jobs

- `ProcessRelease`: Create release from collection
- `FetchMovieMetadata`: Get movie info from TMDb
- `FetchTvMetadata`: Get TV show info from TVDb
- `UpdateSearchIndex`: Update ElasticSearch index
- `SendEmailNotification`: Send user notifications

---

## Security Architecture

### Defense Layers

1. **Input Validation**
   - Form Request validation
   - SQL injection prevention (prepared statements)
   - XSS prevention (Blade escaping)

2. **Authentication**
   - Bcrypt password hashing
   - Session-based authentication
   - API token authentication
   - 2FA support

3. **Authorization**
   - Role-based access control
   - Policy-based permissions
   - API rate limiting
   - CSRF protection

4. **Data Protection**
   - Encrypted sensitive fields
   - Hidden API responses
   - Secure password reset flow
   - Email verification

### Security Best Practices

- Never trust user input
- Use Form Requests for all forms
- Implement rate limiting on all APIs
- Regularly update dependencies
- Log security events
- Monitor failed authentication attempts

---

## API Architecture

### REST API v2

**Base URL**: `/api/v2`

#### Authentication

- **Method**: API Token (Personal Access Token)
- **Header**: `Authorization: Bearer {token}`

#### Rate Limiting

- **Anonymous**: 60 requests/hour
- **Authenticated**: 1000 requests/hour
- **Admin**: Unlimited

#### Response Format

```json
{
  "status": "success|error",
  "data": {},
  "meta": {
    "pagination": {},
    "timestamp": "2025-11-21T10:00:00Z"
  }
}
```

### Newznab API

**Base URL**: `/api`

Standard Newznab protocol implementation for indexer compatibility.

---

## Frontend Architecture

### Component Structure

```
resources/
├── views/
│   ├── layouts/
│   │   ├── app.blade.php
│   │   └── admin.blade.php
│   ├── components/
│   │   ├── card.blade.php
│   │   ├── button.blade.php
│   │   └── ...
│   ├── pages/
│   │   ├── browse/
│   │   ├── details/
│   │   └── ...
│   └── livewire/
│       └── search.blade.php
└── js/
    ├── app.js
    └── components/
```

### State Management

- **Livewire**: Reactive component state
- **Alpine.js**: Client-side interactivity
- **LocalStorage**: User preferences

### Asset Pipeline

- **Vite**: Fast HMR development
- **Tailwind CSS**: Utility-first CSS
- **PostCSS**: CSS processing
- **Code Splitting**: Optimized bundles

---

## Performance Considerations

### Database Optimization

- Proper indexing on frequently queried columns
- Eager loading to prevent N+1 queries
- Query optimization with `explain`
- Connection pooling

### Application Optimization

- Route caching
- Config caching
- View caching
- OPcache enabled

### Scalability

- **Horizontal Scaling**: Load balancer + multiple app servers
- **Database Scaling**: Read replicas, query optimization
- **Cache Scaling**: Redis cluster
- **Queue Scaling**: Multiple queue workers

---

## Development Workflow

### Local Development

1. Clone repository
2. Install dependencies: `composer install && npm install`
3. Configure environment: `.env`
4. Run migrations: `php artisan migrate`
5. Start development server: `php artisan serve`
6. Start Vite: `npm run dev`

### Testing

```bash
# Run all tests
php artisan test

# Run specific test suite
php artisan test --testsuite=Feature

# Run with coverage
php artisan test --coverage
```

### Code Quality

```bash
# PHPStan analysis
./vendor/bin/phpstan analyse

# Code formatting
./vendor/bin/pint

# Linting
npm run lint
```

---

## Deployment Architecture

### Recommended Stack

```
Load Balancer (Nginx)
    ↓
Application Servers (PHP-FPM + Nginx)
    ↓
├── Database (MySQL Primary + Replicas)
├── Cache (Redis Sentinel/Cluster)
├── Search (ElasticSearch Cluster)
└── Queue (Redis + Supervisor)
```

### Environment Requirements

- PHP 8.3+ with required extensions
- MySQL 8.0+ or MariaDB 10.11+
- Redis 7.0+
- Nginx or Apache
- Supervisor for queue workers
- ElasticSearch 8.x or Manticore Search 6.x

---

## Future Architecture Plans

### v3.0 Goals

1. **Microservices**: Split into focused services
2. **GraphQL API**: Flexible data fetching
3. **WebSocket Support**: Real-time updates
4. **Machine Learning**: AI-powered categorization
5. **Distributed Architecture**: Multi-region support

---

## Additional Resources

- [Laravel Documentation](https://laravel.com/docs)
- [CONFIGURATION.md](CONFIGURATION.md) - Configuration guide
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide
- [ROADMAP.md](ROADMAP.md) - Future plans

---

<p align="center">
    <strong>Built with ❤️ by the NNTmux Community</strong>
</p>

<p align="center">
    <sub>Last Updated: November 21, 2025 | Version 2.0.0</sub>
</p>
