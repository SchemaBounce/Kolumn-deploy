# SchemaBounce Backend Configuration

This directory contains examples for configuring Kolumn to use SchemaBounce as the state backend.

## Overview

The SchemaBounce backend provides enterprise-grade state management with the following features:

- **Cloud-native**: Fully managed state storage
- **Secure**: API key authentication with HTTPS
- **Versioned**: Built-in state versioning support  
- **Encrypted**: State encryption at rest and in transit
- **Multi-tenant**: Support for multiple businesses/environments
- **Audit logging**: Complete audit trail for compliance

## Configuration

### Basic Configuration

```hcl
state = {
  backend = "schemabounce"
  config = {
    api_key        = "${var.schemabounce_api_key}"
    environment_id = "env_production_123" 
    api_url        = "https://api.schemabounce.com"
  }
}
```

### Required Fields

- `api_key`: Your SchemaBounce API key for authentication
- `environment_id`: Unique identifier for your environment

### Optional Fields

- `business_id`: For multi-tenant scenarios (optional)
- `api_url`: SchemaBounce API endpoint (defaults to localhost:8080 for development)
- `timeout_seconds`: Request timeout in seconds (default: 30)
- `retries`: Number of retry attempts (default: 3)
- `enable_versioning`: Enable state versioning (default: true)
- `enable_encryption`: Enable state encryption (default: true)
- `data_residency`: Data residency preference - "us", "eu", or "apac" (default: "us")
- `retention_policy`: State retention policy - "30d", "90d", "1y", or "forever" (default: "1y")
- `audit_logging`: Enable audit logging (default: true)

## Migration from Legacy Configuration

The SchemaBounce backend maintains backward compatibility with legacy field names:

| Legacy Field | New Field | Notes |
|--------------|-----------|--------|
| `project_id` | `environment_id` | Automatically mapped |
| `workspace` | `environment_id` | Automatically mapped |
| `organization` | `environment_id` | Automatically mapped |
| `base_url` | `api_url` | Both still work |
| `api_secret` | (removed) | No longer required |

## Environment Variables

You can use environment variables for sensitive configuration:

```bash
export KOLUMN_SCHEMABOUNCE_API_KEY="your-api-key-here"
```

## Examples

- `main.kl`: Complete SchemaBounce backend configuration
- `legacy_migration.kl`: Migration from legacy configuration format

## API Endpoints

The SchemaBounce backend uses these API endpoints:

- `GET /health`: Health check (public)
- `GET /api/v1/environments/{environment_id}/state-file`: Load state  
- `PUT /api/v1/environments/{environment_id}/state-file`: Save state
- `DELETE /api/v1/environments/{environment_id}/state-file`: Delete state

Query parameters:
- `business_id`: Optional business context filter

## Backend Capabilities

| Feature | Supported |
|---------|-----------|
| State Storage | ✅ |
| State Versioning | ✅ |
| State Encryption | ✅ |
| State Locking | ❌ |
| Multi-region | ✅ |
| Compression | ✅ |

Note: State locking is not supported by the SchemaBounce API. Operations are atomic at the API level.

## Troubleshooting

### Authentication Issues

If you get authentication errors:

1. Verify your API key is correct
2. Ensure the API key has permissions for the specified environment
3. Check that the `environment_id` exists in your SchemaBounce account

### Connection Issues

If you get connection errors:

1. Verify the `api_url` is reachable
2. Check firewall/network policies
3. Ensure HTTPS is used for production endpoints

### Legacy Configuration

If migrating from legacy configuration:

1. The backend automatically maps legacy field names
2. No immediate migration required
3. Update to new field names when convenient