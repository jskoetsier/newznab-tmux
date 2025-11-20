#!/bin/bash

# NNTmux Podman Deployment Script for Ubuntu 25.04
# Deploys application to remote server using git pull and Podman

set -e  # Exit on error

# Configuration
REMOTE_USER="root"
REMOTE_HOST="192.168.1.153"
REMOTE_PATH="/opt/nntmux"
PROJECT_NAME="nntmux"
GIT_REPO_URL="$(git config --get remote.origin.url)"

# Convert SSH URL to HTTPS for remote cloning
if [[ $GIT_REPO_URL == git@github.com:* ]]; then
    GIT_REPO_URL=$(echo $GIT_REPO_URL | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//')
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}NNTmux Podman Deployment Script${NC}"
echo -e "${GREEN}Target: Ubuntu 25.04 with Podman${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if SSH connection works
echo -e "${YELLOW}[1/6] Checking SSH connection...${NC}"
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 ${REMOTE_USER}@${REMOTE_HOST} "echo 'SSH connection successful'" 2>/dev/null; then
    echo -e "${RED}Error: Cannot connect to ${REMOTE_HOST}${NC}"
    exit 1
fi
echo -e "${GREEN}✓ SSH connection successful${NC}"

# Get current git branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo -e "${BLUE}Current branch: ${CURRENT_BRANCH}${NC}"

# Deploy to remote server
echo -e "${YELLOW}[2/6] Setting up repository on remote server...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} bash << EOF
    set -e

    # Install required packages if needed
    echo "Checking for required packages..."
    if ! command -v git &> /dev/null; then
        echo "Installing git..."
        apt update && apt install -y git
    fi

    if ! command -v podman &> /dev/null; then
        echo "Installing podman..."
        apt update && apt install -y podman podman-compose
    fi

    # Clone or update repository
    if [ ! -d ${REMOTE_PATH} ]; then
        echo "Cloning repository..."
        git clone ${GIT_REPO_URL} ${REMOTE_PATH}
        cd ${REMOTE_PATH}
        git checkout ${CURRENT_BRANCH}
    else
        echo "Repository exists, pulling latest changes..."
        cd ${REMOTE_PATH}
        git fetch origin
        git reset --hard origin/${CURRENT_BRANCH}
        git pull origin ${CURRENT_BRANCH}
    fi

    echo "✓ Repository updated successfully"
EOF

echo -e "${GREEN}✓ Repository setup complete${NC}"

# Install system dependencies and build
echo -e "${YELLOW}[3/6] Installing system dependencies on remote server...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} bash << 'EOF'
    set -e

    # Install PHP 8.3 and required extensions
    if ! command -v php &> /dev/null; then
        echo "Installing PHP 8.3 and extensions..."
        apt update
        apt install -y software-properties-common
        add-apt-repository -y ppa:ondrej/php
        apt update
        apt install -y php8.3 php8.3-cli php8.3-common php8.3-curl php8.3-mbstring \
            php8.3-xml php8.3-zip php8.3-gd php8.3-mysql php8.3-bcmath \
            php8.3-intl php8.3-soap php8.3-redis php8.3-imagick \
            php8.3-fpm php8.3-pdo php8.3-exif php8.3-sockets \
            unzip curl wget
    fi

    cd /opt/nntmux

    # Check for Composer
    if ! command -v composer &> /dev/null; then
        echo "Installing Composer..."
        curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
    fi

    # Check for Node.js
    if ! command -v node &> /dev/null; then
        echo "Installing Node.js 21..."
        curl -fsSL https://deb.nodesource.com/setup_21.x | bash -
        apt install -y nodejs
    fi

    # Install PHP dependencies
    echo "Installing Composer dependencies..."
    composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

    # Install Node dependencies
    echo "Installing Node dependencies..."
    npm install

    # Build assets
    echo "Building production assets..."
    npm run build:production

    echo "✓ Dependencies installed and assets built"
EOF

echo -e "${GREEN}✓ Dependencies installed${NC}"

# Configure environment
echo -e "${YELLOW}[4/6] Configuring environment...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} bash << 'EOF'
    set -e
    cd /opt/nntmux

    # Create .env if it doesn't exist
    if [ ! -f .env ]; then
        echo "Creating .env file from .env.example..."
        cp .env.example .env
        php artisan key:generate --force
        echo "⚠ IMPORTANT: Configure .env file with your database and settings!"
    else
        echo ".env file already exists"
    fi

    # Set proper permissions
    echo "Setting permissions..."
    chmod -R 755 /opt/nntmux

    # Create required directories
    mkdir -p storage/framework/{cache,sessions,views}
    mkdir -p storage/logs
    mkdir -p bootstrap/cache

    chmod -R 775 storage bootstrap/cache

    echo "✓ Environment configured"
EOF

echo -e "${GREEN}✓ Environment configured${NC}"

# Build and run with Podman
echo -e "${YELLOW}[5/6] Building and deploying with Podman...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} bash << 'EOF'
    set -e
    cd /opt/nntmux

    # Stop existing containers
    echo "Stopping existing containers..."
    podman-compose down 2>/dev/null || true

    # Build with Podman
    echo "Building image with Podman..."
    podman build -t nntmux:latest -f Dockerfile .

    # Check if docker-compose.yml exists
    if [ -f docker-compose.yml ]; then
        COMPOSE_FILE="docker-compose.yml"
    elif [ -f docker-compose.yml.prod-dist ]; then
        echo "Creating docker-compose.yml from prod-dist..."
        cp docker-compose.yml.prod-dist docker-compose.yml
        COMPOSE_FILE="docker-compose.yml"
    elif [ -f docker-compose.yml.dist ]; then
        echo "Creating docker-compose.yml from dist..."
        cp docker-compose.yml.dist docker-compose.yml
        COMPOSE_FILE="docker-compose.yml"
    else
        echo "No docker-compose.yml file found"
        COMPOSE_FILE=""
    fi

    # Start containers with Podman Compose
    if [ -n "$COMPOSE_FILE" ]; then
        echo "Starting containers with podman-compose..."
        podman-compose up -d
    else
        echo "⚠ No compose file available. Run container manually with:"
        echo "  podman run -d -p 80:80 --name nntmux nntmux:latest"
    fi

    echo "✓ Podman deployment complete"
EOF

echo -e "${GREEN}✓ Podman deployment complete${NC}"

# Run post-deployment tasks
echo -e "${YELLOW}[6/6] Running post-deployment tasks...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} bash << 'EOF'
    set -e
    cd /opt/nntmux

    # Laravel optimizations
    echo "Running Laravel optimizations..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    php artisan optimize

    # Note: migrations should be run manually after verifying .env
    # php artisan migrate --force

    echo "✓ Post-deployment tasks complete"
EOF

echo -e "${GREEN}✓ Post-deployment tasks complete${NC}"

# Display final status
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}Deployment Information:${NC}"
echo -e "  Server: ${REMOTE_HOST}"
echo -e "  Path: ${REMOTE_PATH}"
echo -e "  Branch: ${CURRENT_BRANCH}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Configure .env on remote server:"
echo -e "   ${BLUE}ssh ${REMOTE_USER}@${REMOTE_HOST} 'nano ${REMOTE_PATH}/.env'${NC}"
echo ""
echo -e "2. Run database migrations:"
echo -e "   ${BLUE}ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ${REMOTE_PATH} && php artisan migrate --force'${NC}"
echo ""
echo -e "3. Check Podman containers:"
echo -e "   ${BLUE}ssh ${REMOTE_USER}@${REMOTE_HOST} 'podman ps'${NC}"
echo ""
echo -e "4. View logs:"
echo -e "   ${BLUE}ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ${REMOTE_PATH} && podman-compose logs -f'${NC}"
echo ""
echo -e "5. Access application at: ${GREEN}http://${REMOTE_HOST}${NC}"
echo -e "${GREEN}========================================${NC}"
