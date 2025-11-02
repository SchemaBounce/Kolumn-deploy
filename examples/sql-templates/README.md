# SQL Templates Example

This example demonstrates Kolumn's powerful SQL Template System for managing external `.sql` files with provider-specific overrides and variable substitution.

## Key Features Demonstrated

### 1. External SQL File Templates
- Templates stored as external `.sql` files instead of inline SQL blocks
- Provider-specific overrides for PostgreSQL, MySQL, and Snowflake
- Template variable substitution using Go template syntax

### 2. Provider-Specific Optimizations
- **PostgreSQL**: JSONB columns, full-text search, Row Level Security
- **MySQL**: AUTO_INCREMENT, JSON columns, full-text indexes
- **Snowflake**: IDENTITY columns, VARIANT types, clustering, dynamic masking

### 3. Template Variables and Configuration
- Required and optional variables with defaults
- Type validation and descriptions
- Provider-specific database type support

## File Structure

```
sql-templates/
├── main.kl                           # Main configuration with templates and resources
├── sql/
│   ├── users_table.sql               # Default users table template
│   ├── products_table.sql            # Default products table template
│   ├── postgres/
│   │   └── users_table.sql           # PostgreSQL-specific users template
│   ├── mysql/
│   │   └── users_table.sql           # MySQL-specific users template
│   ├── snowflake/
│   │   └── users_table.sql           # Snowflake-specific users template
│   └── views/
│       └── user_summary.sql          # User summary view template
└── README.md                         # This file
```

## Template Definitions

### SQL Template Blocks
```hcl
sql "table_schemas" {
  description = "Reusable table templates for common schemas"
  version     = "1.0.0"

  template "users" {
    description    = "Standard user table template"
    type          = "table"
    source        = "./sql/users_table.sql"           # Default template
    database_types = ["postgres", "mysql", "snowflake"]

    # Provider-specific overrides
    provider_overrides {
      postgres  = "./sql/postgres/users_table.sql"   # Enhanced PostgreSQL version
      mysql     = "./sql/mysql/users_table.sql"      # MySQL-optimized version
      snowflake = "./sql/snowflake/users_table.sql"  # Snowflake-specific features
    }

    # Template variables
    variable "table_name" {
      type        = "string"
      description = "Name of the user table"
      default     = "users"
      required    = true
    }
  }
}
```

### Using Templates in Resources
```hcl
create "postgres_table" "users" {
  provider      = postgres.production
  from_template = "sql.table_schemas.users"    # Reference template

  # Pass variables to template
  variables = {
    table_name   = "app_users"
    enable_audit = true
    schema_name  = "public"
  }
}
```

## Template Variable Substitution

Templates use Go template syntax for variable substitution:

```sql
-- In users_table.sql
CREATE TABLE {{.schema_name}}.{{.table_name}} (
    id BIGINT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    {{if .enable_audit}}
    -- Audit columns (conditional)
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    version INTEGER DEFAULT 1
    {{end}}
);
```

## Provider-Specific Features

### PostgreSQL Enhancements
- `BIGSERIAL` auto-increment primary keys
- `JSONB` columns for flexible metadata
- Full-text search with `TSVECTOR`
- Row Level Security (RLS) policies
- Advanced audit logging with JSONB

### MySQL Enhancements
- `AUTO_INCREMENT` primary keys
- `JSON` columns for metadata
- Full-text search indexes
- Engine and charset specifications
- Email format validation constraints

### Snowflake Enhancements
- `NUMBER(38,0) IDENTITY` for primary keys
- `VARIANT` columns for semi-structured data
- Clustering keys for performance
- Search optimization
- Dynamic data masking policies
- Row access policies
- Change streams and audit tasks

## Running the Example

1. **Initialize the project:**
   ```bash
   cd /mnt/c/git/Kolumn/examples/sql-templates
   kolumn init
   ```

2. **Plan the deployment:**
   ```bash
   kolumn plan
   ```

3. **Apply the configuration:**
   ```bash
   kolumn apply
   ```

4. **Validate template processing:**
   ```bash
   kolumn validate
   ```

## Template System Benefits

### 1. **Avoid Inline SQL Blocks**
- External `.sql` files are easier to edit and maintain
- Better syntax highlighting and IDE support
- Version control-friendly diffs

### 2. **Provider Optimization**
- Use provider-specific features without code duplication
- Maintain compatibility across different database systems
- Leverage unique capabilities of each platform

### 3. **Reusability and Consistency**
- Define schemas once, use across multiple projects
- Ensure consistent naming and structure conventions
- Centralized template management

### 4. **Variable Flexibility**
- Parameterize table names, schema names, and feature flags
- Type-safe variable definitions with validation
- Default values for optional configuration

## Best Practices

1. **Start with Generic Templates**: Create database-agnostic templates first
2. **Add Provider Optimizations**: Create provider-specific overrides for performance
3. **Use Descriptive Variables**: Make templates configurable with clear variable names
4. **Version Your Templates**: Use semantic versioning for template evolution
5. **Document Variables**: Provide clear descriptions and types for all variables
6. **Test All Providers**: Validate templates work across all supported database types

## Template Resolution Order

When Kolumn processes a `from_template` reference:

1. **Parse Template Reference**: `"sql.table_schemas.users"` → group="table_schemas", name="users"
2. **Check Provider Override**: Look for provider-specific template file
3. **Load Template Content**: Read the appropriate `.sql` file
4. **Variable Substitution**: Process Go template variables
5. **Generate Final SQL**: Produce provider-optimized SQL for execution

This system provides the flexibility to use external SQL files while maintaining the power of Kolumn's provider abstraction and variable system.