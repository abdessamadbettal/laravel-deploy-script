# Quick Start Guide

Get your Laravel application deployed in minutes!

## Prerequisites

Ensure your server has:
- Ubuntu/Debian or CentOS/RHEL Linux
- Root/sudo access
- Git installed
- PHP 8.0+ installed with required extensions
- MySQL/MariaDB or PostgreSQL (optional)
- Apache or Nginx web server

## Installation & Deployment

### Step 1: Get the Script

```bash
# Download the script
wget https://raw.githubusercontent.com/yourusername/laravel-deploy-script/main/deploy-laravel.sh

# Make it executable
chmod +x deploy-laravel.sh
```

### Step 2: Run the Script

```bash
sudo ./deploy-laravel.sh
```

### Step 3: Answer the Prompts

The script will ask you for:

1. **Git Repository URL** - Your Laravel app's Git repository
   ```
   Example: https://github.com/username/my-laravel-app.git
   ```

2. **Branch** - Which branch to deploy (default: main)
   ```
   Example: main, production, or develop
   ```

3. **Domain Name** - Your domain
   ```
   Example: myapp.com
   ```

4. **Web Server** - Choose Apache (1) or Nginx (2)
   ```
   Press: 1
   ```

5. **Database** - Choose MySQL (1), PostgreSQL (2), or skip (3)
   ```
   Press: 1
   ```

6. **Database Details**
   - Database name: `myapp_db`
   - Database user: `myapp_user`
   - Database password: (enter a secure password)

7. **SSL Setup** - Enable Let's Encrypt? (y/n)
   ```
   Press: y
   ```

8. **Email** - For SSL certificate notifications
   ```
   Example: admin@myapp.com
   ```

### Step 4: Wait for Completion

The script will:
- ✓ Clone your repository
- ✓ Create database
- ✓ Install dependencies
- ✓ Configure Laravel
- ✓ Setup web server
- ✓ Install SSL certificate
- ✓ Set permissions

### Step 5: Point Your DNS

Configure your domain's DNS A record to point to your server's IP address.

### Step 6: Access Your Application

Visit: `https://yourdomain.com`

## Example: Complete Deployment

Here's a complete example:

```bash
# 1. Download and prepare
wget https://raw.githubusercontent.com/yourusername/laravel-deploy-script/main/deploy-laravel.sh
chmod +x deploy-laravel.sh

# 2. Run the script
sudo ./deploy-laravel.sh

# You'll be prompted with:
# Git repository URL: https://github.com/mycompany/laravel-app.git
# Branch: main
# Domain: app.example.com
# Project name: [app_example_com]
# Installation directory: [/var/www/app_example_com]
# Web server: 1
# Database: 1
# Database name: [app_example_com_db]
# Database user: [app_example_com_user]
# Database password: [enter secure password]
# Database host: [localhost]
# Setup SSL: y
# Email: admin@example.com
# Continue? y

# 3. Wait for completion (5-10 minutes)

# 4. Configure DNS
# Point app.example.com to your server IP

# 5. Done! Visit https://app.example.com
```

## What Gets Installed

After deployment, your server will have:

```
/var/www/your-project/
├── app/
├── config/
├── database/
├── public/          ← Web root
├── resources/
├── storage/         ← Writable
├── vendor/          ← Composer packages
├── .env             ← Configuration
└── ...
```

## Common Scenarios

### Deploying a Blog

```bash
sudo ./deploy-laravel.sh

# Inputs:
Git: https://github.com/yourusername/blog.git
Branch: main
Domain: blog.example.com
Web Server: Apache
Database: MySQL
SSL: Yes
```

### Deploying an API (No Database)

```bash
sudo ./deploy-laravel.sh

# Inputs:
Git: https://github.com/yourusername/api.git
Branch: production
Domain: api.example.com
Web Server: Nginx
Database: Skip (3)
SSL: Yes
```

### Deploying for Development/Testing

```bash
sudo ./deploy-laravel.sh

# Inputs:
Git: https://github.com/yourusername/test-app.git
Branch: develop
Domain: staging.example.com
Web Server: Apache
Database: MySQL
SSL: No (for local testing)
```

## Troubleshooting

### Issue: "Git not found"
```bash
# Install git
sudo apt-get install git  # Ubuntu/Debian
sudo yum install git       # CentOS/RHEL
```

### Issue: "PHP not found"
```bash
# Install PHP
sudo apt-get install php php-cli php-mbstring php-xml php-mysql
```

### Issue: "Permission denied"
```bash
# Use sudo
sudo ./deploy-laravel.sh
```

### Issue: "Cannot clone repository"
- Check repository URL is correct
- For private repos, set up SSH keys first
- Verify network connectivity

### Issue: "MySQL connection failed"
- Ensure MySQL is running: `sudo systemctl status mysql`
- Check MySQL root password
- Verify database credentials

### Issue: "SSL certificate failed"
- Ensure DNS is pointing to your server
- Verify ports 80 and 443 are open
- Wait a few minutes for DNS propagation

## Next Steps

After deployment:

1. **Test your application**
   ```bash
   curl https://yourdomain.com
   ```

2. **Check logs if needed**
   ```bash
   tail -f /var/www/your-project/storage/logs/laravel.log
   ```

3. **Configure additional services**
   - Set up queue workers
   - Configure cron jobs
   - Set up Redis (if needed)
   - Configure email settings

4. **Set up backups**
   - Database backups
   - File backups
   - Automated backup schedule

5. **Monitor your application**
   - Set up uptime monitoring
   - Configure error tracking
   - Monitor server resources

## Advanced Options

### Using Environment Variables

For automated deployments:

```bash
# Set variables (not fully automated yet, but useful for reference)
export GIT_REPO="https://github.com/user/app.git"
export DOMAIN="app.example.com"
export DB_PASSWORD="secure_password"

# Then run the script
sudo -E ./deploy-laravel.sh
```

### Deploying Multiple Applications

Run the script multiple times with different configurations:

```bash
# First app
sudo ./deploy-laravel.sh
# Domain: app1.example.com
# Directory: /var/www/app1

# Second app
sudo ./deploy-laravel.sh
# Domain: app2.example.com
# Directory: /var/www/app2
```

## Getting Help

- Read the full [README.md](README.md)
- Check [EXAMPLES.md](EXAMPLES.md) for more scenarios
- Review [SECURITY.md](SECURITY.md) for security best practices
- Open an issue on GitHub for problems

## Performance Tips

After deployment, optimize:

```bash
cd /var/www/your-project

# Enable OPcache in php.ini
# Cache configuration
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Use Redis for sessions/cache (if installed)
# Update .env:
# CACHE_DRIVER=redis
# SESSION_DRIVER=redis
```

---

**Ready to deploy? Run the script and watch your Laravel application come to life! 🚀**
