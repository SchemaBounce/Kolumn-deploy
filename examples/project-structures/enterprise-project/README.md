# Enterprise Data Platform Project

This is a comprehensive enterprise-grade Kolumn project demonstrating data-centric architecture patterns, multi-environment configuration, and advanced governance capabilities.

## 🏗️ Architecture Overview

This project showcases Kolumn's **data-centric approach** to infrastructure-as-code, focusing on:

- **Universal Data Governance**: Classifications, RBAC, and compliance across all providers
- **Multi-Provider Data Integration**: PostgreSQL, Snowflake, Kafka, MongoDB, S3
- **Real-time Streaming**: Kafka-based event processing and fraud detection
- **Data Warehousing**: Snowflake analytical databases with OLAP capabilities
- **Environment Separation**: Development, staging, and production configurations

## 📁 Project Structure

```
enterprise-project/
├── providers.kl                    # Provider configurations with version constraints
├── variables.kl                    # Variable declarations for all modules
├── main.kl                         # Core data platform resources and module integration
├── outputs.kl                      # Comprehensive outputs for monitoring and integration
│
├── environments/                   # Environment-specific variable overrides
│   ├── development/
│   │   └── development.klvars     # Development environment settings
│   ├── staging/
│   │   └── staging.klvars         # Staging environment (production-like)
│   └── production/
│       └── production.klvars      # Production environment (high-security)
│
├── data/                          # Data governance and policy definitions
│   ├── governance/
│   │   └── governance.kl          # Universal data classifications and RBAC
│   └── policies/
│       └── data_access_policy.kl  # Comprehensive access control policies
│
└── modules/                       # Auto-discovered data-centric modules
    ├── data-warehouse/            # Snowflake analytical databases and OLAP
    │   └── main.kl
    ├── streaming/                 # Kafka topics, stream processing, connectors
    │   └── main.kl
    └── governance/                # Universal governance, classifications, RBAC
        └── main.kl
```

## 🎯 Data-Centric Design Philosophy

### Why Data-Centric, Not Infrastructure-Centric?

Unlike traditional IaC tools that focus on infrastructure (networking, compute, storage), Kolumn is designed specifically for **data platform operations**:

**❌ Traditional IaC Focus:**
- Virtual machines, load balancers, security groups
- Generic infrastructure provisioning
- Application-agnostic resource management

**✅ Kolumn's Data-Centric Focus:**
- Data classifications, lineage, and governance
- Cross-provider data integration
- Data-aware security and compliance
- Business logic in data transformations

### Core Data Platform Components

#### 1. **Data Warehouse Module** (`modules/data-warehouse/`)
- **Snowflake Databases**: Analytics, raw data, curated data layers
- **Dimensional Modeling**: Customer dimensions, transaction facts
- **Analytical Views**: Customer summaries, revenue reporting
- **Automation**: Stored procedures, scheduled tasks
- **Performance**: Clustering, partitioning, auto-scaling

#### 2. **Streaming Module** (`modules/streaming/`)
- **Kafka Topics**: Customer events, transactions, quality alerts
- **Stream Processing**: Real-time enrichment, fraud detection
- **Data Connectors**: CDC from PostgreSQL, sink to Snowflake
- **Schema Registry**: AVRO schemas with evolution management
- **Data Quality**: Real-time monitoring and alerting

#### 3. **Governance Module** (`modules/governance/`)
- **Universal Classifications**: PII, Financial, Confidential, Public
- **Cross-Provider Encryption**: Different strategies per data store
- **RBAC System**: Role-based access with data-aware permissions
- **Compliance Automation**: GDPR, SOX, PCI-DSS controls

## 🔐 Enterprise Security & Compliance

### Multi-Tier Data Classifications

```hcl
# Example: Customer email field with maximum security
column \"email\" {
  type = \"VARCHAR(255)\"
  classifications = [kolumn_classification.highly_sensitive_pii]
  
  # Automatically encrypted differently per provider:
  # - PostgreSQL: Column-level AES-256-GCM
  # - Snowflake: Dynamic data masking
  # - Kafka: Envelope encryption
  # - MongoDB: Field-level encryption
  # - S3: Client-side encryption with KMS
}
```

### Cross-Provider RBAC

```hcl
# Data scientists get masked access to PII across ALL providers
create \"kolumn_role\" \"data_scientist\" {
  permissions = [kolumn_permission.data_scientist_masked_access]
  
  # Same role works across PostgreSQL, Snowflake, Kafka, etc.
  # with appropriate transformations per provider
}
```

### Environment-Based Security Scaling

| Environment | Compliance Level | Encryption | Audit Logging | Session Recording |
|-------------|------------------|------------|---------------|-------------------|
| Development | `basic` | Standard | Basic | Disabled |
| Staging | `standard` | High | Enhanced | Disabled |
| Production | `strict` | Maximum | Complete | Enabled |

## 🚀 Getting Started

### Prerequisites

1. **Kolumn CLI** installed and configured
2. **Provider credentials** configured as environment variables:
   ```bash
   export POSTGRES_PROD_PASSWORD="..."
   export SNOWFLAKE_PROD_PASSWORD="..."
   export MONGODB_PROD_CONNECTION_STRING="..."
   ```

### Deployment Workflow

#### 1. Initialize the Project
```bash
# Initialize Kolumn workspace
kolumn init

# The project structure will be automatically discovered:
# - providers.kl loaded first
# - variables.kl + environment.klvars merged
# - data/*.kl loaded for governance
# - modules/*.kl auto-discovered and registered
# - main.kl processes with module integration
# - outputs.kl loaded last
```

#### 2. Environment-Specific Planning
```bash
# Development environment
kolumn plan -var-file=environments/development/development.klvars

# Staging environment  
kolumn plan -var-file=environments/staging/staging.klvars

# Production environment
kolumn plan -var-file=environments/production/production.klvars
```

#### 3. Apply Changes
```bash
# Deploy to development
kolumn apply -var-file=environments/development/development.klvars

# Deploy to staging (after development validation)
kolumn apply -var-file=environments/staging/staging.klvars

# Deploy to production (after staging validation)
kolumn apply -var-file=environments/production/production.klvars
```

### Module Auto-Discovery

Kolumn automatically discovers and registers modules in the `modules/` directory:

```bash
$ kolumn modules list
┌─────────────────────┬──────────────────────────────────┬─────────┐
│ Module Name         │ Path                             │ Status  │
├─────────────────────┼──────────────────────────────────┼─────────┤
│ data-warehouse      │ modules/data-warehouse           │ Active  │
│ streaming           │ modules/streaming                │ Active  │
│ governance          │ modules/governance               │ Active  │
└─────────────────────┴──────────────────────────────────┴─────────┘
```

## 📊 Data Integration Patterns

### 1. Change Data Capture (CDC) Pipeline

```
PostgreSQL → Kafka (CDC) → Snowflake
     ↓
   Kafka Streams (Enrichment)
     ↓  
   Real-time Analytics
```

### 2. Universal Data Object Usage

```hcl
# Define once in governance module
create \"kolumn_data_object\" \"customer_profile\" {
  column \"email\" { 
    classifications = [kolumn_classification.highly_sensitive_pii]
  }
}

# Use everywhere with appropriate governance
create \"postgres_table\" \"customers\" {
  columns = module.governance.universal_data_objects.customer_profile.columns
  # Inherits: encryption, RBAC, audit requirements
}

create \"kafka_topic\" \"customer_events\" {
  # Same governance applied to streaming data
  schema = derive_from_data_object(customer_profile)
}
```

### 3. Cross-Provider Data Lineage

```
Raw Data (PostgreSQL) 
    ↓ 
Streaming Events (Kafka)
    ↓
Analytics Layer (Snowflake)
    ↓
Data Lake (S3)
    ↓
Document Store (MongoDB)
```

## 🔍 Monitoring & Observability

### Built-in Data Quality Monitoring

- **Schema Evolution**: Automatic compatibility checking
- **Freshness Monitoring**: Detect delayed data pipelines  
- **Completeness Validation**: Required field enforcement
- **Accuracy Checks**: Range and format validation

### Enterprise Dashboards

Access operational dashboards through outputs:

```bash
# Get dashboard URLs
kolumn output operational_dashboards

# Monitor data quality alerts
kolumn output data_quality_monitoring

# Review compliance status
kolumn output security_compliance
```

## 🧪 Testing Data Transformations

### Universal Validation Commands

```bash
# Validate all files (SQL, HCL, Python, Java)
kolumn validate

# Test data transformations
kolumn test --pattern \"**/*.sql\"

# Check data lineage
kolumn lineage --trace customer_profile

# Format all project files  
kolumn fmt
```

### Environment Validation

```bash
# Validate development environment
kolumn validate -var-file=environments/development/development.klvars

# Run integration tests
kolumn test --environment=staging --integration
```

## 📋 Best Practices

### 1. **Data Classification First**
- Always define data classifications before creating resources
- Use universal data objects for consistency
- Leverage governance-aware resource creation

### 2. **Environment Progression**
- Development → Staging → Production
- Gradually increase security and compliance levels
- Test governance policies in non-production first

### 3. **Module Organization**
- Keep data-centric modules focused (warehouse, streaming, governance)
- Avoid infrastructure modules (networking, compute, storage)
- Use auto-discovery for seamless module integration

### 4. **Security by Design**
- Classifications drive encryption decisions
- RBAC permissions follow principle of least privilege  
- Audit logging enabled by default in production

### 5. **Cost Optimization**
- Environment-appropriate resource sizing
- Automated scaling and suspend policies
- Storage lifecycle management

## 🔧 Troubleshooting

### Common Issues

**Issue**: Module not discovered
```bash
# Solution: Check module structure
ls -la modules/data-warehouse/
# Ensure main.kl exists in module directory
```

**Issue**: Variable not found
```bash  
# Solution: Check variable loading order
kolumn validate --debug
# Variables.kl + environment.klvars should merge correctly
```

**Issue**: Cross-provider reference errors
```bash
# Solution: Verify module outputs
kolumn modules show governance --outputs
```

### Debug Commands

```bash
# Show complete configuration
kolumn show config

# Trace variable resolution
kolumn variables list --trace

# Module dependency analysis
kolumn modules graph
```

## 🌟 Key Features Demonstrated

- **✅ Data-Centric Architecture**: Focus on data operations, not infrastructure
- **✅ Universal Governance**: Cross-provider classifications and RBAC
- **✅ Multi-Environment**: Development, staging, production configurations
- **✅ Auto-Discovery**: Seamless module and provider integration
- **✅ Real-time Processing**: Kafka streaming with ML-powered fraud detection
- **✅ Enterprise Security**: Encryption, audit trails, compliance automation
- **✅ Operational Excellence**: Monitoring, alerting, cost optimization

## 📚 Related Examples

- **Minimal Project**: Single-file PostgreSQL setup
- **Standard Project**: Multi-file structure with basic governance
- **Data Platform Project**: Streaming + warehousing without enterprise features

---

**🎯 Enterprise Grade**: This project represents production-ready, enterprise-scale data platform architecture using Kolumn's data-centric approach to infrastructure-as-code.