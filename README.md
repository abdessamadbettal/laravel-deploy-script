# Laravel Deployment Automation Script

A comprehensive Bash script to automate the deployment of any Laravel application from zero to finish on a Linux server. This script handles everything you need to get your Laravel application up and running in minutes.

## Features

- 🚀 **Automated Repository Cloning**: Clone your Laravel application from any Git repository
- 🗄️ **Database Setup**: Automatic configuration for MySQL/MariaDB or PostgreSQL
- 🌐 **Web Server Configuration**: Support for both Apache and Nginx
- 🔒 **SSL Certificate**: Automated Let's Encrypt SSL certificate installation
- 📁 **File Permissions**: Proper Laravel file permissions and ownership
- 📦 **Dependency Management**: Automatic Composer dependency installation
- ⚙️ **Laravel Configuration**: Environment setup, key generation, migrations, and optimization
- 🎨 **User-Friendly**: Interactive prompts with colored output and progress indicators
- ✅ **Error Handling**: Built-in validation and error checking

## Requirements

### System Requirements

- **Operating System**: Linux (Ubuntu, Debian, CentOS, RHEL, etc.)
- **Root Access**: Script must be run with sudo/root privileges
- **Git**: For cloning repositories
- **PHP**: Version 8.0+ (with required extensions)
- **Composer**: Will be automatically installed if not present
- **Web Server**: Apache or Nginx
- **Database** (optional): MySQL/MariaDB or PostgreSQL

### PHP Extensions (Typical Laravel Requirements)

Your PHP installation should have these extensions:
- OpenSSL
- PDO
- Mbstring
- Tokenizer
- XML
- Ctype
- JSON
- BCMath

## Installation

1. **Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/abdessamadbettal/laravel-deploy-script/main/deploy-laravel.sh
   ```

   Or clone the repository:
   ```bash
   git clone https://github.com/abdessamadbettal/laravel-deploy-script.git
   cd laravel-deploy-script
   ```

2. **Make the script executable:**
   ```bash
   chmod +x deploy-laravel.sh
   ```

3. **Run the script:**
   ```bash
   sudo ./deploy-laravel.sh
   ```

## Usage

Simply run the script with sudo and follow the interactive prompts:

```bash
sudo bash deploy-laravel.sh
```

### Interactive Prompts

The script will ask you for the following information:

1. **Git Repository URL**: The URL of your Laravel application repository
2. **Branch**: The branch to deploy (default: main)
3. **Domain Name**: Your domain name (e.g., example.com)
4. **Project Name**: A name for your project (defaults to sanitized domain name)
5. **Installation Directory**: Where to install the application (default: /var/www/project_name)
6. **Web Server**: Choose between Apache or Nginx
7. **Database Type**: MySQL/MariaDB, PostgreSQL, or skip database setup
8. **Database Details**: Database name, user, password, and host
9. **SSL Setup**: Whether to install Let's Encrypt SSL certificate
10. **Email**: Email for SSL certificate notifications

## What the Script Does

### 1. System Requirements Check
- Verifies Git and PHP are installed
- Checks for Composer (installs if missing)

### 2. Repository Cloning
- Clones your Laravel application from the specified Git repository
- Checks out the specified branch

### 3. Database Setup
- Creates database and user
- Grants appropriate privileges
- Supports both MySQL and PostgreSQL

### 4. Laravel Environment Configuration
- Creates/updates `.env` file
- Configures database connection
- Sets app URL and environment settings

### 5. Dependency Installation
- Runs `composer install` with production optimizations
- Installs all required packages

### 6. Laravel Setup
- Generates application key
- Runs database migrations
- Caches configuration, routes, and views

### 7. File Permissions
- Sets appropriate ownership for web server user
- Configures storage and cache directory permissions

### 8. Web Server Configuration
- Creates virtual host (Apache) or server block (Nginx)
- Enables the site
- Restarts the web server

### 9. SSL Certificate (Optional)
- Installs certbot if needed
- Obtains Let's Encrypt SSL certificate
- Configures automatic HTTPS redirect
- Sets up auto-renewal

## Example Output

```
================================================
Laravel Deployment Automation Script
================================================

✓ Git is installed
✓ PHP 8.1.2 is installed
✓ Composer is installed

Enter Git repository URL: https://github.com/username/my-laravel-app.git
Enter branch to deploy (default: main): main
Enter domain name (e.g., example.com): myapp.com
...
```

## Post-Deployment

After successful deployment:

1. **Point DNS**: Configure your domain's DNS A record to point to your server's IP address
2. **Access Application**: Visit your domain (https://yourdomain.com)
3. **Review Configuration**: Check the `.env` file for any additional settings
4. **Additional Setup**: Configure mail, queues, caching, etc. as needed

## Troubleshooting

### Permission Issues
If you encounter permission errors:
```bash
cd /var/www/your-project
sudo chown -R www-data:www-data .
sudo chmod -R 775 storage bootstrap/cache
```

### SSL Certificate Fails
- Ensure your domain's DNS is properly configured
- Verify ports 80 and 443 are open in your firewall
- Check if another service is using port 80

### Database Connection Errors
- Verify database credentials in `.env` file
- Ensure database service is running: `systemctl status mysql` or `systemctl status postgresql`
- Check database user permissions

### Web Server Not Starting
- Check configuration syntax: `apache2ctl configtest` or `nginx -t`
- Review error logs: `/var/log/apache2/error.log` or `/var/log/nginx/error.log`

## Security Considerations

- The script sets `APP_DEBUG=false` for production
- Storage and cache directories are given appropriate permissions
- SSL certificates are automatically configured when selected
- Database passwords can be auto-generated
- All sensitive data is stored in `.env` (not committed to Git)

## Directory Structure

After deployment, your Laravel application will be in:
```
/var/www/your-project/
├── app/
├── bootstrap/
├── config/
├── database/
├── public/         ← Web server document root
├── resources/
├── routes/
├── storage/        ← Writable by web server
├── tests/
├── vendor/
├── .env            ← Environment configuration
└── ...
```

## Updating Your Application

To update your deployed application:

1. Navigate to your project directory:
   ```bash
   cd /var/www/your-project
   ```

2. Pull latest changes:
   ```bash
   sudo -u www-data git pull origin main
   ```

3. Update dependencies and optimize:
   ```bash
   sudo -u www-data composer install --no-dev --optimize-autoloader
   sudo -u www-data php artisan migrate --force
   sudo -u www-data php artisan config:cache
   sudo -u www-data php artisan route:cache
   sudo -u www-data php artisan view:cache
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).

## Support

If you encounter any issues or have questions:
- Open an issue on GitHub
- Check the troubleshooting section above
- Review Laravel's official documentation

## Credits

Created to simplify Laravel deployment on Linux servers.

---

**Note**: Always test the deployment on a staging environment before deploying to production.
