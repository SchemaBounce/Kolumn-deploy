# Standard Project Structure

This example demonstrates the **standard** Kolumn project structure with proper multi-file organization and separation of concerns.

## Project Structure

```
standard-project/
├── providers.kl          # Provider configurations
├── variables.kl          # Variable declarations with validation
├── main.kl              # Resource definitions
├── outputs.kl           # Output declarations
├── variables.klvars     # Variable values
└── README.md            # This documentation
```

## File Loading Order

Kolumn loads files in this specific order to ensure proper dependency resolution:

1. **`providers.kl`** - Provider configurations loaded first
2. **`variables.kl`** + **`variables.klvars`** - Variable declarations and values
3. **`main.kl`** - Main resource definitions
4. **`outputs.kl`** - Output declarations loaded last

## Features Demonstrated

- **Separation of concerns**: Each file has a specific purpose
- **Variable system**: Parameterized configuration with type validation
- **Multiple providers**: PostgreSQL and Redis integration
- **Cross-file references**: Resources reference variables from other files
- **Outputs**: Exposing important values for external consumption
- **Environment-aware**: Configuration adapts based on environment variable

## Usage

Initialize and apply the standard project:

```bash
# Navigate to the project directory
cd examples/project-structures/standard-project

# Initialize the project
kolumn init

# View the execution plan
kolumn plan

# Apply with default values
kolumn apply

# Apply with custom variable values
kolumn apply -var="environment=staging" -var="app_name=my-blog"

# Apply with production variables
kolumn apply -var-file="production.klvars"
```

## Variable Configuration

Create environment-specific `.klvars` files:

**development.klvars**:
```hcl
environment = "dev"
database_password = "dev_password"
```

**production.klvars**:
```hcl
environment = "prod" 
database_host = "prod-db.example.com"
database_password = "secure_prod_password"
redis_host = "prod-redis.example.com"
```

## When to Use

The standard structure is ideal for:

- **Production applications**: Proper organization for maintainability
- **Team projects**: Clear file boundaries for collaboration
- **Multi-environment**: Same configuration across dev/staging/prod
- **Complex configurations**: Multiple providers and resources
- **CI/CD integration**: Parameterized deployments

## Template Generation

Generate this structure using:

```bash
kolumn init --template standard
```

## Key Characteristics

- **Multi-file organization**: Logical separation of concerns
- **Variable-driven**: Parameterized and environment-aware
- **Cross-file references**: Variables used across multiple files
- **Output management**: Important values exposed for external use
- **Type safety**: Variable validation and type checking
- **Environment support**: Configuration adapts to environment context

This structure balances **organization** with **simplicity**, making it suitable for most production Kolumn projects.