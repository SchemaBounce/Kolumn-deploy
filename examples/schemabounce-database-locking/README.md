# SchemaBounce with Mandatory Database-Based Locking

This example demonstrates how to configure Kolumn's SchemaBounce backend with mandatory database-based locking for secure, multi-user state management.

## Overview

**IMPORTANT**: Database-based locking is **mandatory** for all SchemaBounce backends. The system provides enterprise-grade state locking using any SQL database (PostgreSQL, MySQL, SQLite, etc.) to prevent concurrent modifications to Kolumn state files stored in SchemaBounce.

**Configuration Requirements**: Both `lock_database_provider` and `lock_database_url` are required fields for SchemaBounce backend configuration.

## Key Features

### 1. **Simple Single Table Design**
- Uses one table with a single row approach
- Boolean `is_locked` field for lock status
- Lock metadata including who, when, and what operation

### 2. **Universal SQL Compatibility**
- Works with PostgreSQL, MySQL, SQLite, MSSQL, and others
- Uses standard SQL with database-specific optimizations
- `ON CONFLICT` handling for concurrent lock attempts

### 3. **Enterprise-Grade Safety**
- Prevents concurrent state modifications
- Detailed lock information for debugging
- Automatic lock cleanup and validation
- Ping-before-access verification

### 4. **SchemaBounce Integration**
- Seamless integration with SchemaBounce state backend
- Locks coordinate with SchemaBounce API operations
- Independent database for locking (can be separate from state storage)

## Configuration

### Mandatory Configuration Requirements
```hcl
state {
  backend "schemabounce" {
    # SchemaBounce API settings (required)
    api_url = "http://localhost:8081"
    jwt = var.schemabounce_jwt
    # api_key = var.schemabounce_api_key  # Legacy fallback
    environment_id = var.environment_id

    # Database-based locking (MANDATORY FIELDS)
    lock_database_provider = "postgres"  # REQUIRED: Database type
    lock_database_url = "postgres://user:pass@localhost:5432/locks"  # REQUIRED: Connection URL
    lock_table_name = "kolumn_schemabounce_lock"  # Optional, defaults to this
  }
}
```

**⚠️ Configuration will fail if either `lock_database_provider` or `lock_database_url` is missing.**

### Supported Database Providers
- **PostgreSQL**: `lock_database_provider = "postgres"`
- **MySQL**: `lock_database_provider = "mysql"`
- **SQLite**: `lock_database_provider = "sqlite3"`
- **SQL Server**: `lock_database_provider = "sqlserver"`

### Database URL Formats
```bash
# PostgreSQL
postgres://username:password@host:5432/database?sslmode=disable

# MySQL
mysql://username:password@tcp(host:3306)/database?tls=false

# SQLite
sqlite3:///path/to/database.db

# SQL Server
sqlserver://username:password@host:1433?database=lockdb
```

## Lock Table Schema

The system automatically creates a lock table with this structure:

```sql
CREATE TABLE kolumn_schemabounce_lock (
    id VARCHAR(50) PRIMARY KEY DEFAULT 'state_lock',
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,
    lock_id VARCHAR(255),
    operation VARCHAR(100),
    who VARCHAR(255),
    version VARCHAR(50),
    acquired_at TIMESTAMP,
    path VARCHAR(500),
    CONSTRAINT single_row_lock CHECK (id = 'state_lock')
);
```

### Key Features:
- **Single Row Design**: Only one row with ID 'state_lock'
- **Atomic Operations**: Uses database transactions for lock operations
- **Lock Metadata**: Tracks who acquired the lock and when
- **Path Tracking**: Records the state file path being locked

## Lock Lifecycle

### 1. **Lock Acquisition**
```sql
UPDATE kolumn_schemabounce_lock
SET is_locked = TRUE,
    lock_id = $1,
    operation = $2,
    who = $3,
    version = $4,
    acquired_at = $5,
    path = $6
WHERE id = 'state_lock' AND is_locked = FALSE
```

### 2. **Lock Release**
```sql
UPDATE kolumn_schemabounce_lock
SET is_locked = FALSE,
    lock_id = NULL,
    operation = NULL,
    who = NULL,
    version = NULL,
    acquired_at = NULL,
    path = NULL
WHERE id = 'state_lock' AND lock_id = $1
```

### 3. **Lock Status Check**
```sql
SELECT is_locked FROM kolumn_schemabounce_lock WHERE id = 'state_lock'
```

## Usage Examples

### Supplying Credentials Safely
Preferred: keep secrets out of files by using `klvars` placeholders and CLI overrides:

```bash
# environments/dev.klvars
lock_database_provider = "postgres"
environment_id        = "env_dev"
# lock_database_url and tokens are provided at runtime

# Local (JWT + lock DB URL from environment/secret store)
kolumn plan  -var-file=environments/dev.klvars \
  --var "schemabounce_jwt=$SCHEMABOUNCE_JWT" \
  --var "lock_database_url=$LOCK_DATABASE_URL"

kolumn apply -var-file=environments/dev.klvars \
  --var "schemabounce_jwt=$SCHEMABOUNCE_JWT" \
  --var "lock_database_url=$LOCK_DATABASE_URL"

# GitHub Actions
kolumn apply -var-file=environments/dev.klvars \
  --var "schemabounce_jwt=${{ secrets.SCHEMABOUNCE_JWT }}" \
  --var "lock_database_url=${{ secrets.LOCK_DATABASE_URL }}"
```

### Concurrent Access Behavior
```bash
# Terminal 1
kolumn apply  # Acquires lock

# Terminal 2 (while Terminal 1 is running)
kolumn plan   # Gets lock error:
# Error: State is locked
# Lock ID: apply-operation-1234567890
# Locked by: user@hostname
# Operation: apply
# Acquired: 2024-01-15 10:30:45 UTC
```

## Best Practices

### 1. **Separate Lock Database**
```hcl
# Use a dedicated database for locking
state {
  backend "schemabounce" {
    # State stored in SchemaBounce
    api_url = "https://api.schemabounce.com"

    # Locks stored in separate database
    lock_database_provider = "postgres"
    lock_database_url = "postgres://locks:pass@locks.company.com:5432/kolumn_locks"
  }
}
```

### 2. **High Availability Setup**
```hcl
# Use replicated database for lock reliability
state {
  backend "schemabounce" {
    api_url = "https://api.schemabounce.com"

    # Primary-replica setup
    lock_database_provider = "postgres"
    lock_database_url = "postgres://user:pass@primary.db.company.com:5432/locks"
  }
}
```

### 3. **Lock Table Monitoring**
```sql
-- Monitor lock status
SELECT
    is_locked,
    lock_id,
    operation,
    who,
    acquired_at,
    EXTRACT(EPOCH FROM (NOW() - acquired_at)) as lock_duration_seconds
FROM kolumn_schemabounce_lock
WHERE id = 'state_lock';

-- Check for stale locks (older than 1 hour)
SELECT *
FROM kolumn_schemabounce_lock
WHERE id = 'state_lock'
  AND is_locked = true
  AND acquired_at < NOW() - INTERVAL '1 hour';
```

### 4. **Emergency Lock Release**
```sql
-- EMERGENCY ONLY: Force release stale lock
UPDATE kolumn_schemabounce_lock
SET is_locked = FALSE,
    lock_id = NULL,
    operation = NULL,
    who = NULL,
    version = NULL,
    acquired_at = NULL,
    path = NULL
WHERE id = 'state_lock';
```

## Configuration Options

### Required Fields
- `lock_database_provider`: Database type (postgres, mysql, sqlite3, etc.)
- `lock_database_url`: Database connection string

### Optional Fields
- `lock_table_name`: Custom table name (default: "kolumn_schemabounce_lock")

### SchemaBounce Integration
The locking system integrates seamlessly with all SchemaBounce features:
- **State Versioning**: Locks coordinate with state version tracking
- **Encryption**: Lock operations respect SchemaBounce encryption settings
- **Audit Logging**: Lock acquisition/release events are logged
- **Multi-tenancy**: Locks work with business_id and environment_id isolation

## Troubleshooting

### Common Issues

#### 1. **Database Connection Failed**
```
Error: failed to open lock database: connection refused
```
**Solution**: Verify database is running and connection URL is correct

#### 2. **Lock Table Creation Failed**
```
Error: failed to create lock table: permission denied
```
**Solution**: Ensure database user has CREATE TABLE permissions

#### 3. **Lock Already Held**
```
Error: State is locked by user@host (operation: apply)
```
**Solution**: Wait for operation to complete or force-release if stale

#### 4. **Lock Manager Not Configured**
```
Error: lock manager not configured
```
**Solution**: Check lock_database_provider and lock_database_url are set

### Debug Mode
```bash
# Enable debug logging to see lock operations
export KOLUMN_LOG_LEVEL=debug
kolumn plan
```

## Architecture Benefits

### 1. **Scalability**
- Database handles concurrent access automatically
- Works with any number of Kolumn instances
- No coordination required between clients

### 2. **Reliability**
- Database transactions ensure atomic lock operations
- Lock state persists across Kolumn restarts
- Detailed metadata for debugging

### 3. **Flexibility**
- Works with any SQL database
- Can use existing database infrastructure
- Independent of SchemaBounce state storage

### 4. **Enterprise Ready**
- Integrates with existing database monitoring
- Supports backup and disaster recovery
- Audit trail of all lock operations

## Security Considerations

### 1. **Database Access**
- Use dedicated database user for lock operations
- Grant minimal required permissions (SELECT, INSERT, UPDATE, DELETE on lock table)
- Use SSL/TLS for database connections in production

### 2. **Connection Security**
```hcl
state {
  backend "schemabounce" {
    # Secure database connection
    lock_database_url = "postgres://user:pass@host:5432/locks?sslmode=require"
  }
}
```

### 3. **Network Security**
- Place lock database on secure network
- Use VPN or private networks for database access
- Monitor database access logs for unauthorized attempts

This database-based locking system provides enterprise-grade coordination for Kolumn state management while integrating seamlessly with SchemaBounce's comprehensive schema management platform.
