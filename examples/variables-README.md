# Kolumn Variables Examples

This directory contains comprehensive examples of Kolumn variable usage patterns and best practices.

## Variable Files Overview

| File | Purpose | Use Case |
|------|---------|-----------|
| `variables.klvars` | Basic variable patterns and types | Learning and development |
| `development.klvars` | Development environment settings | Local development |
| `staging.klvars` | Staging environment configuration | Pre-production testing |
| `production.klvars` | Production-ready configuration | Production deployment |
| `kolumn.auto.klvars` | Auto-loaded global settings | Cross-environment defaults |

## Variable Loading Order

Kolumn loads variables in the following precedence order (highest to lowest):

1. **Command line** (`-var` flags)
2. **Environment variables** (`KOLUMN_VAR_*`, `KOL_VAR_*`, `TF_VAR_*`)
3. **Explicit variable files** (`-var-file` flags)
4. **kolumn.klvars** (if present)
5. **Auto-loading files** (`*.auto.klvars`)
6. **Default values** (from variable declarations)

## Usage Examples

### Basic Usage

```bash
# Use development settings
kolumn plan -var-file="development.klvars"

# Use production settings
kolumn plan -var-file="production.klvars"

# Override specific values
kolumn plan -var-file="staging.klvars" -var="database_host=custom-host.com"
```

### Environment Variables

```bash
# Set individual variables
export KOLUMN_VAR_database_host="localhost"
export KOLUMN_VAR_environment="development"
export KOLUMN_VAR_debug_enabled="true"

# Run with environment variables
kolumn plan
```

### Multiple Variable Files

```bash
# Combine base settings with environment-specific overrides
kolumn plan \
  -var-file="kolumn.auto.klvars" \
  -var-file="production.klvars" \
  -var="app_version=1.2.3"
```

## Variable Declaration Patterns

### In your `.kl` configuration files, declare variables:

```hcl
# String variables
variable "database_host" {
  type        = string
  description = "Database host address"
  default     = "localhost"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+$", var.database_host))
    error_message = "Database host must be a valid hostname or IP address."
  }
}

# Number variables
variable "database_port" {
  type        = number
  description = "Database port number"
  default     = 5432
  
  validation {
    condition     = var.database_port > 0 && var.database_port < 65536
    error_message = "Database port must be between 1 and 65535."
  }
}

# Boolean variables
variable "debug_enabled" {
  type        = bool
  description = "Enable debug logging"
  default     = false
}

# List variables
variable "allowed_hosts" {
  type        = list(string)
  description = "List of allowed host addresses"
  default     = ["localhost", "127.0.0.1"]
}

# Object variables
variable "postgres_config" {
  type = object({
    shared_buffers = string
    max_connections = number
    ssl_mode = string
  })
  description = "PostgreSQL configuration parameters"
  default = {
    shared_buffers = "256MB"
    max_connections = 100
    ssl_mode = "require"
  }
}

# Sensitive variables
variable "database_password" {
  type        = string
  description = "Database password"
  sensitive   = true
  
  validation {
    condition     = length(var.database_password) >= 12
    error_message = "Database password must be at least 12 characters long."
  }
}
```

## Best Practices

### 1. Environment Separation
- Keep separate `.klvars` files for each environment
- Use descriptive names: `development.klvars`, `staging.klvars`, `production.klvars`
- Never commit sensitive production values to version control

### 2. Security
- Mark sensitive variables as `sensitive = true`
- Use environment variables for secrets: `KOLUMN_VAR_db_password`
- Consider external secret management systems for production

### 3. Validation
- Add validation rules to catch configuration errors early
- Use meaningful error messages in validation rules
- Validate complex objects and lists

### 4. Documentation
- Always include descriptions for variables
- Document expected formats and constraints
- Provide examples in comments

### 5. Defaults
- Provide sensible defaults for development
- Make production-critical settings explicit (no defaults)
- Use nullable variables when appropriate

## Environment-Specific Patterns

### Development Environment
- Relaxed security settings for easier debugging
- Verbose logging enabled
- All feature flags turned on
- Local database connections
- Minimal resource allocation

### Staging Environment  
- Production-like security settings
- Moderate resource allocation
- Testing-specific features enabled
- Automated testing configurations
- Data refresh from production (anonymized)

### Production Environment
- Maximum security and encryption
- High-performance resource allocation
- Monitoring and alerting configured
- Backup and disaster recovery settings
- Compliance and audit requirements

## Common Patterns

### Feature Flags
```hcl
variable "feature_flags" {
  type = object({
    new_ui = bool
    advanced_analytics = bool
    beta_features = bool
  })
  description = "Application feature flags"
}
```

### Resource Tags
```hcl
variable "resource_tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    managed_by = "kolumn"
    environment = "development"
  }
}
```

### Database Configuration
```hcl
variable "database_config" {
  type = object({
    host = string
    port = number
    name = string
    ssl_mode = string
    pool_settings = object({
      max_connections = number
      idle_timeout = string
    })
  })
  description = "Database connection configuration"
}
```

## Troubleshooting

### Common Issues

1. **Variable not found**: Ensure the variable is declared in your `.kl` files
2. **Type mismatch**: Check that your variable values match the declared type
3. **Validation failure**: Review validation rules and ensure values meet criteria
4. **File not found**: Check file paths and permissions for `.klvars` files

### Debugging Variables

```bash
# Validate variable files without executing
kolumn validate -var-file="production.klvars"

# Show what variables would be used
kolumn plan -var-file="production.klvars" --validate-only

# Debug variable loading
KOLUMN_LOG_LEVEL=debug kolumn plan -var-file="production.klvars"
```

## Security Notes

- **Never commit sensitive values**: Use `.gitignore` for production variable files
- **Environment variables**: Prefer `KOLUMN_VAR_*` for secrets in CI/CD
- **Validation**: Always validate sensitive inputs (passwords, API keys)
- **Encryption**: Use encrypted storage for production variable files
- **Access control**: Restrict access to production variable files

## Migration from Terraform

If migrating from Terraform, Kolumn supports `TF_VAR_*` environment variables for compatibility:

```bash
# Works with existing TF_VAR_ variables
export TF_VAR_database_host="terraform-db.com"
kolumn plan  # Will use TF_VAR_ values

# Equivalent Kolumn native approach
export KOLUMN_VAR_database_host="kolumn-db.com" 
kolumn plan  # KOLUMN_VAR_ takes precedence over TF_VAR_
```

This ensures smooth migration from Terraform-based infrastructure.