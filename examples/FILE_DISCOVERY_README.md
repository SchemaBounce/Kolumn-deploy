# Kolumn File Discovery System

## Overview

Kolumn's File Discovery System enables unidirectional reading and interpolation of external files (SQL, Python, YAML, JSON, etc.) with Kolumn data objects, variables, and resource references. This allows you to:

- **Keep existing file structure**: Your SQL, Python, YAML, and other files stay in their natural locations
- **Universal interpolation**: Use `${var.name}`, `${input.name}`, `${discover.resource.field}`, `${kolumn_data_object.name.field}` patterns across all file types  
- **Cross-language references**: Reference Kolumn resources and data objects from any file type
- **Advanced dependency tracking**: Automatically detect and track dependencies between files and resources

## Supported File Types

- **SQL** (.sql) - Database queries, views, procedures
- **Python** (.py) - DAGs, ETL scripts, data processing
- **Java** (.java) - Spring Boot configurations, application code  
- **YAML** (.yaml, .yml) - Kubernetes manifests, configuration files
- **JSON** (.json) - API configurations, application settings
- **JavaScript/TypeScript** (.js, .ts) - Node.js applications, configs
- **Shell** (.sh, .bash) - Deployment scripts, automation
- **And more** - Extensible architecture for additional file types

## Basic Usage

### 1. Discover and Interpolate Files

```hcl
# Define data objects
create "kolumn_data_object" "users" {
  column "id" { type = "BIGSERIAL", primary_key = true }
  column "email" { type = "VARCHAR(255)", unique = true }
  column "name" { type = "VARCHAR(100)" }
}

# Discover external SQL file with interpolation
discover "kolumn_file" "user_summary_view" {
  location = "./sql/user_summary.sql"
  inputs = {
    schema_name = "public"
    table_prefix = "app_"
    user_columns = "${kolumn_data_object.users.columns}"
  }
}

# Use discovered content to create resources
create "postgres_view" "user_summary" {
  sql = "${discover.user_summary_view.interpolated_content}"
  depends_on = ["kolumn_data_object.users"]
}
```

### 2. Example External SQL File (`sql/user_summary.sql`)

```sql
---
name: user_summary
description: User summary with order statistics  
depends_on: [users, orders]
materialized: view
---

CREATE VIEW ${input.schema_name}.${input.table_prefix}user_summary AS
SELECT 
    u.id,
    u.email,
    u.name,
    COUNT(o.id) as order_count
FROM ${input.schema_name}.users u
LEFT JOIN ${input.schema_name}.orders o ON u.id = o.user_id
GROUP BY u.id, u.email, u.name;

-- Columns from data object: ${input.user_columns}
```

## Advanced Interpolation Patterns

### Variable Types

```hcl
discover "kolumn_file" "config" {
  location = "./config/app.json"
  inputs = {
    # Basic variables
    environment = "production"
    api_version = "v2"
    
    # Resource references
    database_url = "${postgres_database.main.connection_string}"
    redis_host = "${redis_cluster.cache.host}"
    
    # Data object references
    user_schema = "${kolumn_data_object.users.schema}"
    user_columns = "${kolumn_data_object.users.columns}"
    
    # Cross-discovery references  
    base_config = "${discover.base_settings.interpolated_content}"
  }
}
```

### Interpolation Patterns

- `${var.name}` - Basic variables from HCL variable declarations
- `${input.name}` - Input values provided in the discover block
- `${resource.type.name.field}` - Resource attributes (e.g., `${postgres_table.users.name}`)
- `${kolumn_data_object.name.field}` - Data object attributes  
- `${discover.name.field}` - Other discovered file attributes

### File-Type Specific Formatting

The interpolation engine automatically formats values based on target file type:

**SQL Format:**
```sql
WHERE status = '${input.status}'    -- Becomes: WHERE status = 'active'
AND count > ${input.limit}          -- Becomes: AND count > 100  
AND enabled = ${input.enabled}      -- Becomes: AND enabled = TRUE
```

**JSON Format:**
```json
{
  "status": "${input.status}",       // Becomes: "status": "active"
  "limit": ${input.limit},           // Becomes: "limit": 100
  "enabled": ${input.enabled}        // Becomes: "enabled": true
}
```

**YAML Format:**  
```yaml
database:
  host: ${input.db_host}             # Becomes: host: localhost
  port: ${input.db_port}             # Becomes: port: 5432
  ssl: ${input.ssl_enabled}          # Becomes: ssl: true
```

## Complex Examples

### 1. Python ETL Pipeline with Airflow

```hcl
# Discover Python DAG file
discover "kolumn_file" "user_etl" {
  location = "./dags/user_etl.py"
  inputs = {
    source_table = "${postgres_table.users.full_name}"
    target_table = "${bigquery_table.users_warehouse.full_name}"
    batch_size = 1000
    schedule = "0 2 * * *"
    database_url = "${postgres_database.source.connection_string}"
  }
}

# Create Airflow DAG resource
create "airflow_dag" "user_etl_pipeline" {
  dag_content = "${discover.user_etl.interpolated_content}"
  depends_on = [
    "postgres_table.users",
    "bigquery_table.users_warehouse"
  ]
}
```

### 2. Kubernetes Deployment with Service Discovery

```hcl
# Discover Kubernetes manifest
discover "kolumn_file" "app_deployment" {
  location = "./k8s/deployment.yaml"
  inputs = {
    app_name = "data-api"
    image_tag = "${var.build_version}"
    replicas = 3
    database_secret = "${kubernetes_secret.db_creds.name}"
    environment = "${var.environment}"
  }
}

# Deploy to Kubernetes
create "kubernetes_deployment" "data_api" {
  manifest = "${discover.app_deployment.interpolated_content}"
  namespace = "production"
}
```

### 3. Chained File Discovery

```hcl
# Base configuration
discover "kolumn_file" "base_config" {
  location = "./config/base.json"  
  inputs = {
    environment = "${var.environment}"
    region = "${var.aws_region}"
  }
}

# Environment-specific config that references base
discover "kolumn_file" "env_config" {
  location = "./config/${var.environment}.json"
  inputs = {
    # Reference another discovered file
    base_config = "${discover.base_config.interpolated_content}"
    database_url = "${postgres_database.main.connection_string}"
  }
}

# Application using both configs
create "application_config" "api_service" {
  base_config = "${discover.base_config.interpolated_content}"
  environment_config = "${discover.env_config.interpolated_content}"
}
```

## Dependency Management

The file discovery system automatically:

1. **Extracts dependencies** from interpolation patterns
2. **Tracks file changes** via last modification timestamps  
3. **Validates references** during plan phase
4. **Orders execution** based on dependency graph

```hcl
output "file_dependencies" {
  value = {
    user_etl_dependencies = "${discover.user_etl.dependencies}"
    # Example output: ["postgres_table.users", "bigquery_table.users_warehouse", "var.batch_size"]
  }
}
```

## Discovery Resource Fields

Each discovered file exposes these fields:

- `${discover.name.location}` - File path  
- `${discover.name.file_type}` - Detected file type (sql, python, json, etc.)
- `${discover.name.interpolated_content}` - Content after interpolation
- `${discover.name.dependencies}` - Extracted dependency list
- `${discover.name.metadata}` - File metadata (size, line count, etc.)

## File Metadata Support

Files can include metadata in various formats:

**SQL Files:**
```sql
---
name: user_summary
description: User analytics view
depends_on: [users, orders]
materialized: view
---
SELECT ...
```

**JSON Files:**
```json
{
  "name": "api-config",
  "description": "Production API configuration", 
  "depends_on": ["database", "redis"],
  "version": "1.0.0"
}
```

**YAML Files:**
```yaml
name: k8s-deployment
description: Production deployment manifest
depends_on: [secrets, configmaps]
version: "1.2.0"
```

## Resource Operations

File discovery supports full CRUD operations:

- **CREATE/DISCOVER**: `kolumn apply` discovers and interpolates files
- **READ**: Access discovered file data via `${discover.name.*}` references  
- **UPDATE**: Files are re-discovered when inputs change
- **IMPORT**: Discover existing files with `kolumn import`

## Best Practices

### 1. File Organization
```
project/
├── kolumn/
│   ├── main.kl              # Main Kolumn configuration
│   └── variables.kl         # Variable definitions
├── sql/
│   ├── views/
│   ├── procedures/
│   └── migrations/
├── dags/                    # Airflow Python DAGs  
├── k8s/                     # Kubernetes manifests
└── config/                  # Application configurations
```

### 2. Input Management
```hcl
# Centralize inputs in variables
variable "database_config" {
  type = object({
    host = string
    port = number
    database = string
  })
}

# Use in discoveries
discover "kolumn_file" "app_config" {
  location = "./config/app.json"
  inputs = var.database_config
}
```

### 3. Dependency Tracking
```hcl
# Explicit dependencies for complex scenarios
discover "kolumn_file" "migration" {
  location = "./sql/migration_001.sql"
  inputs = {
    schema_name = "${postgres_schema.main.name}"
  }
  depends_on = [
    "postgres_schema.main",
    "postgres_table.users"
  ]
}
```

## Error Handling

The system provides detailed error information:

- **File not found**: Clear error message with expected location
- **Interpolation failures**: Identifies missing variables/resources
- **Syntax errors**: File-type specific validation errors
- **Dependency cycles**: Circular dependency detection

## Performance

- **Lazy loading**: Files are only read when referenced
- **Caching**: Interpolated content is cached until file changes
- **Parallel processing**: Multiple files discovered concurrently  
- **Incremental updates**: Only changed files are re-processed

## Integration with Kolumn Ecosystem

File discovery integrates seamlessly with:

- **Variable System**: Use HCL variables in interpolation
- **Data Objects**: Reference column schemas and metadata
- **State Management**: Track file state across runs
- **Provider Ecosystem**: Works with all 30+ external providers
- **Module System**: Share discovered files across modules

This system revolutionizes infrastructure-as-code by bridging the gap between declarative Kolumn configurations and existing file-based workflows, enabling seamless migration and hybrid architectures.