# 🚀 Autonomous Column Propagation Example

This example demonstrates the most powerful feature of Kolumn: **autonomous column propagation** where changes to a source table schema automatically propagate across ALL related resources with zero manual updates required.

## 🎯 What This Example Shows

**Single Source of Truth**: One PostgreSQL table (`users`) serves as the authoritative schema definition.

**Automatic Propagation**: When columns change in the source, updates flow everywhere:
- ✅ PostgreSQL analytics tables get new columns
- ✅ Kafka topics update their schema registry
- ✅ Python DAGs adapt their processing logic
- ✅ SQL files receive new column variables
- ✅ YAML configurations update automatically

**Built-in Governance**: PII detection, encryption, and compliance policies apply automatically based on column names and patterns.

## 📁 Files in This Example

```
autonomous-column-propagation.kl    # Main Kolumn configuration
files/
├── user_analytics.sql              # SQL with column interpolation
├── user_processing_dag.py          # Python DAG with schema awareness
└── kafka_user_schema.yaml          # Kafka config with dynamic schema
```

## 🔄 The Autonomous Magic

### Step 1: Discover Source Schema
```hcl
# The SINGLE SOURCE OF TRUTH
discover "postgres_table" "source_users" {
  database_provider = provider.postgres
  table_name = "users"
  schema_name = "public"
}
```

### Step 2: Create Universal Data Object
```hcl
# Convert discovery into reusable schema
create "kolumn_data_object" "user_schema" {
  # ⚡ AUTONOMOUS: Dynamically inherits ALL columns (concise map style)
  columns = {
    for col_name, col in discover.postgres_table.source_users.columns : col_name => {
      name            = col_name
      type            = col.type
      classifications = contains(["email", "phone", "ssn"], col_name) ? [kolumn_classification.pii] : [kolumn_classification.public]
    }
  }
}
```

### Step 3: Everything Else Inherits Automatically
- **Related Tables**: Use column maps to inherit schema directly (`columns = kolumn_data_object.user_schema.columns`)
- **Kafka Topics**: Schema registry auto-updates with new fields
- **DAGs**: Processing logic adapts to new column structure
- **SQL Files**: Get new columns via `${user_columns}` interpolation
- **YAML Configs**: Dynamic field generation from schema

## 🧪 Testing the Autonomous Propagation

### Scenario 1: Add a New Column
```sql
-- 1. Change the source PostgreSQL table
ALTER TABLE users ADD COLUMN middle_name VARCHAR(100);

-- 2. Run Kolumn plan to see the magic
kolumn plan -c autonomous-column-propagation.kl
```

**What Happens Automatically:**
- ✅ `kolumn_data_object.user_schema` detects new column
- ✅ `postgres_table.user_analytics` adds `middle_name` column
- ✅ `postgres_table.user_archive` adds `middle_name` column  
- ✅ `kafka_topic.user_events` schema registry includes new field
- ✅ Python DAG gets `middle_name` in its processing config
- ✅ SQL files can reference `middle_name` via interpolation
- ✅ YAML configs include `middle_name` in field lists

### Scenario 2: Add a PII Column
```sql
-- 1. Add a sensitive data column
ALTER TABLE users ADD COLUMN social_security_number VARCHAR(50);

-- 2. Run Kolumn plan
kolumn plan -c autonomous-column-propagation.kl
```

**What Happens Automatically:**
- 🔍 **PII Detection**: Column name contains "ssn" → auto-classified as PII
- 🛡️ **Security Applied**: Encryption requirements applied automatically
- 🚫 **Kafka Exclusion**: PII excluded from public event streams
- 🔐 **Hash Generation**: Only hashes included in analytics processing
- 📋 **Audit Trail**: Access logging configured automatically
- 🚨 **Alerts**: Security team notified of new PII field

### Scenario 3: Remove a Column
```sql
-- 1. Drop a deprecated column
ALTER TABLE users DROP COLUMN deprecated_field;

-- 2. Run Kolumn plan
kolumn plan -c autonomous-column-propagation.kl
```

**What Happens Automatically:**
- ✅ Column removed from all derived tables
- ✅ Kafka schema evolution handles field removal
- ✅ DAG stops processing the dropped field
- ✅ SQL files lose access to the variable
- ✅ No broken references anywhere in the system

## 💡 Key Benefits

### 1. Zero Configuration Drift
- **Traditional**: Update schema in 12 different places manually
- **Kolumn**: Change source once, everything updates automatically

### 2. Built-in Data Governance  
- **PII Detection**: Automatic based on column names and patterns
- **Security Policies**: Applied consistently across all systems
- **Audit Trails**: Complete lineage from source to all derivatives

### 3. Developer Productivity
- **Single Schema**: Developers work with one authoritative definition
- **No Sync Issues**: Impossible to have mismatched schemas
- **Fast Iteration**: Add columns and test immediately across all systems

### 4. Operational Excellence
- **Drift Monitoring**: Automatic detection of schema changes
- **Validation Rules**: Ensure consistency across resources
- **Alert System**: Proactive notification of propagation issues

## 🏗️ Architecture Patterns

### Discovery Pattern
```hcl
# Discover existing infrastructure as source of truth
discover "postgres_table" "source" { ... }
discover "orm_model" "django_user" { ... }  
discover "kafka_topic" "events" { ... }
```

### Data Object Pattern
```hcl
# Create reusable schema definitions
create "kolumn_data_object" "universal_schema" {
  dynamic "column" {
    for_each = discover.source.columns
    content { ... }
  }
}
```

### Propagation Pattern
```hcl
# Everything else references the data object
create "postgres_table" "derived" {
  dynamic "column" {
    for_each = kolumn_data_object.universal_schema.columns
    content { ... }
  }
}
```

### File Interpolation Pattern
```hcl
# Files get schema via interpolation variables
discover "kolumn_file" "processing_logic" {
  inputs = {
    schema = kolumn_data_object.universal_schema.columns
  }
}
```

## 🔧 Advanced Features

### Classification-Aware Processing
```hcl
# Automatic PII detection and handling
classifications = contains(["email", "phone", "ssn"], column.key) ? [
  kolumn_classification.pii
] : [kolumn_classification.public]
```

### Cross-Provider Coordination
```hcl
# Same schema used across different providers
dynamic "column" {
  for_each = kolumn_data_object.user_schema.columns
  content {
    # PostgreSQL table
    # Kafka topic  
    # MongoDB collection
    # All use the same column definition
  }
}
```

### Schema Evolution Management
```hcl
# Built-in versioning and migration support
create "kolumn_validation" "schema_consistency" {
  rules = [{
    type = "schema_match"
    source = discover.postgres_table.source_users
    targets = [postgres_table.user_analytics]
  }]
}
```

## 🚀 Getting Started

1. **Set up your source table**:
   ```sql
   CREATE TABLE users (
     id BIGSERIAL PRIMARY KEY,
     email VARCHAR(255) UNIQUE,
     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
   );
   ```

2. **Run the example**:
   ```bash
   kolumn init
   kolumn plan -c autonomous-column-propagation.kl
   kolumn apply -c autonomous-column-propagation.kl
   ```

3. **Test the propagation**:
   ```sql
   ALTER TABLE users ADD COLUMN phone VARCHAR(20);
   kolumn plan -c autonomous-column-propagation.kl
   # Watch the magic happen! ✨
   ```

## 🎯 The Result

**One Schema Change → Universal Update**

This is not just Infrastructure-as-Code. This is **Schema-as-Code** - where your data structure definitions become the single source of truth that automatically coordinates your entire data ecosystem.

Welcome to the future of data infrastructure management! 🌟
