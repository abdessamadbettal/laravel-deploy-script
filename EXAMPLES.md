# Deployment Examples

This document provides real-world examples of using the Laravel deployment script.

## Example 1: Basic Deployment with Apache and MySQL

This example shows a basic deployment using Apache web server and MySQL database.

```bash
sudo ./deploy-laravel.sh
```

**Input values:**
```
Git repository URL: https://github.com/yourusername/blog-app.git
Branch: main
Domain: blog.example.com
Project name: blog_app
Installation directory: /var/www/blog_app
Web server: 1 (Apache)
Database: 1 (MySQL)
Database name: blog_app_db
Database user: blog_app_user
Database password: [enter secure password]
Database host: localhost
Setup SSL: y
Email: admin@example.com
```

**Result:**
- Application deployed to `/var/www/blog_app`
- Accessible at `https://blog.example.com`
- MySQL database configured and migrated
- SSL certificate installed and configured

## Example 2: Nginx with PostgreSQL

Deploy using Nginx and PostgreSQL database.

```bash
sudo ./deploy-laravel.sh
```

**Input values:**
```
Git repository URL: https://github.com/company/crm-system.git
Branch: production
Domain: crm.company.com
Project name: crm_system
Installation directory: /var/www/crm
Web server: 2 (Nginx)
Database: 2 (PostgreSQL)
Database name: crm_db
Database user: crm_user
Database password: [secure password]
Database host: localhost
Setup SSL: y
Email: devops@company.com
```

**Result:**
- Application deployed to `/var/www/crm`
- Nginx server block configured
- PostgreSQL database created
- SSL enabled with automatic renewal

## Example 3: Deployment Without Database

Deploy a stateless Laravel application without database setup.

```bash
sudo ./deploy-laravel.sh
```

**Input values:**
```
Git repository URL: https://github.com/user/api-gateway.git
Branch: main
Domain: api.example.com
Project name: api_gateway
Installation directory: /var/www/api
Web server: 2 (Nginx)
Database: 3 (Skip database setup)
Setup SSL: y
Email: api-admin@example.com
```

**Result:**
- Application deployed without database configuration
- Ready for external database or API-only service

## Example 4: Development/Staging Deployment

Deploy to a staging environment with custom branch.

```bash
sudo ./deploy-laravel.sh
```

**Input values:**
```
Git repository URL: https://github.com/team/ecommerce.git
Branch: develop
Domain: staging.shop.com
Project name: shop_staging
Installation directory: /var/www/staging
Web server: 1 (Apache)
Database: 1 (MySQL)
Database name: shop_staging_db
Database user: shop_staging_user
Database password: [auto-generated]
Database host: localhost
Setup SSL: n (No SSL for staging)
```

**Result:**
- Staging environment deployed
- Using develop branch
- No SSL (suitable for internal testing)

## Example 5: Multiple Applications on Same Server

Deploy multiple Laravel applications on the same server.

### First Application:
```bash
sudo ./deploy-laravel.sh
```
```
Domain: app1.example.com
Installation directory: /var/www/app1
Database name: app1_db
```

### Second Application:
```bash
sudo ./deploy-laravel.sh
```
```
Domain: app2.example.com
Installation directory: /var/www/app2
Database name: app2_db
```

**Result:**
- Both applications running independently
- Separate databases and configurations
- Each with its own SSL certificate

## Pre-Deployment Checklist

Before running the deployment script:

- [ ] Git repository is accessible
- [ ] Domain DNS is configured (or will be after deployment)
- [ ] Server has sufficient resources (disk space, RAM)
- [ ] Required ports are open (80, 443)
- [ ] PHP and extensions are installed
- [ ] Database server is installed and running
- [ ] You have root/sudo access
- [ ] .env.example exists in repository (recommended)

## Post-Deployment Verification

After deployment, verify the installation:

1. **Check web server status:**
   ```bash
   systemctl status apache2  # or nginx
   ```

2. **Test database connection:**
   ```bash
   cd /var/www/your-project
   php artisan tinker
   >>> DB::connection()->getPdo();
   ```

3. **Check Laravel logs:**
   ```bash
   tail -f /var/www/your-project/storage/logs/laravel.log
   ```

4. **Verify SSL certificate:**
   ```bash
   certbot certificates
   ```

5. **Test application:**
   ```bash
   curl -I https://yourdomain.com
   ```

## Common Scenarios

### Deploying from Private Repository

If your repository is private, set up SSH keys first:

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "server@example.com"

# Add key to GitHub/GitLab
cat ~/.ssh/id_ed25519.pub
# Copy and add to your Git provider

# Use SSH URL when prompted
# Git repository URL: git@github.com:username/private-repo.git
```

### Using Custom Domain Port

If your application needs a custom port, modify after deployment:

```bash
# For Nginx
sudo nano /etc/nginx/sites-available/yourdomain.com
# Change: listen 8080;

sudo systemctl restart nginx
```

### Deploying with Existing Database

To use an existing database:

1. Choose "Skip database setup" during deployment
2. Manually edit `.env` file with your database credentials:
   ```bash
   cd /var/www/your-project
   sudo nano .env
   ```

### Configuring Queue Workers

After deployment, set up queue workers if needed:

```bash
# Create supervisor config
sudo nano /etc/supervisor/conf.d/laravel-worker.conf
```

```ini
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/your-project/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/your-project/storage/logs/worker.log
```

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start laravel-worker:*
```

## Troubleshooting Examples

### Issue: Permission Denied

```bash
# Fix storage permissions
cd /var/www/your-project
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

### Issue: 500 Internal Server Error

```bash
# Check Laravel logs
tail -100 /var/www/your-project/storage/logs/laravel.log

# Check web server logs
sudo tail -100 /var/log/apache2/error.log  # or nginx
```

### Issue: Database Connection Failed

```bash
# Test MySQL connection
mysql -u your_db_user -p your_db_name

# Check .env configuration
cd /var/www/your-project
cat .env | grep DB_
```

### Issue: Composer Install Fails

```bash
# Manually run composer
cd /var/www/your-project
sudo -u www-data composer install --no-dev --optimize-autoloader

# If memory issues:
sudo php -d memory_limit=512M /usr/local/bin/composer install
```

## Performance Optimization

After deployment, consider these optimizations:

```bash
cd /var/www/your-project

# Enable OPcache (edit php.ini)
# opcache.enable=1
# opcache.memory_consumption=128

# Use Redis for cache (if available)
sudo apt install redis-server
# Update .env: CACHE_DRIVER=redis

# Configure queue workers for async jobs
# QUEUE_CONNECTION=redis

# Enable Laravel Octane (for high performance)
composer require laravel/octane
php artisan octane:install
```

## Updating Deployed Application

```bash
cd /var/www/your-project

# Pull latest code
sudo -u www-data git pull origin main

# Update dependencies
sudo -u www-data composer install --no-dev --optimize-autoloader

# Run migrations
sudo -u www-data php artisan migrate --force

# Clear and recache
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan config:cache
sudo -u www-data php artisan route:cache
sudo -u www-data php artisan view:cache

# Restart services if needed
sudo systemctl restart apache2  # or nginx
```
