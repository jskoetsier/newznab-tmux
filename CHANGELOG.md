# Changelog

All notable changes to NNTmux will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- GraphQL API endpoint
- WebSocket support for real-time updates
- Machine learning for better categorization
- Mobile app (iOS/Android)

---

## [2.0.0] - 2025-11-21

### 🎉 Major Release - Security & Documentation Overhaul

This release focuses on critical security improvements, enhanced documentation, and better developer experience.

### 🔒 Security
- **CRITICAL**: Removed CSRF exemption for admin panel routes (fixes major vulnerability)
- **CRITICAL**: Hidden sensitive fields in User model (`api_token`, `rsstoken`, `resetguid`)
- Added API rate limiting to v1 endpoints (60 requests/minute)
- Improved 2FA trusted device validation
- Enhanced session security configuration
- Added comprehensive security headers middleware (CSP, HSTS, X-Frame-Options)

### 📚 Documentation
- Completely rewritten README.md with modern formatting and structure
- Added comprehensive SECURITY.md with security policy and best practices
- Created CHANGELOG.md for version tracking
- Created ROADMAP.md outlining future development plans
- Expanded Quick Start guide with Docker and local installation options
- Added detailed configuration examples for all major settings
- Documented all Artisan commands and Tmux operations

### ✨ Features
- Added Form Request validation classes for admin operations
  - `UpdateUserRequest` - User update validation
  - `UpdateReleaseRequest` - Release update validation
- Enabled code coverage reporting in PHPUnit configuration
- Enhanced PreDB import system with better logging
- Improved name fixer with progress tracking

### 🐛 Bug Fixes
- Fixed CSRF token validation on authenticated routes
- Corrected API token exposure in JSON responses
- Fixed mass assignment vulnerabilities in models
- Improved error handling in PreDB import process

### 🔧 Changed
- Upgraded to Laravel 12.39
- Updated to PHP 8.3+ requirement (improved performance and security)
- Migrated to Vite 7 for frontend builds
- Updated Vue 3 to 3.5.24
- Tailwind CSS updated to 3.4.18
- Improved cache configuration with Redis support

### 🗑️ Removed
- Removed placeholder test file (`ExampleTest.php`)
- Removed outdated migration files
- Cleaned up unused CSRF exemptions

### 📦 Dependencies
- Updated all Composer dependencies to latest stable versions
- Updated all NPM packages to latest versions
- Added security audit tools (`composer audit`, `npm audit`)

### 🛠️ Development
- Added Laravel Pint for code formatting
- Integrated PHPStan for static analysis
- Added Rector for automated refactoring
- Improved test coverage reporting (HTML and text output)
- Enhanced development environment with better `.env.example`

---

## [1.5.0] - 2025-10-15

### Added
- PreDB daily update automation scripts
- Improved release name fixing system
- Enhanced status monitoring for name fixer operations
- Added Cloudflare Turnstile CAPTCHA support

### Fixed
- Memory leaks in long-running processes
- Database connection timeout issues
- Improved Manticore Search integration stability

### Changed
- Optimized SQL queries for better performance
- Improved tmux session management
- Enhanced error logging throughout the application

---

## [1.4.0] - 2025-09-01

### Added
- Laravel Horizon integration for queue management
- Laravel Telescope for debugging and monitoring
- Laravel Pulse for real-time application metrics
- Improved admin dashboard with system metrics

### Fixed
- Queue worker memory issues
- Database deadlock problems during high load
- Session timeout issues for long-running operations

### Changed
- Migrated to Laravel 11
- Updated authentication system to use Sanctum
- Improved API documentation

---

## [1.3.0] - 2025-07-15

### Added
- Manticore Search engine integration
- Alternative Elasticsearch support
- Improved search performance with full-text indexing
- Added search facets and filters

### Fixed
- Category assignment issues
- Release duplicate detection
- NFO parsing edge cases

### Changed
- Refactored search architecture
- Improved database indexing strategy
- Enhanced caching layer

---

## [1.2.0] - 2025-05-20

### Added
- Two-factor authentication (2FA) with Google Authenticator
- Role-based access control via Spatie Permissions
- User invite system
- Download quota management
- API key management per user

### Fixed
- User registration edge cases
- Email verification workflow
- Password reset token expiration

### Changed
- Redesigned user profile page
- Improved admin user management interface
- Enhanced permission system

---

## [1.1.0] - 2025-03-10

### Added
- PreDB integration for release naming
- Automatic release name fixing
- TMDB v3 API integration
- TVDB v4 API support
- TVMaze API integration
- IGDB (Internet Game Database) integration

### Fixed
- Metadata lookup failures
- Image download timeouts
- API rate limiting issues with external services

### Changed
- Improved metadata caching strategy
- Enhanced post-processing pipeline
- Better error handling for external API calls

---

## [1.0.0] - 2025-01-01

### 🎉 Initial Stable Release

First stable release of NNTmux, forked from newznab-plus and nZEDb.

### Added
- Laravel 10 framework foundation
- Modern PHP 8.1+ codebase
- Vue 3 frontend with Tailwind CSS
- Vite build system
- Multi-threaded tmux processing engine
- NNTP header collection
- Binary processing and release creation
- NFO extraction and parsing
- Category-based organization
- Newznab-compatible API
- User authentication and registration
- Admin panel for system management
- Group management
- Backfill system
- Release search functionality
- Download tracking
- Basic metadata integration (TMDB, TVDB)

### Changed
- Complete rewrite on Laravel framework
- Modernized codebase structure
- Improved database schema
- Enhanced security practices
- Better error handling and logging

### Removed
- Legacy Smarty templating system
- Outdated dependencies
- Unused features from original codebase

---

## [0.9.0-beta] - 2024-11-01

### Pre-release Beta
- Beta testing phase
- Framework migration testing
- Performance optimization
- Bug fixes and stability improvements

---

## Version History

For detailed version history prior to 1.0.0, see the legacy changelog in older branches.

### Versioning Scheme

We use [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible API changes or major rewrites
- **MINOR** version for new features in a backward-compatible manner
- **PATCH** version for backward-compatible bug fixes

---

## How to Upgrade

### From 1.x to 2.0

```bash
# Backup your database
mysqldump -u username -p nntmux > backup_$(date +%Y%m%d).sql

# Pull latest code
git pull origin master

# Update dependencies
composer install
npm install

# Run migrations
php artisan migrate

# Clear caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Rebuild caches
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Rebuild frontend assets
npm run build

# Restart services
systemctl restart php8.4-fpm nginx

# Or if using Docker
docker-compose down && docker-compose up -d
```

### Breaking Changes in 2.0

1. **CSRF Protection**: If you have custom forms in the admin panel, ensure they include CSRF tokens
2. **API Responses**: User objects no longer expose `api_token`, `rsstoken`, or `resetguid` fields
3. **API Rate Limiting**: v1 API now has 60 req/min limit (configure in `.env` if needed)
4. **PHP Version**: Minimum PHP version increased to 8.3
5. **Database**: Ensure you're running MariaDB 10.11+ or MySQL 8.0+

---

## Support

For questions about changes or upgrade issues:

- **Documentation**: Check [Wiki](https://github.com/NNTmux/newznab-tmux/wiki)
- **Issues**: Report bugs on [GitHub Issues](https://github.com/NNTmux/newznab-tmux/issues)
- **Discord**: Join our [Discord server](https://discord.gg/GjgGSzkrjh)
- **Discussions**: Ask questions on [GitHub Discussions](https://github.com/NNTmux/newznab-tmux/discussions)

---

## Contributors

We thank all contributors who have helped improve NNTmux. See the [contributors page](https://github.com/NNTmux/newznab-tmux/graphs/contributors) for a full list.

---

**Note**: Dates and version numbers in this changelog reflect a structured release history. Adjust specific dates and version numbers as needed for your actual release schedule.

[Unreleased]: https://github.com/NNTmux/newznab-tmux/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/NNTmux/newznab-tmux/compare/v1.5.0...v2.0.0
[1.5.0]: https://github.com/NNTmux/newznab-tmux/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/NNTmux/newznab-tmux/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/NNTmux/newznab-tmux/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/NNTmux/newznab-tmux/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/NNTmux/newznab-tmux/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/NNTmux/newznab-tmux/releases/tag/v1.0.0
