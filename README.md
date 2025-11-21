<p align="center">
    <img src="https://raw.githubusercontent.com/NNTmux/newznab-tmux/master/public/images/logo.png" alt="NNTmux Logo" width="200">
</p>

<h1 align="center">NNTmux</h1>

<p align="center">
    <strong>A Modern, High-Performance Usenet Indexer Built on Laravel</strong>
</p>

<p align="center">
    <a href="https://packagist.org/packages/nntmux/newznab-tmux"><img src="https://poser.pugx.org/nntmux/newznab-tmux/v/stable.svg" alt="Latest Stable Version"></a>
    <a href="https://packagist.org/packages/nntmux/newznab-tmux"><img src="https://poser.pugx.org/nntmux/newznab-tmux/license.svg" alt="License"></a>
    <a href="https://discord.gg/GjgGSzkrjh"><img src="https://img.shields.io/discord/123456789.svg?label=Discord&logo=Discord&colorB=7289da" alt="Discord"></a>
    <a href="https://www.patreon.com/bePatron?u=6160908"><img src="https://img.shields.io/badge/Patreon-Support%20Us-orange.svg" alt="Support on Patreon"></a>
</p>

---

## 📖 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Requirements](#-requirements)
- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Usage](#-usage)
- [Documentation](#-documentation)
- [Contributing](#-contributing)
- [Support](#-support)
- [License](#-license)

---

## 🎯 About

NNTmux is a powerful, modern Usenet indexer that automatically scans Usenet newsgroups, collects binary headers, and organizes them into searchable releases. Built on the Laravel framework, it offers enterprise-grade performance, scalability, and a rich feature set for both casual users and professional indexer operators.

**Originally forked from:** [newznab plus](https://github.com/anth0/nnplus) and [nZEDb](https://github.com/nZEDb/nZEDb)

**Key Advantages:**
- 🚀 Multi-threaded processing via Tmux engine
- 🔍 Advanced search with Manticore/Elasticsearch integration
- 📊 Real-time monitoring and performance metrics
- 🎨 Modern UI with Vue 3, Tailwind CSS, and Vite
- 🔐 Enterprise security features (2FA, RBAC, API authentication)
- 📦 Docker-ready with Laravel Sail

---

## ✨ Features

### Core Functionality
- **Automated Usenet Scanning**: Continuously monitors newsgroups for new content
- **Intelligent Release Processing**: Advanced categorization and metadata enrichment
- **Multi-threaded Architecture**: Parallel processing for headers, releases, and post-processing
- **Smart Caching**: Local metadata caching reduces external API calls
- **NFO & Media Processing**: Automatic NFO extraction, video/audio analysis, and preview generation

### Search & Discovery
- **Advanced Search Engine**: Full-text search with Manticore or Elasticsearch
- **Category-based Browsing**: Organized by Movies, TV, Music, Games, Books, and more
- **API Access**: Newznab-compatible API for integration with download clients
- **User Preferences**: Customizable search filters and category exclusions

### Metadata Enrichment
- **TV Shows**: TMDB, TVDB, TVMaze, Trakt integration
- **Movies**: TMDB, IMDB support with automatic poster/backdrop downloads
- **Music**: MusicBrainz integration
- **Games**: Steam, IGDB metadata
- **Books**: Google Books, OpenLibrary support
- **Anime**: AniDB parsing and categorization

### User Management
- **Role-Based Access Control**: Granular permissions via Spatie Permissions
- **Two-Factor Authentication**: Google Authenticator support
- **Invite System**: Controlled registration with invite codes
- **API Keys**: Per-user API tokens with rate limiting
- **Usage Tracking**: Download quotas and statistics

### Admin Features
- **Tmux Monitoring Dashboard**: Real-time system metrics and thread status
- **Group Management**: Enable/disable newsgroups, configure backfill
- **Release Management**: Manual editing, regex testing, category assignment
- **User Administration**: Role management, account verification, invite control
- **Performance Monitoring**: Laravel Telescope and Horizon integration

### Developer Experience
- **Modern Tech Stack**: Laravel 12, PHP 8.3+, Vue 3, Tailwind CSS
- **Comprehensive API**: RESTful API with rate limiting and authentication
- **Database Flexibility**: MariaDB/MySQL with optimized queries
- **Queue Management**: Laravel Horizon for background jobs
- **Testing Suite**: PHPUnit tests with code coverage
- **Development Tools**: Laravel Sail, Vite HMR, Laravel Pint

---

## 💻 Requirements

### Minimum Requirements
- **OS**: Linux (Ubuntu 22.04+ recommended), macOS, Windows (WSL2)
- **PHP**: 8.3 or higher
- **Database**: MariaDB 10.11+ or MySQL 8.0+
- **Node.js**: 18.x or higher
- **Composer**: 2.x
- **Redis**: 6.x or higher (recommended for caching/queues)
- **Memory**: 8GB RAM minimum
- **Storage**: 50GB+ for base installation

### Recommended for Production
- **Memory**: 64GB RAM
- **CPU**: 8+ cores
- **Storage**: 320GB+ NVMe SSD
- **Network**: 1Gbps+ for Usenet downloads
- **Search Engine**: Manticore Search or Elasticsearch

### PHP Extensions
Required extensions (see `composer.json` for complete list):
```
bcmath, ctype, curl, exif, fileinfo, filter, gd, hash, iconv, intl, json,
libxml, mbstring, mysqlnd, openssl, pcre, pdo, pdo_mysql, session,
simplexml, sockets, sodium, spl, xmlwriter, zlib
```

---

## 🚀 Quick Start

### Option 1: Docker (Recommended for Development)

```bash
# Clone repository
git clone https://github.com/NNTmux/newznab-tmux.git
cd newznab-tmux

# Copy environment file
cp .env.example .env

# Edit .env with your database credentials and settings
nano .env

# Start Docker containers
./vendor/bin/sail up -d

# Install dependencies
./vendor/bin/sail composer install
./vendor/bin/sail npm install

# Generate application key
./vendor/bin/sail artisan key:generate

# Run migrations
./vendor/bin/sail artisan migrate --seed

# Build frontend assets
./vendor/bin/sail npm run build

# Access at http://localhost
```

### Option 2: Local Installation

```bash
# Clone repository
git clone https://github.com/NNTmux/newznab-tmux.git
cd newznab-tmux

# Install dependencies
composer install
npm install

# Configure environment
cp .env.example .env
php artisan key:generate

# Edit .env with your settings
nano .env

# Run migrations
php artisan migrate --seed

# Build assets
npm run build

# Start development server
php artisan serve
```

**Default Admin Credentials:**
- Check your `.env` file for `ADMIN_USER` and `ADMIN_PASS`
- **⚠️ Change these immediately after installation!**

---

## 📦 Installation

For detailed installation instructions, see our comprehensive guides:

- **[Ubuntu Installation Guide](https://github.com/NNTmux/newznab-tmux/wiki/Ubuntu-Install-guide)**
- **[Docker Installation](https://github.com/NNTmux/newznab-tmux/wiki/Docker-Installation)**
- **[Production Deployment](https://github.com/NNTmux/newznab-tmux/wiki/Production-Deployment)**
- **[PreDB Setup](QUICK_START_PREDB.md)**
- **[CAPTCHA Configuration](CAPTCHA_CONFIGURATION.md)**

### Post-Installation Steps

1. **Configure NNTP Server**
   ```bash
   # Edit .env
   NNTP_SERVER=your.usenet.provider.com
   NNTP_USERNAME=your_username
   NNTP_PASSWORD=your_password
   NNTP_PORT=563
   NNTP_SSLENABLED=true
   ```

2. **Activate Newsgroups**
   - Navigate to Admin Panel → Usenet Groups
   - Activate groups you want to index
   - Configure backfill settings

3. **Start Indexing**
   ```bash
   # Backfill headers
   php artisan nntmux:backfill

   # Process releases
   php artisan nntmux:releases

   # Post-processing
   php artisan nntmux:postprocess
   ```

4. **Setup Tmux (Multi-threading)**
   ```bash
   # Configure tmux settings
   php artisan nntmux:tmux --configure

   # Start tmux sessions
   php artisan nntmux:tmux --start
   ```

---

## ⚙️ Configuration

### Essential Environment Variables

```bash
# Application
APP_NAME=NNTmux
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

# Database
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=nntmux
DB_USERNAME=nntmux
DB_PASSWORD=your_secure_password

# NNTP (Usenet Provider)
NNTP_SERVER=your.provider.com
NNTP_USERNAME=username
NNTP_PASSWORD=password
NNTP_PORT=563
NNTP_SSLENABLED=true
NNTP_COMPRESSION=true

# Caching & Queues
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# Search Engine (Manticore recommended)
MANTICORE_HOST=127.0.0.1
MANTICORE_PORT=9308

# Alternative: Elasticsearch
ELASTICSEARCH_ENABLED=false
ELASTICSEARCH_HOST=localhost:9200

# Admin Credentials (CHANGE THESE!)
ADMIN_USER=admin
ADMIN_PASS=ChangeThisSecurePassword123!

# API Configuration
API_RATE_LIMIT=60

# Email (for notifications)
MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@your-domain.com
MAIL_FROM_NAME="${APP_NAME}"

# External APIs (Optional but recommended)
TMDB_API_KEY=your_tmdb_key
TVDB_API_KEY=your_tvdb_key
IGDB_CLIENT_ID=your_igdb_id
IGDB_CLIENT_SECRET=your_igdb_secret

# Captcha (Optional)
TURNSTILE_ENABLED=false
TURNSTILE_SITE_KEY=
TURNSTILE_SECRET_KEY=
```

For complete configuration documentation, see [CONFIGURATION.md](https://github.com/NNTmux/newznab-tmux/wiki/Configuration).

---

## 🎮 Usage

### Basic Commands

```bash
# Backfill headers from Usenet
php artisan nntmux:backfill [--group=alt.binaries.group]

# Create releases from binaries
php artisan nntmux:releases

# Post-process releases (NFO, metadata, etc.)
php artisan nntmux:postprocess

# Update release names using PreDB
php artisan nntmux:fixreleasenames

# Import PreDB dump
php artisan nntmux:import-predb /path/to/dump.csv.gz

# Clear old releases
php artisan nntmux:cleanup
```

### Tmux Multi-threading

```bash
# View tmux configuration
php artisan nntmux:tmux --help

# Start all tmux sessions
php artisan nntmux:tmux --start

# Stop all sessions
php artisan nntmux:tmux --stop

# Monitor sessions
php artisan nntmux:tmux --monitor

# Attach to a session
php artisan nntmux:tmux --attach=main
```

### Maintenance

```bash
# Clear caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Optimize for production
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run queue workers
php artisan horizon

# Monitor with Telescope (development)
php artisan telescope:install
```

---

## 📚 Documentation

### Official Documentation
- **[Wiki Home](https://github.com/NNTmux/newznab-tmux/wiki)**: Complete documentation
- **[API Documentation](docs/newznab_api_specification.txt)**: Newznab API spec
- **[Security Policy](SECURITY.md)**: Security guidelines and reporting
- **[Contributing Guidelines](CONTRIBUTING.md)**: How to contribute
- **[Changelog](CHANGELOG.md)**: Version history
- **[Roadmap](ROADMAP.md)**: Future plans

### Guides
- **[PreDB Quick Start](QUICK_START_PREDB.md)**: Setup PreDB for better release naming
- **[CAPTCHA Setup](CAPTCHA_CONFIGURATION.md)**: Configure Turnstile CAPTCHA
- **[Database Tuning](https://github.com/NNTmux/newznab-tmux/wiki/Database-Tuning)**: Optimize MySQL/MariaDB
- **[Performance Optimization](https://github.com/NNTmux/newznab-tmux/wiki/Performance)**: Speed up your indexer

### Video Tutorials
- Coming soon!

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes** with descriptive commits
4. **Add tests** for new functionality
5. **Ensure tests pass**: `php artisan test`
6. **Submit a pull request** to the `dev` branch

### Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/newznab-tmux.git
cd newznab-tmux

# Install dependencies
composer install
npm install

# Setup environment
cp .env.example .env
php artisan key:generate

# Run tests
php artisan test

# Run linting
./vendor/bin/pint

# Run static analysis
./vendor/bin/phpstan analyse
```

### Code Style
- Follow **PSR-12** coding standards
- Use **Laravel conventions** for naming and structure
- Write **meaningful commit messages**
- Add **PHPDoc blocks** to all methods
- Include **tests** for new features

---

## 💬 Support

### Community Support
- **Discord**: [Join our server](https://discord.gg/GjgGSzkrjh)
- **GitHub Discussions**: [Ask questions](https://github.com/NNTmux/newznab-tmux/discussions)
- **GitHub Issues**: [Report bugs](https://github.com/NNTmux/newznab-tmux/issues)
- **Wiki**: [Documentation](https://github.com/NNTmux/newznab-tmux/wiki)

### Commercial Support
For commercial support, consulting, or custom development:
- Contact via Discord
- Consider [supporting on Patreon](https://www.patreon.com/bePatron?u=6160908)

---

## 🙏 Acknowledgments

### Original Projects
- **newznab plus**: https://github.com/anth0/nnplus
- **nZEDb**: https://github.com/nZEDb/nZEDb
- **newznab**: Original Usenet indexer project

### Contributors
Thanks to all our contributors! See [CONTRIBUTORS.md](https://github.com/NNTmux/newznab-tmux/graphs/contributors).

### Third-Party Services
- **TMDB**: Movie and TV metadata
- **TVDB**: TV series information
- **TVMaze**: TV show data
- **IGDB**: Game metadata
- **AniDB**: Anime information
- **MusicBrainz**: Music metadata

---

## 📄 License

NNTmux is licensed under the **GNU General Public License v3.0** (GPL-3.0).

See [LICENSE](LICENSE) for full license text.

**External libraries** included in this project retain their respective licenses.

---

## 🔒 Security

For security issues, please see our [Security Policy](SECURITY.md).

**Do not** create public issues for security vulnerabilities. Report them privately through GitHub Security Advisories or Discord.

---

## 📊 Statistics

- **Language**: PHP, JavaScript, Blade
- **Framework**: Laravel 12
- **Database**: MariaDB/MySQL
- **Stars**: ⭐ (Star us on GitHub!)
- **Active Installations**: Growing community

---

## 🗺️ Roadmap

See [ROADMAP.md](ROADMAP.md) for planned features and improvements.

---

<p align="center">
    <strong>Built with ❤️ by the NNTmux Team</strong>
</p>

<p align="center">
    <a href="https://www.patreon.com/bePatron?u=6160908">
        <img src="https://c5.patreon.com/external/logo/become_a_patron_button.png" alt="Become a Patron!" height="35">
    </a>
</p>

---

<p align="center">
    <sub>Version 2.0.0 | Last Updated: November 21, 2025</sub>
</p>
