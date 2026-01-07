# Kolumn Migration Examples

This directory contains examples demonstrating Kolumn's migration system for complex data transformations that require explicit forward/backward steps.

## When to Use Migrations

**Kolumn is state-driven** (like Terraform): you declare the desired shape and Kolumn converges to it. Most schema changes should use the normal `kolumn plan` / `kolumn apply` workflow.

**Migrations are for exceptions** - use them when state convergence alone is risky or insufficient:

| Use Case | Example | Why Migration? |
|----------|---------|----------------|
| Column type changes | `text` → `integer` | Requires data normalization |
| Large backfills | Adding computed columns | Needs batching to avoid locks |
| Phased swaps | Encrypt existing data | Requires dual-write triggers |
| Risky transformations | Restructure tables | Needs explicit rollback plan |

## Examples

### 1. Column Type Change (`column_type_change.kl`)

Demonstrates converting a text column to integer with data normalization:

```hcl
migration "column_type" "users_auth_provider_id_to_int" {
  provider = postgres.primary
  resource = postgres_table.users
  column   = "auth_provider_id"

  from_type = "text"
  to_type   = "integer"

  forward {
    prechecks = ["count_non_numeric table=users column=auth_provider_id"]
    steps = [
      "normalize_column table=users column=auth_provider_id condition=!numeric value=0",
      "alter_column_type table=users column=auth_provider_id from=text to=integer"
    ]
  }

  backward {
    steps = ["alter_column_type table=users column=auth_provider_id from=integer to=text"]
  }
}
```

### 2. Backfill Migration (`backfill_migration.kl`)

Demonstrates adding a new column and backfilling data in batches:

```hcl
migration "backfill" "add_full_name_column" {
  forward {
    steps = [
      "add_column table=customers column=full_name type=varchar(201) nullable=true",
      "backfill_column table=customers column=full_name expression=first_name||' '||last_name batch_size=10000 sleep_ms=100",
      "alter_column_nullable table=customers column=full_name nullable=false"
    ]
  }
}
```

### 3. Phased Swap (`phased_swap.kl`)

Demonstrates zero-downtime column replacement using dual-write triggers:

```hcl
migration "phased_swap" "encrypt_ssn_column" {
  forward {
    steps = [
      "add_column table=employees column=ssn_encrypted type=bytea nullable=true",
      "create_trigger table=employees trigger=trg_dual_write_ssn ...",
      "backfill_column table=employees column=ssn_encrypted expression=encrypt_ssn(ssn) ...",
      "drop_trigger table=employees trigger=trg_dual_write_ssn",
      "rename_column table=employees column=ssn to=ssn_plaintext_backup",
      "rename_column table=employees column=ssn_encrypted to=ssn"
    ]
  }
}
```

## CLI Commands

```bash
# Preview migrations
kolumn migration plan
kolumn migrate plan                    # Alias

# Preview specific migration
kolumn migration plan --target my_migration

# Preview with SQL output
kolumn migration plan --sql-only

# Apply migrations (forward)
kolumn migration apply
kolumn migrate apply                   # Alias
kolumn apply                           # Also applies migrations

# Apply specific migration
kolumn migration apply --target my_migration

# Apply with precheck bypass (risky!)
kolumn migration apply --allow-risky-migrations

# Rollback migrations
kolumn migration rollback --target my_migration
kolumn migrate rollback --target my_migration
kolumn apply --rollback --rollback-target my_migration

# Check migration status
kolumn migration status

# Validate migration definitions
kolumn migration validate
```

## Safety Options

Every migration can specify safety hints:

```hcl
safety {
  quarantine     = true    # Create backup before destructive changes
  quarantine_ttl = "7d"    # Keep quarantine data for rollback
  lock_table     = true    # Acquire exclusive lock during migration
  timeout        = "10m"   # Maximum migration duration
  require_backup = true    # Require backward steps to be defined
}
```

## Structured Operations

Migrations use structured operations (not raw SQL) validated by providers:

| Operation | Description | Parameters |
|-----------|-------------|------------|
| `alter_column_type` | Change column data type | `table`, `column`, `from`, `to` |
| `normalize_column` | Update values matching condition | `table`, `column`, `condition`, `value` |
| `add_column` | Add new column | `table`, `column`, `type`, `nullable`, `default` |
| `drop_column` | Remove column | `table`, `column` |
| `rename_column` | Rename column | `table`, `column`, `to` |
| `backfill_column` | Populate column in batches | `table`, `column`, `expression`, `batch_size`, `sleep_ms` |
| `add_index` | Create index | `table`, `columns`, `method`, `unique` |
| `drop_index` | Remove index | `table`, `index` |
| `create_trigger` | Create database trigger | `table`, `trigger`, `timing`, `events`, `body` |
| `drop_trigger` | Remove trigger | `table`, `trigger` |
| `create_shadow_table` | Create copy of table | `table`, `shadow`, `columns` |
| `swap_shadow_table` | Atomically swap tables | `table`, `shadow`, `backup` |
| `validate_column` | Check column data | `table`, `column`, `condition` |
| `validate_row_count` | Compare row counts | `table`, `shadow`, `tolerance` |

## Prechecks

Prechecks run during `plan` phase and block `apply` unless `--allow-risky-migrations` is used:

| Precheck | Description | Parameters |
|----------|-------------|------------|
| `count_non_numeric` | Count rows with non-numeric values | `table`, `column` |
| `estimate_row_count` | Estimate rows for time prediction | `table`, `warn_threshold` |
| `table_exists` | Verify table exists | `table` |
| `function_exists` | Verify function exists | `schema`, `function` |

## Migration History

Migration history is stored in SchemaBounce state (capped at 500 entries):

```bash
# View migration history
kolumn migration status

# Output:
# Migration history (SchemaBounce backend): applied=5 pending=2 total_defined=7
#   - 2024-12-15T10:30:00Z encrypt_ssn_column forward provider=postgres.primary ops=9 quarantine=qrtn_abc123
#   - 2024-12-14T15:20:00Z add_full_name_column forward provider=postgres.primary ops=4 quarantine=none
# Pending migrations:
#   - add_order_count_column
#   - restructure_audit_logs
```

## Best Practices

1. **Always define backward steps** - Enable rollback for production safety
2. **Use prechecks** - Catch issues before applying changes
3. **Enable quarantine** - Keep backups for recovery
4. **Batch large operations** - Use `batch_size` and `sleep_ms` to avoid locks
5. **Test in staging first** - Validate migrations before production
6. **Monitor migration status** - Track applied/pending migrations in state

## Related Documentation

- [State-Driven Migrations](/docs/migrations/STATE_DRIVEN_MIGRATIONS.md) - Philosophy and design
- [Transformation Migrations](/docs/migrations/TRANSFORMATION_MIGRATIONS.md) - Detailed HCL reference
