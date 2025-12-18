# Contributing to Laravel Deployment Script

Thank you for considering contributing to this project! This document outlines the process for contributing.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with:
- A clear, descriptive title
- Detailed steps to reproduce the issue
- Expected behavior vs actual behavior
- Your environment (OS, PHP version, web server, etc.)
- Any error messages or logs

### Suggesting Enhancements

We welcome suggestions for improvements! Please create an issue with:
- A clear description of the enhancement
- Why this enhancement would be useful
- Examples of how it would work

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Make your changes** following our coding standards
3. **Test your changes** thoroughly
4. **Ensure the script still works** for all supported configurations
5. **Update documentation** if needed (README.md, EXAMPLES.md)
6. **Submit a pull request** with a clear description of changes

## Coding Standards

### Bash Script Guidelines

- Use 4 spaces for indentation (not tabs)
- Add comments for complex logic
- Use descriptive variable names in UPPER_CASE
- Use functions for reusable code
- Add error checking with `set -e` and conditional checks
- Use colored output for better user experience
- Maintain consistent formatting with existing code

### Function Structure

```bash
function_name() {
    print_header "Section Name"
    
    # Check prerequisites
    if [[ condition ]]; then
        print_error "Error message"
        exit 1
    fi
    
    # Main logic
    print_info "Doing something..."
    
    # Success feedback
    print_success "Operation completed"
}
```

### Error Handling

Always check command success:

```bash
command_that_might_fail || {
    print_error "Command failed"
    exit 1
}

# Or
if ! command_that_might_fail; then
    print_error "Command failed"
    exit 1
fi
```

### User Input

Always validate user input:

```bash
read -p "Enter value: " USER_INPUT
if [[ -z "$USER_INPUT" ]]; then
    print_error "Value is required"
    exit 1
fi
```

## Testing

Before submitting a pull request:

1. **Test on multiple distributions:**
   - Ubuntu/Debian
   - CentOS/RHEL
   - Other major Linux distributions

2. **Test different configurations:**
   - Apache and Nginx
   - MySQL and PostgreSQL
   - With and without SSL
   - With and without database

3. **Test error scenarios:**
   - Invalid repository URLs
   - Missing dependencies
   - Permission issues
   - Network failures

4. **Manual testing checklist:**
   - [ ] Script runs without errors
   - [ ] Repository clones successfully
   - [ ] Database is created and configured
   - [ ] Web server configuration is correct
   - [ ] SSL certificate installs (if selected)
   - [ ] Permissions are set correctly
   - [ ] Laravel application works properly
   - [ ] All user prompts work as expected
   - [ ] Error messages are clear and helpful

## Documentation

When adding new features:

1. Update README.md with:
   - Feature description
   - Usage instructions
   - Any new requirements

2. Add examples to EXAMPLES.md if applicable

3. Update inline comments in the script

4. Document any new configuration options

## Commit Messages

Use clear, descriptive commit messages:

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues/PRs when applicable

Examples:
```
Add PostgreSQL support for database setup
Fix SSL certificate installation on CentOS
Improve error handling for git clone failures
Update documentation with Nginx examples
```

## Code Review Process

1. All submissions require review
2. Maintainers may request changes
3. Changes should be made in the same branch
4. Once approved, a maintainer will merge the PR

## Feature Requests Priority

We prioritize features that:
- Benefit the majority of users
- Maintain simplicity and ease of use
- Follow Laravel best practices
- Are well-tested and documented
- Don't introduce breaking changes

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion for ideas
- Reach out to maintainers

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Thank You!

Your contributions make this project better for everyone. We appreciate your time and effort! 🙏
