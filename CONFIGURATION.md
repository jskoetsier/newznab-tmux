# NNTmux Configuration Guide

> **Last Updated**: November 21, 2025
> **Version**: 2.0.0

## Table of Contents

1. [Environment Configuration](#environment-configuration)
2. [Database Configuration](#database-configuration)
3. [Cache Configuration](#cache-configuration)
4. [Search Engine Configuration](#search-engine-configuration)
5. [NNTP Server Configuration](#nntp-server-configuration)
6. [API Configuration](#api-configuration)
7. [Mail Configuration](#mail-configuration)
8. [Queue Configuration](#queue-configuration)
9. [File Storage Configuration](#file-storage-configuration)
10. [Security Configuration](#security-configuration)

---

## Environment Configuration

### Basic Setup

Copy the example environment file and configure it:

```bash
cp .env.example .env
php artisan key:generate
```

### Essential Environment Variables

```env
# Application
APP_NAME="NNTmux"
APP_ENV=production
APP_KEY=base64:YOUR_GENERATED_KEY
APP_DEBUG=false
APP_URL=https://your-domain.com

# Database
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=nntmux
DB_USERNAME=nntmux_user
DB_PASSWORD=secure_password

# Redis
REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

# Cache
CACHE_DRIVER=redis
CACHE_PREFIX=nntmux_cache

# Queue
QUEUE_CONNECTION=redis
QUEUE_FAILED_DRIVER=database-uuids

# Session
SESSION_DRIVER=redis
SESSION_LIFETIME=120

# Search Engine
SCOUT_DRIVER=elasticsearch
# OR
# SCOUT_DRIVER=manticoresearch
```

---

## Database Configuration

### MySQL/MariaDB Setup

#### 1. Create Database and User

```sql
CREATE DATABASE nntmux CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'nntmux_user'@'localhost' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON nntmux.* TO 'nntmux_user'@'localhost';
FLUSH PRIVILEGES;
```

#### 2. Recommended MySQL Configuration

Edit `/etc/mysql/my.cnf` or `/etc/my.cnf`:

```ini
[mysqld]
# Performance
innodb_buffer_pool_size = 4G
innodb_log_file_size = 512M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Connections
max_connections = 500
max_allowed_packet = 64M

# Query Cache (if using MySQL < 8.0)
query_cache_type = 1
query_cache_size = 256M

# Character Set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

#### 3. Run Migrations

```bash
php artisan migrate --force
```

### Database Optimization

```bash
# Optimize tables regularly
php artisan db:optimize

# Analyze tables for query optimization
mysqlcheck -o --all-databases -u root -p
```

---

## Cache Configuration

### Redis Setup

#### Installation

```bash
# Ubuntu/Debian
sudo apt install redis-server

# Start Redis
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

#### Redis Configuration

Edit `/etc/redis/redis.conf`:

```conf
# Memory
maxmemory 2gb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000

# Performance
tcp-backlog 511
timeout 300
```

#### Laravel Cache Configuration

`config/cache.php`:

```php
'default' => env('CACHE_DRIVER', 'redis'),

'stores' => [
    'redis' => [
        'driver' => 'redis',
        'connection' => 'cache',
        'lock_connection' => 'default',
    ],
],

'prefix' => env('CACHE_PREFIX', 'nntmux_cache'),
```

### Cache Management Commands

```bash
# Clear all cache
php artisan cache:clear

# Clear specific cache
php artisan cache:forget 'key'

# Warm up cache
php artisan cache:warmup
```

---

## Search Engine Configuration

### Option 1: ElasticSearch (Recommended)

#### Installation

```bash
# Ubuntu/Debian
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt update && sudo apt install elasticsearch

# Start ElasticSearch
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch
```

#### Configuration

`.env`:
```env
SCOUT_DRIVER=elasticsearch
ELASTICSEARCH_HOST=localhost:9200
ELASTICSEARCH_INDEX=nntmux
```

`config/scout.php`:
```php
'elasticsearch' => [
    'hosts' => [
        env('ELASTICSEARCH_HOST', 'localhost:9200'),
    ],
    'index' => env('ELASTICSEARCH_INDEX', 'nntmux'),
],
```

#### Index Creation

```bash
php artisan scout:import "App\Models\Release"
```

### Option 2: Manticore Search

#### Installation

```bash
# Ubuntu/Debian
wget https://repo.manticoresearch.com/manticore-repo.noarch.deb
sudo dpkg -i manticore-repo.noarch.deb
sudo apt update && sudo apt install manticore

# Start Manticore
sudo systemctl start manticore
sudo systemctl enable manticore
```

#### Configuration

`.env`:
```env
SCOUT_DRIVER=manticoresearch
MANTICORE_HOST=127.0.0.1
MANTICORE_PORT=9308
```

---

## NNTP Server Configuration

### Adding NNTP Providers

#### Via Web Interface

1. Navigate to: Admin → Site Settings → NNTP Server
2. Fill in the details:
   - **Server**: news.provider.com
   - **Port**: 563 (SSL) or 119 (non-SSL)
   - **Username**: your_username
   - **Password**: your_password
   - **Connections**: 20 (recommended)

#### Via Environment

`.env`:
```env
NNTP_SERVER=news.provider.com
NNTP_PORT=563
NNTP_USERNAME=your_username
NNTP_PASSWORD=your_password
NNTP_SSLENABLED=true
NNTP_MAX_CONNECTIONS=20
```

### Multiple NNTP Servers

Configure in database `nntp_servers` table or via admin panel:

```sql
INSERT INTO nntp_servers (server, port, username, password, sslenabled, active)
VALUES ('news.provider.com', 563, 'user', 'pass', 1, 1);
```

---

## API Configuration

### API Keys

#### Generating API Keys

```bash
# Generate personal access token
php artisan tinker
>>> $user = \App\Models\User::find(1);
>>> $token = $user->createToken('API Token')->plainTextToken;
>>> echo $token;
```

### Rate Limiting

`config/api.php`:
```php
'rate_limits' => [
    'anonymous' => 60,      // 60 requests per hour
    'authenticated' => 1000, // 1000 requests per hour
    'admin' => null,        // Unlimited
],
```

### API Documentation

Access API documentation at: `https://your-domain.com/api/docs`

---

## Mail Configuration

### SMTP Configuration

`.env`:
```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@your-domain.com
MAIL_FROM_NAME="${APP_NAME}"
```

### Testing Email Configuration

```bash
php artisan tinker
>>> Mail::raw('Test email', function ($message) {
    $message->to('test@example.com')->subject('Test');
});
```

---

## Queue Configuration

### Supervisor Setup

#### Installation

```bash
sudo apt install supervisor
```

#### Configuration

Create `/etc/supervisor/conf.d/nntmux-worker.conf`:

```ini
[program:nntmux-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/nntmux/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=4
redirect_stderr=true
stdout_logfile=/path/to/nntmux/storage/logs/worker.log
stopwaitsecs=3600
```

#### Start Workers

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start nntmux-worker:*
```

### Queue Monitoring

```bash
# View queue status
php artisan queue:monitor

# View failed jobs
php artisan queue:failed

# Retry failed jobs
php artisan queue:retry all
```

---

## File Storage Configuration

### Local Storage

`.env`:
```env
FILESYSTEM_DISK=local
```

### S3 Storage

`.env`:
```env
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=your-bucket-name
AWS_USE_PATH_STYLE_ENDPOINT=false
```

### Storage Directories

Ensure proper permissions:

```bash
chmod -R 775 storage
chmod -R 775 bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

---

## Security Configuration

### HTTPS Configuration

#### Nginx Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /path/to/nntmux/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

### CSRF Protection

Enabled by default. Configure in `config/session.php`:

```php
'secure' => env('SESSION_SECURE_COOKIE', true),
'same_site' => 'lax',
```

### Two-Factor Authentication

Enable 2FA in admin panel:
1. Navigate to: Profile → Security
2. Enable Two-Factor Authentication
3. Scan QR code with Google Authenticator

---

## Performance Tuning

### PHP Configuration

Edit `php.ini`:

```ini
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
post_max_size = 64M
upload_max_filesize = 64M

; OPcache
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
```

### Laravel Optimization

```bash
# Production optimization
php artisan config:cache
php artisan route:cache
php artisan view:cache
composer install --optimize-autoloader --no-dev
```

---

## Backup Configuration

### Database Backup

Create backup script `/usr/local/bin/backup-nntmux.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/backups/nntmux"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup database
mysqldump -u nntmux_user -p nntmux > $BACKUP_DIR/db_$DATE.sql

# Backup .env and storage
tar -czf $BACKUP_DIR/files_$DATE.tar.gz /path/to/nntmux/.env /path/to/nntmux/storage

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

Add to crontab:
```bash
0 2 * * * /usr/local/bin/backup-nntmux.sh
```

---

## Monitoring Configuration

### Application Monitoring

Install Laravel Telescope (development only):

```bash
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate
```

### Log Monitoring

Configure in `config/logging.php`:

```php
'channels' => [
    'daily' => [
        'driver' => 'daily',
        'path' => storage_path('logs/laravel.log'),
        'level' => env('LOG_LEVEL', 'debug'),
        'days' => 14,
    ],
],
```

### System Monitoring

Use tools like:
- **New Relic**: Application performance monitoring
- **Sentry**: Error tracking
- **Grafana**: Metrics visualization

---

## Troubleshooting

### Common Issues

#### Permission Errors

```bash
sudo chown -R www-data:www-data /path/to/nntmux
sudo chmod -R 775 /path/to/nntmux/storage
sudo chmod -R 775 /path/to/nntmux/bootstrap/cache
```

#### Cache Issues

```bash
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

#### Queue Not Processing

```bash
# Check supervisor status
sudo supervisorctl status

# Restart workers
sudo supervisorctl restart nntmux-worker:*
```

#### Database Connection Issues

```bash
# Test connection
php artisan tinker
>>> DB::connection()->getPdo();
```

---

## Additional Resources

- [Laravel Configuration Documentation](https://laravel.com/docs/11.x/configuration)
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide
- [SECURITY.md](SECURITY.md) - Security best practices

---

<p align="center">
    <strong>Built with ❤️ by the NNTmux Community</strong>
</p>

<p align="center">
    <sub>Last Updated: November 21, 2025 | Version 2.0.0</sub>
</p>
