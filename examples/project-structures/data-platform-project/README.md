# Data Platform Project Structure

This example demonstrates a **comprehensive data platform** structure with advanced governance, multi-provider integration, and enterprise-grade data management.

## Project Structure

```
data-platform-project/
├── providers.kl             # Multi-provider configuration (6 providers)
├── variables.kl             # Comprehensive variable declarations
├── main.kl                 # Core data platform resources
├── outputs.kl              # Detailed platform outputs
├── variables.klvars        # Development environment values
├── data/                   # Data governance and streaming configs
│   ├── governance.kl       # Classifications, RBAC, universal data objects
│   └── streaming.kl        # Kafka topics, streams, connectors
└── README.md               # This documentation
```

## File Loading Order

```
1. providers.kl              # Provider configurations (6 providers)
2. variables.kl + variables.klvars  # Variable declarations and values
3. data/governance.kl         # Data governance framework (loaded first)
4. data/streaming.kl          # Streaming infrastructure
5. main.kl                   # Core resources using universal data objects
6. outputs.kl                # Comprehensive platform outputs
```

## Key Features Demonstrated

### 🏛️ **Universal Governance Framework**
- **Data Classifications**: PII, Financial, Internal, Public with provider-specific encryption
- **Universal Data Objects**: Customer and Transaction objects used across all providers
- **Role-Based Access Control (RBAC)**: Data Scientist, Financial Analyst, Data Engineer roles
- **Cross-Provider Encryption**: Different encryption methods per provider and classification

### 🔄 **Multi-Provider Data Platform**
- **PostgreSQL**: Analytical database with row-level security and partitioning
- **Snowflake**: Data warehouse with masking policies and clustering
- **Kafka**: Real-time streaming with schema registry integration
- **MongoDB**: Document store with field-level encryption and sharding
- **S3**: Data lake with lifecycle policies and KMS encryption
- **Kolumn Provider**: Universal governance orchestrating all providers

### 📊 **Real-Time Data Processing**
- **Kafka Topics**: Customer events, transactions, audit logs
- **Stream Processing**: Real-time customer enrichment and fraud detection
- **Kafka Connect**: CDC from PostgreSQL to Kafka, streaming to Snowflake
- **Schema Registry**: Avro schemas with backward compatibility

### 🔒 **Enterprise Security & Compliance**
- **Classification-Based Encryption**: Automatic encryption based on data classification
- **Audit Logging**: Comprehensive access logging across all systems
- **Data Retention**: Configurable retention policies per classification
- **Compliance**: PCI DSS, SOX compliance tags and controls

## Usage

### Initialize and Deploy

```bash
# Navigate to the project directory
cd examples/project-structures/data-platform-project

# Initialize the project
kolumn init

# View the comprehensive execution plan
kolumn plan

# Apply with development configuration
kolumn apply

# Apply with production-grade encryption
kolumn apply -var="encryption_level=maximum" -var="environment=prod"
```

### Environment-Specific Deployments

**Development**:
```bash
kolumn apply -var-file="development.klvars"
```

**Staging**:
```bash
kolumn apply -var-file="staging.klvars" -var="encryption_level=high"
```

**Production**:
```bash
kolumn apply -var-file="production.klvars" \
  -var="encryption_level=maximum" \
  -var="enable_audit_logging=true"
```

### Data Object Usage

The platform uses **Universal Data Objects** that automatically adapt to each provider:

```hcl
# Single definition works across all providers
kolumn_data_object.customer = {
  # Used by PostgreSQL as tables
  # Used by Snowflake as dimension tables with masking
  # Used by Kafka as Avro schemas
  # Used by MongoDB as document schemas with encryption
  # Used by S3 as Parquet file structures
}
```

### Governance in Action

```hcl
# Automatic encryption based on classification
column "email" {
  type = "VARCHAR(255)"
  classifications = [kolumn_classification.pii]
  # Automatically encrypted in:
  # - PostgreSQL: Column-level AES-256-GCM
  # - Snowflake: Dynamic data masking
  # - Kafka: Field-level AES-256-CTR
  # - MongoDB: Field-level encryption
  # - S3: KMS encryption with PII key
}
```

### Role-Based Access

```hcl
# Data scientists see masked PII data
kolumn_role.data_scientist = {
  # email becomes "jo****@example.com"
  # phone becomes "***-***-1234"
}

# Financial analysts see full financial data
kolumn_role.financial_analyst = {
  # Full access to transaction amounts and payment methods
}
```

## When to Use

The data platform structure is ideal for:

- **Enterprise data platforms**: Multi-provider, governance-first architecture
- **Financial services**: PCI DSS compliance and financial data protection
- **Healthcare**: HIPAA compliance with PII protection and audit logging
- **Real-time analytics**: Streaming data processing with batch analytics
- **Data science**: Governed access to sensitive data with role-based masking
- **Regulatory compliance**: Comprehensive audit trails and data retention

## Template Generation

Generate this structure using:

```bash
kolumn init --template data-platform
```

## Key Architecture Patterns

### 1. **Governance-First Design**
- Data classifications defined before any resources
- Universal data objects ensure consistent governance
- Encryption and access controls applied automatically

### 2. **Multi-Provider Orchestration**
- Single configuration manages 6 different providers
- Cross-provider data flows (PostgreSQL → Kafka → Snowflake)
- Provider-specific optimizations (partitioning, clustering, sharding)

### 3. **Real-Time + Batch Integration**
- CDC captures PostgreSQL changes to Kafka
- Stream processing enriches data in real-time
- Batch analytics in Snowflake on processed data

### 4. **Security by Design**
- Classification-based encryption ensures data protection
- Row-level security and masking policies
- Audit logging tracks all data access

### 5. **Scalable Storage Architecture**
- Time-series partitioning for high-volume transactions
- S3 data lake with intelligent tiering
- MongoDB sharding for document scale

## Monitoring and Observability

The platform exposes comprehensive outputs for monitoring:

```bash
# View platform configuration
kolumn output environment_configuration

# Check data governance settings
kolumn output data_classifications

# Monitor streaming infrastructure
kolumn output kafka_topics
```

This structure represents **enterprise-grade data platform architecture** with built-in governance, security, and scalability using Kolumn's universal data management capabilities.