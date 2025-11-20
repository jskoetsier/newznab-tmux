#!/bin/bash

# NNTmux Deployment Script
# Automates deployment to remote server

set -e  # Exit on error

# Configuration
REMOTE_USER="root"
REMOTE_HOST="192.168.1.153"
REMOTE_PATH="/var/www/nntmux"
REMOTE_BACKUP_PATH="/var/www/nntmux-backups"
PROJECT_NAME="nntmux"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}NNTmux Deployment Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if SSH connection works
echo -e "${YELLOW}Checking SSH connection...${NC}"
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 ${REMOTE_USER}@${REMOTE_HOST} "echo 'SSH connection successful'" 2>/dev/null; then
    echo -e "${RED}Error: Cannot connect to ${REMOTE_HOST}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ SSH connection successful${NC}"

# Build assets locally
echo -e "${YELLOW}Building production assets...${NC}"
npm run build:production
echo -e "${GREEN}✓ Assets built successfully${NC}"

# Optimize composer
echo -e "${YELLOW}Optimizing Composer autoloader...${NC}"
composer install --no-dev --optimize-autoloader --no-interaction
echo -e "${GREEN}✓ Composer optimized${NC}"

# Run Laravel optimizations
echo -e "${YELLOW}Running Laravel optimizations...${NC}"
php artisan config:cache
php artisan route:cache
php artisan view:cache
echo -e "${GREEN}✓ Laravel optimizations complete${NC}"

# Create backup on remote server
echo -e "${YELLOW}Creating backup on remote server...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} "
    mkdir -p ${REMOTE_BACKUP_PATH}
    if [ -d ${REMOTE_PATH} ]; then
        BACKUP_FILE=${REMOTE_BACKUP_PATH}/backup-\$(date +%Y%m%d-%H%M%S).tar.gz
        tar -czf \${BACKUP_FILE} -C ${REMOTE_PATH} . 2>/dev/null || echo 'No existing installation to backup'
        echo 'Backup created: '\${BACKUP_FILE}
    fi
"
echo -e "${GREEN}✓ Backup created${NC}"

# Create remote directory if it doesn't exist
echo -e "${YELLOW}Preparing remote directory...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_PATH}"

# Sync files to remote server (excluding unnecessary files)
echo -e "${YELLOW}Syncing files to remote server...${NC}"
rsync -avz --delete \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='.env' \
    --exclude='storage/logs/*' \
    --exclude='storage/framework/cache/*' \
    --exclude='storage/framework/sessions/*' \
    --exclude='storage/framework/views/*' \
    --exclude='tests' \
    --exclude='.phpunit.result.cache' \
    --exclude='phpunit.xml' \
    ./ ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/

echo -e "${GREEN}✓ Files synced successfully${NC}"

# Run post-deployment commands on remote server
echo -e "${YELLOW}Running post-deployment commands...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} "
    cd ${REMOTE_PATH}

    # Copy .env if it doesn't exist
    if [ ! -f .env ]; then
        cp .env.example .env
        echo 'Created .env file - PLEASE CONFIGURE IT!'
    fi

    # Set proper permissions
    chown -R www-data:www-data ${REMOTE_PATH}
    chmod -R 755 ${REMOTE_PATH}
    chmod -R 775 ${REMOTE_PATH}/storage
    chmod -R 775 ${REMOTE_PATH}/bootstrap/cache

    # Install/update composer dependencies
    composer install --no-dev --optimize-autoloader --no-interaction

    # Generate app key if needed
    if grep -q 'APP_KEY=$' .env; then
        php artisan key:generate --force
    fi

    # Run migrations (with confirmation)
    # php artisan migrate --force

    # Clear and cache config
    php artisan config:clear
    php artisan cache:clear
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache

    # Optimize
    php artisan optimize

    # Restart services (adjust as needed for your setup)
    if command -v systemctl &> /dev/null; then
        systemctl restart php8.3-fpm 2>/dev/null || echo 'Could not restart PHP-FPM'
        systemctl restart nginx 2>/dev/null || echo 'Could not restart Nginx'
    fi

    echo 'Deployment completed successfully!'
"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Verify .env configuration on remote server"
echo -e "2. Run migrations if needed: ${YELLOW}php artisan migrate --force${NC}"
echo -e "3. Check application at: ${YELLOW}http://${REMOTE_HOST}${NC}"
echo -e "${GREEN}========================================${NC}"
