<p align="center">
    <a href="https://packagist.org/packages/nntmux/newznab-tmux"><img src="https://poser.pugx.org/nntmux/newznab-tmux/v/stable.svg" alt="Latest Stable Version"></a>
    <a href="https://packagist.org/packages/nntmux/newznab-tmux"><img src="https://poser.pugx.org/nntmux/newznab-tmux/license.svg" alt="License"></a>
    <a href="https://www.patreon.com/bePatron?u=6160908"><img src="https://c5.patreon.com/external/logo/become_a_patron_button.png" alt="Become a Patron!" height="20"></a>
</p>

# NNTmux

NNTmux is a modern Usenet indexer built on Laravel, designed for high performance and scalability. It automatically scans Usenet, collects headers, and organizes them into searchable releases. The project is actively maintained and features multi-threaded processing, advanced search, and a web-based front-end with API access.

This project is a fork of [newznab plus](https://github.com/anth0/nnplus) and [nZEDb](https://github.com/nZEDb/nZEDb), with significant improvements:

- Multi-threaded processing (header retrieval, release creation, post-processing)
- Advanced search (name, subject, category, post-date)
- Intelligent local caching of metadata
- Tmux engine for thread, database, and performance monitoring
- Image and video sample support
- Modern frontend stack: Vite, Tailwind CSS, Vue 3
- Dockerized development via Laravel Sail

## Prerequisites

- System administration experience (Linux recommended)
- PHP 8.3+ and required extensions (see composer.json for full list)
- MariaDB 10+ or MySQL 8+ (Postgres not supported)
- Node.js 18+ and npm for frontend assets
- Composer for PHP dependencies
- Redis (recommended) for caching and queues
- Recommended: 64GB RAM, 8+ cores, 320GB+ disk space

## Quick Start

### 5-Minute Setup (Docker)

The fastest way to get NNTmux running locally:

1. **Clone and Setup**
   ```bash
   git clone https://github.com/NNTmux/newznab-tmux.git
   cd newznab-tmux
   cp .env.example .env
   ```

2. **Configure Environment**
   Edit `.env` and set your database credentials:
   ```bash
   DB_HOST=mysql
   DB_PORT=3306
   DB_DATABASE=nntmux
   DB_USERNAME=nntmux
   DB_PASSWORD=your_secure_password
   ```

3. **Start with Laravel Sail**
   ```bash
   ./vendor/bin/sail up -d
   ./vendor/bin/sail artisan migrate --seed
   ./vendor/bin/sail artisan key:generate
   ```

4. **Build Frontend Assets**
   ```bash
   ./vendor/bin/sail npm install
   ./vendor/bin/sail npm run build
   ```

5. **Access the Application**
   - Web Interface: http://localhost
   - Default Admin: Check your `.env` for `ADMIN_USER` and `ADMIN_PASS`

### Local Installation (Non-Docker)

1. **Install Dependencies**
   ```bash
   composer install
   npm install
   ```

2. **Configure Environment**
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```

   Edit `.env` with your database settings.

3. **Database Setup**
   ```bash
   php artisan migrate --seed
   ```

4. **Build Assets**
   ```bash
   npm run build
   ```

5. **Serve Application**
   ```bash
   php artisan serve
   ```

### Key Configuration Settings

After installation, configure these important settings in your `.env` file:

```bash
# Application
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

# Database (adjust for your setup)
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=nntmux
DB_USERNAME=nntmux
DB_PASSWORD=your_password

# NNTP Server (Required for indexing)
NNTP_SERVER=your.usenet.provider.com
NNTP_USERNAME=your_username
NNTP_PASSWORD=your_password
NNTP_PORT=563
NNTP_SSLENABLED=true

# Cache & Sessions
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# Search Engine (Choose one)
MANTICORE_HOST=127.0.0.1
MANTICORE_PORT=9308
# OR
ELASTICSEARCH_ENABLED=false

# Admin Credentials (Change these!)
ADMIN_USER=admin
ADMIN_PASS=change_this_password
```

### First Steps After Installation

1. **Access Admin Panel**: Navigate to `http://your-domain/admin`
2. **Configure Usenet Groups**: Go to Admin → Usenet Groups and activate groups to index
3. **Start Indexing**: Run the backfill command to begin collecting headers:
   ```bash
   php artisan nntmux:backfill
   ```
4. **Process Releases**: Create releases from collected binaries:
   ```bash
   php artisan nntmux:releases
   ```
5. **Setup Tmux**: For multi-threaded processing, configure and start tmux:
   ```bash
   php artisan nntmux:tmux
   ```

### Testing Your Installation

Run the test suite to ensure everything is configured correctly:

```bash
php artisan test
```

For code coverage report:

```bash
php artisan test --coverage
```

### Common Issues

**Database connection failed**: Verify your database credentials in `.env` and ensure MariaDB/MySQL is running.

**Migration errors**: Ensure your database user has proper permissions (CREATE, ALTER, DROP, etc.).

**Assets not loading**: Run `npm run build` and ensure your web server can access the `public` directory.

**High memory usage**: NNTmux requires significant RAM for optimal performance. Consider adjusting PHP memory limits in `php.ini`.

For more detailed troubleshooting, see our [Wiki](https://github.com/NNTmux/newznab-tmux/wiki) or join our [Discord](https://discord.gg/GjgGSzkrjh).

## Database Tuning

For large-scale indexing, tune your database for performance. Use [mysqltuner.pl](http://mysqltuner.pl) and set `innodb_buffer_pool_size` appropriately (1-2GB per million releases).

For further tuning advice, see:
- [How do I tune MySQL for performance?](https://stackoverflow.com/questions/1047497/how-do-i-tune-mysql-for-performance)
- [How to optimize MySQL server performance?](https://stackoverflow.com/questions/600032/how-to-optimize-mysql-server-performance)
- [How to optimize MariaDB for large databases?](https://stackoverflow.com/questions/32421909/how-to-optimize-mariadb-for-large-databases)

## Installation

Follow the [Ubuntu install guide](https://github.com/NNTmux/newznab-tmux/wiki/Ubuntu-Install-guide) and [Composer install guide](https://github.com/NNTmux/newznab-tmux/wiki/Installing-Composer).

## Docker & Development

NNTmux uses Laravel Sail for Docker-based development. To start:

1. Edit your `.env` file for configuration.
2. Run:
   ```
   ./sail up -d
   ```

Frontend assets use Vite, Tailwind CSS, and Vue 3. See `package.json` for scripts and dependencies.

## Contribution & Support

- Active development: see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
- Support: [Discord](https://discord.gg/GjgGSzkrjh)

## License

NNTmux is GPL v3. See LICENSE for details. External libraries include their own licenses in respective folders.
