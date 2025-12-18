# Security Policy

## Security Considerations

This deployment script handles sensitive operations and data. Please review the following security considerations before use.

### What the Script Does

The script performs privileged operations including:
- Creating database users and passwords
- Configuring web servers
- Setting file permissions
- Managing SSL certificates
- Handling environment variables with sensitive data

### Security Best Practices

#### 1. Run with Appropriate Privileges
- The script requires root/sudo access
- Only run on servers you control
- Review the script before execution

#### 2. Secure Passwords
- Use strong, unique passwords for database users
- The script can generate random passwords automatically
- Never commit passwords to version control

#### 3. Environment Files
- The `.env` file contains sensitive configuration
- It's automatically excluded from Git
- Ensure proper file permissions (600 or 640)
- Never expose `.env` publicly

#### 4. SSL Certificates
- Always enable SSL for production deployments
- Let's Encrypt certificates auto-renew
- Verify SSL configuration after deployment

#### 5. Database Security
- Use strong database passwords
- Limit database user privileges to specific databases
- Consider using localhost for database connections
- Change default database credentials after deployment

#### 6. File Permissions
- The script sets appropriate Laravel permissions
- Storage and cache directories: 775
- Other directories: 755
- Files: 644
- Review permissions after deployment

#### 7. Web Server Security
- Disable directory listing (handled by script)
- Hide sensitive files (handled by script)
- Configure appropriate security headers
- Keep web server updated

#### 8. Git Repository Access
- For private repositories, use SSH keys
- Don't store credentials in the repository URL
- Set up deploy keys for production servers

#### 9. Server Hardening
Before running the script, ensure your server is hardened:
- Update all packages: `apt update && apt upgrade`
- Configure firewall: `ufw enable` and allow only necessary ports
- Disable root SSH login
- Use SSH key authentication
- Configure fail2ban for brute-force protection

#### 10. Regular Updates
- Keep PHP, web server, and dependencies updated
- Monitor security advisories for Laravel
- Update Composer packages regularly
- Review and rotate credentials periodically

### Sensitive Data Handling

#### Passwords
- Database passwords are passed via command-line arguments
- Clear bash history after deployment if sensitive data was entered
- Consider using environment variables or password files for automation

#### MySQL Root Password
- The script prompts for MySQL root password if needed
- Password is stored temporarily in memory only
- Not logged or saved to disk

### Post-Deployment Security

After deployment:

1. **Review `.env` file permissions:**
   ```bash
   chmod 600 /var/www/your-project/.env
   ```

2. **Clear sensitive data from bash history:**
   ```bash
   history -c
   ```

3. **Verify SSL configuration:**
   ```bash
   curl -I https://yourdomain.com
   ```

4. **Check file permissions:**
   ```bash
   ls -la /var/www/your-project/
   ```

5. **Review Laravel security settings:**
   - `APP_DEBUG=false` in production
   - `APP_ENV=production`
   - Strong `APP_KEY`

6. **Configure additional security headers:**
   Add to web server configuration:
   - X-Frame-Options
   - X-Content-Type-Options
   - Strict-Transport-Security
   - Content-Security-Policy

### Known Limitations

1. **No Secret Management**: The script doesn't integrate with secret management systems (Vault, AWS Secrets Manager, etc.)
2. **Local Password Storage**: Database passwords are stored in `.env` file
3. **No Multi-Factor Authentication**: Database access doesn't use MFA
4. **No Automated Backups**: Set up backup solutions separately

### Reporting Security Issues

If you discover a security vulnerability:

1. **Do NOT** open a public issue
2. Email the maintainers privately
3. Provide detailed information about the vulnerability
4. Allow time for a fix before public disclosure

### Security Checklist

Before deployment:
- [ ] Server is updated and hardened
- [ ] Firewall is configured
- [ ] SSH access is secured
- [ ] Strong passwords prepared
- [ ] Script has been reviewed

After deployment:
- [ ] SSL certificate is installed and valid
- [ ] `.env` file permissions are correct (600)
- [ ] Database user has minimal required privileges
- [ ] Application is accessible via HTTPS
- [ ] Laravel security settings are production-ready
- [ ] Sensitive bash history is cleared
- [ ] Backup solution is configured

### Additional Resources

- [Laravel Security Best Practices](https://laravel.com/docs/security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Benchmarks for Linux](https://www.cisecurity.org/cis-benchmarks/)
- [Let's Encrypt Best Practices](https://letsencrypt.org/docs/)

### Compliance

This script is provided as-is for educational and development purposes. For production environments:
- Conduct security audits
- Follow your organization's security policies
- Consider compliance requirements (PCI-DSS, HIPAA, GDPR, etc.)
- Implement additional security controls as needed

---

**Remember**: Security is a process, not a one-time setup. Regularly review and update your security practices.
