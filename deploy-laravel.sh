#!/bin/bash

################################################################################
# Laravel Deployment Automation Script
# 
# This script automates the deployment of Laravel applications on Linux servers
# It handles:
# - Repository cloning
# - Database setup (MySQL/PostgreSQL)
# - Apache/Nginx configuration
# - SSL certificate installation
# - File permissions and ownership
# - PHP dependencies via Composer
# - Laravel configuration and optimization
#
# Usage: sudo bash deploy-laravel.sh
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Helper Functions
################################################################################

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

################################################################################
# System Requirements Check
################################################################################

check_system_requirements() {
    print_header "Checking System Requirements"
    
    local missing_packages=()
    
    # Check for required commands
    if ! check_command "git"; then
        missing_packages+=("git")
    else
        print_success "Git is installed"
    fi
    
    if ! check_command "php"; then
        missing_packages+=("php")
    else
        PHP_VERSION=$(php -r "echo PHP_VERSION;")
        print_success "PHP ${PHP_VERSION} is installed"
    fi
    
    if ! check_command "composer"; then
        print_warning "Composer is not installed - will install it"
        INSTALL_COMPOSER=true
    else
        print_success "Composer is installed"
        INSTALL_COMPOSER=false
    fi
    
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        print_error "Missing required packages: ${missing_packages[*]}"
        print_info "Please install them first and try again"
        exit 1
    fi
}

################################################################################
# User Input Collection
################################################################################

collect_deployment_info() {
    print_header "Laravel Deployment Configuration"
    
    # Git repository
    read -p "Enter Git repository URL: " GIT_REPO
    if [[ -z "$GIT_REPO" ]]; then
        print_error "Repository URL is required"
        exit 1
    fi
    
    # Branch
    read -p "Enter branch to deploy (default: main): " GIT_BRANCH
    GIT_BRANCH=${GIT_BRANCH:-main}
    
    # Domain name
    read -p "Enter domain name (e.g., example.com): " DOMAIN_NAME
    if [[ -z "$DOMAIN_NAME" ]]; then
        print_error "Domain name is required"
        exit 1
    fi
    
    # Project name (derived from domain or custom)
    DEFAULT_PROJECT_NAME=$(echo "$DOMAIN_NAME" | sed 's/\./_/g')
    read -p "Enter project name (default: $DEFAULT_PROJECT_NAME): " PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-$DEFAULT_PROJECT_NAME}
    
    # Installation directory
    DEFAULT_INSTALL_DIR="/var/www/$PROJECT_NAME"
    read -p "Enter installation directory (default: $DEFAULT_INSTALL_DIR): " INSTALL_DIR
    INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}
    
    # Web server choice
    print_info "Select web server:"
    echo "1) Apache"
    echo "2) Nginx"
    read -p "Enter choice (1 or 2, default: 1): " WEB_SERVER_CHOICE
    WEB_SERVER_CHOICE=${WEB_SERVER_CHOICE:-1}
    
    if [[ "$WEB_SERVER_CHOICE" == "1" ]]; then
        WEB_SERVER="apache"
    elif [[ "$WEB_SERVER_CHOICE" == "2" ]]; then
        WEB_SERVER="nginx"
    else
        print_error "Invalid choice"
        exit 1
    fi
    
    # Database configuration
    print_info "Database Configuration:"
    echo "1) MySQL/MariaDB"
    echo "2) PostgreSQL"
    echo "3) Skip database setup"
    read -p "Enter choice (default: 1): " DB_CHOICE
    DB_CHOICE=${DB_CHOICE:-1}
    
    if [[ "$DB_CHOICE" == "1" ]]; then
        DB_TYPE="mysql"
    elif [[ "$DB_CHOICE" == "2" ]]; then
        DB_TYPE="postgresql"
    else
        DB_TYPE="none"
    fi
    
    if [[ "$DB_TYPE" != "none" ]]; then
        read -p "Enter database name (default: ${PROJECT_NAME}_db): " DB_NAME
        DB_NAME=${DB_NAME:-${PROJECT_NAME}_db}
        
        read -p "Enter database user (default: ${PROJECT_NAME}_user): " DB_USER
        DB_USER=${DB_USER:-${PROJECT_NAME}_user}
        
        read -sp "Enter database password: " DB_PASSWORD
        echo ""
        
        if [[ -z "$DB_PASSWORD" ]]; then
            DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
            print_info "Generated random database password: $DB_PASSWORD"
        fi
        
        read -p "Enter database host (default: localhost): " DB_HOST
        DB_HOST=${DB_HOST:-localhost}
    fi
    
    # SSL setup
    read -p "Setup SSL with Let's Encrypt? (y/n, default: y): " SETUP_SSL
    SETUP_SSL=${SETUP_SSL:-y}
    
    if [[ "$SETUP_SSL" == "y" || "$SETUP_SSL" == "Y" ]]; then
        read -p "Enter email for SSL certificate notifications: " SSL_EMAIL
        if [[ -z "$SSL_EMAIL" ]]; then
            print_warning "Email is required for Let's Encrypt"
            SETUP_SSL="n"
        fi
    fi
    
    # Confirm configuration
    print_header "Configuration Summary"
    echo "Repository: $GIT_REPO"
    echo "Branch: $GIT_BRANCH"
    echo "Domain: $DOMAIN_NAME"
    echo "Project Name: $PROJECT_NAME"
    echo "Install Directory: $INSTALL_DIR"
    echo "Web Server: $WEB_SERVER"
    echo "Database Type: $DB_TYPE"
    if [[ "$DB_TYPE" != "none" ]]; then
        echo "Database Name: $DB_NAME"
        echo "Database User: $DB_USER"
        echo "Database Host: $DB_HOST"
    fi
    echo "Setup SSL: $SETUP_SSL"
    echo ""
    
    read -p "Continue with deployment? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        print_info "Deployment cancelled"
        exit 0
    fi
}

################################################################################
# Composer Installation
################################################################################

install_composer() {
    if [[ "$INSTALL_COMPOSER" == true ]]; then
        print_header "Installing Composer"
        
        EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
        
        if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
            print_error "Composer installer corrupt"
            rm composer-setup.php
            exit 1
        fi
        
        php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
        rm composer-setup.php
        
        print_success "Composer installed successfully"
    fi
}

################################################################################
# Repository Cloning
################################################################################

clone_repository() {
    print_header "Cloning Repository"
    
    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Directory $INSTALL_DIR already exists"
        read -p "Remove and continue? (y/n): " REMOVE_DIR
        if [[ "$REMOVE_DIR" == "y" || "$REMOVE_DIR" == "Y" ]]; then
            rm -rf "$INSTALL_DIR"
            print_info "Removed existing directory"
        else
            print_error "Cannot proceed with existing directory"
            exit 1
        fi
    fi
    
    mkdir -p "$INSTALL_DIR"
    
    print_info "Cloning from $GIT_REPO (branch: $GIT_BRANCH)..."
    if ! git clone -b "$GIT_BRANCH" "$GIT_REPO" "$INSTALL_DIR"; then
        print_error "Failed to clone repository"
        print_info "Please check:"
        print_info "  - Repository URL is correct"
        print_info "  - Branch name exists"
        print_info "  - You have access (use SSH keys for private repos)"
        print_info "  - Network connectivity is available"
        exit 1
    fi
    
    print_success "Repository cloned successfully"
}

################################################################################
# Database Setup
################################################################################

setup_database() {
    if [[ "$DB_TYPE" == "none" ]]; then
        print_info "Skipping database setup"
        return
    fi
    
    print_header "Setting Up Database"
    
    if [[ "$DB_TYPE" == "mysql" ]]; then
        setup_mysql_database
    elif [[ "$DB_TYPE" == "postgresql" ]]; then
        setup_postgresql_database
    fi
}

setup_mysql_database() {
    print_info "Creating MySQL database and user..."
    
    # Check if MySQL root password is needed
    MYSQL_CMD="mysql"
    if ! mysql -e "SELECT 1;" &>/dev/null; then
        print_info "MySQL requires authentication"
        read -sp "Enter MySQL root password: " MYSQL_ROOT_PASS
        echo ""
        MYSQL_CMD="mysql -p${MYSQL_ROOT_PASS}"
    fi
    
    # Create database and user
    $MYSQL_CMD -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" || {
        print_error "Failed to create database"
        print_info "Please check MySQL root credentials and permissions"
        exit 1
    }
    
    $MYSQL_CMD -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASSWORD}';" || {
        print_error "Failed to create user"
        exit 1
    }
    
    $MYSQL_CMD -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'${DB_HOST}';" || {
        print_error "Failed to grant privileges"
        exit 1
    }
    
    $MYSQL_CMD -e "FLUSH PRIVILEGES;" || {
        print_error "Failed to flush privileges"
        exit 1
    }
    
    print_success "MySQL database created successfully"
}

setup_postgresql_database() {
    print_info "Creating PostgreSQL database and user..."
    
    # Create user and database
    sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';" 2>/dev/null || true
    sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" 2>/dev/null || {
        print_error "Failed to create database"
        exit 1
    }
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" || true
    
    print_success "PostgreSQL database created successfully"
}

################################################################################
# Laravel Environment Setup
################################################################################

setup_laravel_environment() {
    print_header "Configuring Laravel Environment"
    
    cd "$INSTALL_DIR" || exit 1
    
    # Copy .env file
    if [[ ! -f .env ]]; then
        if [[ -f .env.example ]]; then
            cp .env.example .env
            print_success "Created .env from .env.example"
        else
            print_warning ".env.example not found, creating basic .env"
            cat > .env << EOF
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://${DOMAIN_NAME}

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=${DB_TYPE}
DB_HOST=${DB_HOST}
DB_PORT=$([[ "$DB_TYPE" == "postgresql" ]] && echo "5432" || echo "3306")
DB_DATABASE=${DB_NAME}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DRIVER=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
EOF
        fi
    else
        print_info ".env file already exists, updating values..."
    fi
    
    # Update .env values
    if [[ "$DB_TYPE" != "none" ]]; then
        sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=${DB_TYPE}|" .env
        sed -i "s|^DB_HOST=.*|DB_HOST=${DB_HOST}|" .env
        sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" .env
        sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" .env
        sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|" .env
        if [[ "$DB_TYPE" == "postgresql" ]]; then
            sed -i "s|^DB_PORT=.*|DB_PORT=5432|" .env
        else
            sed -i "s|^DB_PORT=.*|DB_PORT=3306|" .env
        fi
    fi
    
    sed -i "s|^APP_URL=.*|APP_URL=https://${DOMAIN_NAME}|" .env
    sed -i "s|^APP_ENV=.*|APP_ENV=production|" .env
    sed -i "s|^APP_DEBUG=.*|APP_DEBUG=false|" .env
    
    print_success "Environment file configured"
}

################################################################################
# Install Dependencies
################################################################################

install_dependencies() {
    print_header "Installing Dependencies"
    
    cd "$INSTALL_DIR" || exit 1
    
    print_info "Installing Composer dependencies..."
    composer install --no-dev --optimize-autoloader --no-interaction
    
    print_success "Dependencies installed successfully"
}

################################################################################
# Laravel Setup Commands
################################################################################

run_laravel_commands() {
    print_header "Running Laravel Setup Commands"
    
    cd "$INSTALL_DIR" || exit 1
    
    # Generate application key
    print_info "Generating application key..."
    php artisan key:generate --force
    print_success "Application key generated"
    
    # Run migrations (if database is configured)
    if [[ "$DB_TYPE" != "none" ]]; then
        print_info "Running database migrations..."
        php artisan migrate --force
        print_success "Database migrations completed"
    fi
    
    # Clear and cache config
    print_info "Optimizing application..."
    php artisan config:clear
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    
    print_success "Laravel application optimized"
}

################################################################################
# Set File Permissions
################################################################################

set_permissions() {
    print_header "Setting File Permissions"
    
    cd "$INSTALL_DIR" || exit 1
    
    # Determine web server user
    if [[ "$WEB_SERVER" == "apache" ]]; then
        WEB_USER="www-data"
    elif [[ "$WEB_SERVER" == "nginx" ]]; then
        WEB_USER="www-data"
    fi
    
    # Check if user exists
    if ! id "$WEB_USER" &>/dev/null; then
        WEB_USER="nginx"
        if ! id "$WEB_USER" &>/dev/null; then
            WEB_USER="apache"
            if ! id "$WEB_USER" &>/dev/null; then
                print_warning "Could not determine web server user, using root"
                WEB_USER="root"
            fi
        fi
    fi
    
    print_info "Setting owner to $WEB_USER..."
    chown -R "$WEB_USER":"$WEB_USER" "$INSTALL_DIR"
    
    print_info "Setting directory permissions..."
    find "$INSTALL_DIR" -type d -exec chmod 755 {} \;
    
    print_info "Setting file permissions..."
    find "$INSTALL_DIR" -type f -exec chmod 644 {} \;
    
    print_info "Setting storage and cache permissions..."
    chmod -R 775 "$INSTALL_DIR/storage"
    chmod -R 775 "$INSTALL_DIR/bootstrap/cache"
    
    print_success "Permissions set successfully"
}

################################################################################
# Apache Configuration
################################################################################

configure_apache() {
    print_header "Configuring Apache"
    
    # Check if Apache is installed
    if ! check_command "apache2" && ! check_command "httpd"; then
        print_error "Apache is not installed"
        print_info "Please install Apache and try again"
        exit 1
    fi
    
    # Determine Apache config directory
    if [[ -d "/etc/apache2/sites-available" ]]; then
        APACHE_SITES_DIR="/etc/apache2/sites-available"
        APACHE_SITES_ENABLED="/etc/apache2/sites-enabled"
        APACHE_SERVICE="apache2"
    elif [[ -d "/etc/httpd/conf.d" ]]; then
        APACHE_SITES_DIR="/etc/httpd/conf.d"
        APACHE_SERVICE="httpd"
    else
        print_error "Could not find Apache configuration directory"
        exit 1
    fi
    
    CONFIG_FILE="$APACHE_SITES_DIR/${DOMAIN_NAME}.conf"
    
    print_info "Creating Apache virtual host configuration..."
    
    cat > "$CONFIG_FILE" << EOF
<VirtualHost *:80>
    ServerName ${DOMAIN_NAME}
    ServerAlias www.${DOMAIN_NAME}
    DocumentRoot ${INSTALL_DIR}/public

    <Directory ${INSTALL_DIR}/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/${DOMAIN_NAME}-error.log
    CustomLog \${APACHE_LOG_DIR}/${DOMAIN_NAME}-access.log combined
</VirtualHost>
EOF
    
    print_success "Apache configuration created"
    
    # Enable site (Debian/Ubuntu style)
    if [[ -d "$APACHE_SITES_ENABLED" ]]; then
        a2ensite "${DOMAIN_NAME}.conf"
        a2enmod rewrite
    fi
    
    # Test configuration
    if check_command "apache2"; then
        apache2ctl configtest
    elif check_command "httpd"; then
        httpd -t
    fi
    
    # Restart Apache
    print_info "Restarting Apache..."
    systemctl restart "$APACHE_SERVICE"
    
    print_success "Apache configured and restarted"
}

################################################################################
# Nginx Configuration
################################################################################

configure_nginx() {
    print_header "Configuring Nginx"
    
    # Check if Nginx is installed
    if ! check_command "nginx"; then
        print_error "Nginx is not installed"
        print_info "Please install Nginx and try again"
        exit 1
    fi
    
    NGINX_SITES_DIR="/etc/nginx/sites-available"
    NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"
    
    # Create sites directories if they don't exist
    mkdir -p "$NGINX_SITES_DIR"
    mkdir -p "$NGINX_SITES_ENABLED"
    
    # Detect PHP-FPM socket
    PHP_FPM_SOCKET="/var/run/php/php-fpm.sock"
    if [[ -S "/var/run/php/php-fpm.sock" ]]; then
        PHP_FPM_SOCKET="/var/run/php/php-fpm.sock"
    elif [[ -S "/run/php/php-fpm.sock" ]]; then
        PHP_FPM_SOCKET="/run/php/php-fpm.sock"
    else
        # Try to find versioned PHP-FPM sockets
        for socket in /var/run/php/php*-fpm.sock /run/php/php*-fpm.sock; do
            if [[ -S "$socket" ]]; then
                PHP_FPM_SOCKET="$socket"
                break
            fi
        done
    fi
    
    print_info "Using PHP-FPM socket: $PHP_FPM_SOCKET"
    
    CONFIG_FILE="$NGINX_SITES_DIR/${DOMAIN_NAME}"
    
    print_info "Creating Nginx server block configuration..."
    
    cat > "$CONFIG_FILE" << EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN_NAME} www.${DOMAIN_NAME};
    root ${INSTALL_DIR}/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:${PHP_FPM_SOCKET};
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_index index.php;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
    
    print_success "Nginx configuration created"
    
    # Enable site
    ln -sf "$CONFIG_FILE" "$NGINX_SITES_ENABLED/${DOMAIN_NAME}"
    
    # Test configuration
    print_info "Testing Nginx configuration..."
    if ! nginx -t; then
        print_error "Nginx configuration test failed"
        print_info "Please check the configuration file: $CONFIG_FILE"
        exit 1
    fi
    
    print_success "Nginx configuration test passed"
    
    # Restart Nginx
    print_info "Restarting Nginx..."
    if ! systemctl restart nginx; then
        print_error "Failed to restart Nginx"
        exit 1
    fi
    
    print_success "Nginx configured and restarted"
}

################################################################################
# SSL Configuration with Let's Encrypt
################################################################################

setup_ssl() {
    if [[ "$SETUP_SSL" != "y" && "$SETUP_SSL" != "Y" ]]; then
        print_info "Skipping SSL setup"
        return
    fi
    
    print_header "Setting Up SSL Certificate"
    
    # Check if certbot is installed
    if ! check_command "certbot"; then
        print_warning "Certbot is not installed"
        print_info "Installing certbot..."
        
        if check_command "apt-get"; then
            apt-get update
            apt-get install -y certbot
            
            if [[ "$WEB_SERVER" == "apache" ]]; then
                apt-get install -y python3-certbot-apache
            elif [[ "$WEB_SERVER" == "nginx" ]]; then
                apt-get install -y python3-certbot-nginx
            fi
        elif check_command "yum"; then
            yum install -y certbot
            
            if [[ "$WEB_SERVER" == "apache" ]]; then
                yum install -y python3-certbot-apache
            elif [[ "$WEB_SERVER" == "nginx" ]]; then
                yum install -y python3-certbot-nginx
            fi
        else
            print_error "Could not install certbot automatically"
            print_info "Please install certbot manually and run it with:"
            print_info "certbot --${WEB_SERVER} -d ${DOMAIN_NAME} -d www.${DOMAIN_NAME}"
            return
        fi
    fi
    
    print_info "Obtaining SSL certificate from Let's Encrypt..."
    
    if [[ "$WEB_SERVER" == "apache" ]]; then
        certbot --apache --non-interactive --agree-tos --email "$SSL_EMAIL" \
            -d "$DOMAIN_NAME" -d "www.$DOMAIN_NAME" --redirect
    elif [[ "$WEB_SERVER" == "nginx" ]]; then
        certbot --nginx --non-interactive --agree-tos --email "$SSL_EMAIL" \
            -d "$DOMAIN_NAME" -d "www.$DOMAIN_NAME" --redirect
    fi
    
    if [[ $? -eq 0 ]]; then
        print_success "SSL certificate installed successfully"
        print_info "Certificate will auto-renew via certbot"
    else
        print_warning "SSL certificate installation failed"
        print_info "You may need to configure DNS records and try again"
    fi
}

################################################################################
# Deployment Summary
################################################################################

print_deployment_summary() {
    print_header "Deployment Complete!"
    
    echo ""
    print_success "Laravel application deployed successfully!"
    echo ""
    echo "Application Details:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Domain:           $DOMAIN_NAME"
    echo "Installation:     $INSTALL_DIR"
    echo "Web Server:       $WEB_SERVER"
    
    if [[ "$DB_TYPE" != "none" ]]; then
        echo ""
        echo "Database Details:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Type:            $DB_TYPE"
        echo "Database:        $DB_NAME"
        echo "User:            $DB_USER"
        echo "Password:        $DB_PASSWORD"
        echo "Host:            $DB_HOST"
    fi
    
    echo ""
    echo "Next Steps:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Point your domain DNS to this server's IP address"
    echo "2. Visit https://${DOMAIN_NAME} to access your application"
    echo "3. Review your .env file at: ${INSTALL_DIR}/.env"
    echo "4. Configure any additional Laravel services as needed"
    echo ""
    
    if [[ "$SETUP_SSL" == "y" || "$SETUP_SSL" == "Y" ]]; then
        print_info "SSL certificate will auto-renew. Check with: certbot renew --dry-run"
    fi
    
    echo ""
    print_success "Happy coding! 🚀"
    echo ""
}

################################################################################
# Main Execution Flow
################################################################################

main() {
    print_header "Laravel Deployment Automation Script"
    
    # Check if running as root
    check_root
    
    # Check system requirements
    check_system_requirements
    
    # Collect deployment information
    collect_deployment_info
    
    # Install Composer if needed
    install_composer
    
    # Clone repository
    clone_repository
    
    # Setup database
    setup_database
    
    # Configure Laravel environment
    setup_laravel_environment
    
    # Install dependencies
    install_dependencies
    
    # Run Laravel commands
    run_laravel_commands
    
    # Set file permissions
    set_permissions
    
    # Configure web server
    if [[ "$WEB_SERVER" == "apache" ]]; then
        configure_apache
    elif [[ "$WEB_SERVER" == "nginx" ]]; then
        configure_nginx
    fi
    
    # Setup SSL
    setup_ssl
    
    # Print summary
    print_deployment_summary
}

# Run main function
main "$@"
