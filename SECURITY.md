# Security Policy

## Supported Versions

We actively support and provide security updates for the following versions of NNTmux:

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < Latest| :x:                |

We recommend always running the latest version of NNTmux to ensure you have all security patches.

## Reporting a Vulnerability

We take the security of NNTmux seriously. If you believe you've found a security vulnerability, please follow these guidelines:

### How to Report

**DO NOT** create a public GitHub issue for security vulnerabilities.

Instead, please report security vulnerabilities through one of these secure channels:

1. **GitHub Security Advisories** (Preferred)
   - Navigate to the [Security Advisories](https://github.com/NNTmux/newznab-tmux/security/advisories) page
   - Click "Report a vulnerability"
   - Fill out the form with details

2. **Discord** (For urgent issues)
   - Join our [Discord server](https://discord.gg/GjgGSzkrjh)
   - Contact a moderator or admin directly via private message
   - Provide details of the vulnerability

### What to Include

When reporting a vulnerability, please include:

- **Description**: Clear description of the vulnerability
- **Impact**: What could an attacker potentially do?
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Proof of Concept**: Code or screenshots demonstrating the vulnerability
- **Affected Versions**: Which version(s) are affected
- **Suggested Fix**: If you have ideas on how to fix it (optional)
- **Your Contact Info**: How we can reach you for follow-up

### What to Expect

- **Acknowledgment**: We'll acknowledge receipt within 48 hours
- **Initial Assessment**: We'll provide an initial assessment within 5 business days
- **Updates**: We'll keep you informed of our progress
- **Fix Timeline**: Critical vulnerabilities will be patched within 7-14 days
- **Credit**: With your permission, we'll credit you in the security advisory

### Disclosure Policy

- Please allow us reasonable time to address the vulnerability before public disclosure
- We aim to patch critical vulnerabilities within 14 days
- We will coordinate the disclosure timeline with you
- Once patched, we'll publish a security advisory crediting the reporter (if desired)

## Security Best Practices

When deploying NNTmux, follow these security best practices:

### 1. Environment Configuration

```bash
# Use strong, unique credentials
ADMIN_USER=<unique_username>
ADMIN_PASS=<strong_password_with_symbols_numbers>

# Disable debug mode in production
APP_ENV=production
APP_DEBUG=false

# Use HTTPS
APP_URL=https://your-domain.com
```

### 2. Database Security

- Use a dedicated database user with minimal required privileges
- Use strong, unique database passwords (32+ characters recommended)
- Restrict database access to localhost when possible
- Regularly backup your database
- Keep MariaDB/MySQL updated

### 3. Server Configuration

- **Keep PHP Updated**: Use PHP 8.3+ with the latest security patches
- **Firewall**: Only expose necessary ports (80/443)
- **SSH**: Disable root login, use SSH keys
- **File Permissions**: Set proper permissions on storage and bootstrap/cache
  ```bash
  chmod -R 755 storage bootstrap/cache
  chown -R www-data:www-data storage bootstrap/cache
  ```

### 4. Application Security

- **CSRF Protection**: Never disable CSRF protection on authenticated routes
- **API Keys**: Rotate API keys periodically
- **Session Security**: Use secure session configuration
  ```bash
  SESSION_DRIVER=redis
  SESSION_SECURE_COOKIE=true
  SESSION_HTTP_ONLY=true
  ```
- **Rate Limiting**: API rate limiting is enabled by default - don't disable it
- **2FA**: Enable two-factor authentication for admin accounts

### 5. Regular Maintenance

- **Updates**: Keep NNTmux and dependencies updated
  ```bash
  composer update
  npm update
  ```
- **Security Scanning**: Run security audits regularly
  ```bash
  composer audit
  npm audit
  ```
- **Log Monitoring**: Review logs for suspicious activity
- **Backup Strategy**: Maintain regular backups (database + config files)

### 6. Network Security

- **Reverse Proxy**: Use nginx/Apache as a reverse proxy
- **SSL/TLS**: Use valid SSL certificates (Let's Encrypt recommended)
- **Security Headers**: Ensure security headers are enabled (CSP, HSTS, etc.)
- **Cloudflare**: Consider using Cloudflare for DDoS protection

### 7. User Management

- **Strong Passwords**: Enforce strong password requirements (enabled by default)
- **Password Breach Check**: Laravel checks passwords against breached databases
- **Account Verification**: Email verification is enabled by default
- **Invite System**: Use invite-only registration when appropriate
- **Role-Based Access**: Leverage Spatie permissions for proper access control

## Security Features

NNTmux includes several built-in security features:

### Authentication & Authorization
- ✅ Password hashing using bcrypt
- ✅ Two-factor authentication (2FA) support
- ✅ Role-based access control (RBAC) via Spatie Permissions
- ✅ Email verification
- ✅ Password strength validation
- ✅ Password breach checking
- ✅ Rate limiting on login attempts
- ✅ Account lockout after failed attempts

### API Security
- ✅ API token authentication
- ✅ Rate limiting on API endpoints
- ✅ CORS protection
- ✅ Request validation

### Data Protection
- ✅ CSRF protection on all forms
- ✅ XSS protection via Blade templating
- ✅ SQL injection prevention via Eloquent ORM
- ✅ Sensitive data hidden from JSON responses
- ✅ Content Security Policy (CSP) headers

### Infrastructure Security
- ✅ Secure session handling
- ✅ Cookie encryption
- ✅ HTTPS enforcement (when configured)
- ✅ File upload validation
- ✅ Input sanitization

## Known Security Considerations

### Default Credentials
⚠️ **Critical**: Change default admin credentials immediately after installation!

The default credentials are documented publicly. Change them in your `.env` file:
```bash
ADMIN_USER=your_unique_username
ADMIN_PASS=your_strong_password
```

### File Permissions
Ensure proper file permissions after deployment:
```bash
# Set directory permissions
find . -type d -exec chmod 755 {} \;

# Set file permissions
find . -type f -exec chmod 644 {} \;

# Make artisan executable
chmod +x artisan

# Set storage permissions
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache
```

### Environment Variables
Never commit your `.env` file to version control. It contains sensitive credentials.

## Security Checklist

Before going to production, verify:

- [ ] Changed default admin credentials
- [ ] Set `APP_ENV=production` and `APP_DEBUG=false`
- [ ] Enabled HTTPS and set `APP_URL` correctly
- [ ] Configured secure session settings
- [ ] Set up proper file permissions
- [ ] Configured firewall rules
- [ ] Enabled 2FA for admin accounts
- [ ] Set strong database credentials
- [ ] Configured rate limiting
- [ ] Enabled CSP headers
- [ ] Set up regular backups
- [ ] Configured log rotation
- [ ] Reviewed all `.env` settings
- [ ] Disabled unnecessary services
- [ ] Updated all dependencies

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Laravel Security Best Practices](https://laravel.com/docs/security)
- [PHP Security Guide](https://phptherightway.com/#security)
- [NNTmux Wiki](https://github.com/NNTmux/newznab-tmux/wiki)

## Contact

For security-related questions that aren't vulnerabilities, you can:
- Open a discussion on GitHub
- Ask in our Discord server (non-sensitive questions only)
- Check our Wiki documentation

---

**Remember**: Security is a shared responsibility. While we work hard to keep NNTmux secure, proper deployment and configuration are essential for a secure installation.
