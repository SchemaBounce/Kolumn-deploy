# Kolumn Examples

This directory contains **4 comprehensive examples** that demonstrate Kolumn's revolutionary capabilities as an infrastructure-as-code tool with full Terraform protocol compatibility AND universal data governance.

## 🚀 Architecture Overview

**Kolumn's Hybrid Architecture**:
- **Kolumn Provider (this repository)**: Provides universal data governance with 5 core resources
- **External Providers (30+ separate repositories)**: Database, streaming, storage, orchestration providers developed with Kolumn's revolutionary SDK
- **Integration**: External providers consume Kolumn's governance layer for unified security and compliance

## 🎯 Quick Start Guide

Choose the example that best matches your use case:

| Use Case | Example | Complexity | Resources |
|----------|---------|------------|-----------|
| **Kolumn provider only** | [`kolumn-provider-only.kl`](#kolumn-provider-governance-foundation) | ⭐⭐ Beginner | 5 core resources |
| **Baseline schema setup** | [`demo-step1-baseline.kl`](#baseline-schema-demo) | ⭐⭐ Beginner | Foundation + external |
| **File discovery system** | [`universal-file-processing.kl`](#universal-file-processing) | ⭐⭐⭐ Intermediate | File discovery + external |
| **Multi-provider platform** | [`multi-provider-ecommerce.kl`](#multi-provider-e-commerce-platform) | ⭐⭐⭐⭐ Advanced | Complete ecosystem |

## 📂 Examples Overview

### 1. Kolumn Provider Governance Foundation  
**File**: `kolumn-provider-only.kl`  
**Focus**: Pure Kolumn provider resources without external dependencies  
**Complexity**: ⭐⭐ Beginner

Perfect starting point to understand Kolumn's governance foundation with ALL 5 core resources:

- **Data Classifications**: Security classifications (PII, financial, analytics, public, internal) with provider-specific encryption
- **Universal Data Objects**: Schema definitions that coordinate across external providers (customer, transaction, user_activity)
- **RBAC System**: Role-based access control with granular permissions and transformations
- **File Discovery**: Bidirectional file processing with SQL, Python, YAML, JSON support
- **Cross-Provider Integration**: Shows how external providers consume governance

**Kolumn Provider Resources (Complete List)**:
- `kolumn_classification` - Data security classifications with encryption configs
- `kolumn_data_object` - Universal schema definitions with provider configs  
- `kolumn_role` - RBAC roles with capabilities and restrictions
- `kolumn_permission` - Granular permissions with provider-specific transformations
- `kolumn_file` - File discovery with bidirectional processing

**Use This When**: Learning Kolumn's governance foundation or developing external providers that integrate with Kolumn.

### 2. Baseline Schema Demo
**File**: `demo-step1-baseline.kl`  
**Focus**: Foundation for autonomous schema propagation across providers  
**Complexity**: ⭐⭐ Beginner

Demonstrates how Kolumn data objects become the single source of truth:

- **Single Source Schema**: Define schema once in `kolumn_data_object`, use everywhere
- **External Provider Integration**: PostgreSQL and Kafka providers consume governance
- **Autonomous Propagation**: Changes to data objects automatically propagate
- **Classification System**: Basic PII and public classifications
- **File Discovery**: SQL file integration with resource references

**Architecture Pattern**: Kolumn governance → External provider resources
**Use This When**: Starting with schema governance and want to see provider integration.

### 3. Multi-Provider E-Commerce Platform
**File**: `multi-provider-ecommerce.kl`  
**Focus**: Complete data platform with universal governance  
**Complexity**: ⭐⭐⭐⭐ Advanced  

Demonstrates Kolumn's full "Terraform for the entire data stack" capability:

- **Universal Data Objects**: Customer, transaction, user activity schemas across all providers
- **Multi-Provider Architecture**: PostgreSQL (transactional), DynamoDB (NoSQL), Kafka (streaming), S3 (storage), Dagster (orchestration)
- **Classification-Driven Security**: Automatic encryption and compliance (PII, financial, analytics)
- **Complete RBAC**: Multiple roles with provider-specific transformations
- **Cross-Provider Coordination**: Unified governance across entire data ecosystem

**External Providers Used**: PostgreSQL, DynamoDB, Kafka, S3, Dagster (from separate repositories)
**Use This When**: Building a complete enterprise data platform with governance across multiple technologies.

### 4. Universal File Processing  
**File**: `universal-file-processing.kl`  
**Focus**: Revolutionary file discovery with bidirectional processing  
**Complexity**: ⭐⭐⭐ Intermediate

Showcases Kolumn's unique **File Discovery System** that no other infrastructure-as-code tool provides:

- **Bidirectional Processing**: Send inputs TO files AND extract outputs FROM files
- **Cross-Language Interpolation**: Use `${resource.name}` patterns in SQL, Python, YAML, JSON files
- **File-Type Smart Formatting**: Automatic value formatting per file type
- **Universal Resource References**: Reference database tables from Python DAGs, API configs from SQL queries
- **Advanced Dependency Tracking**: Automatic extraction of resource dependencies across languages
- **Chained File Discovery**: Files that reference other discovered files

**File Types Supported**:
- **SQL** (.sql): Views, procedures, data quality checks + schema extraction
- **Python** (.py): Airflow DAGs, ETL scripts + function/class extraction
- **YAML** (.yaml, .yml): Kubernetes deployments, dbt configurations + resource extraction
- **JSON** (.json): API configurations, monitoring settings + key-value extraction

**Kolumn Provider Resources**:
- `kolumn_file` - Bidirectional file discovery with input/output processing
- `kolumn_data_object` - Cross-language schema consistency
- `kolumn_classification` - Universal security across file types

**External Providers**: PostgreSQL, BigQuery, Airflow, Kubernetes, API services (from separate repositories)
**Use This When**: You have existing files (SQL, Python, YAML, JSON) and want to integrate them with Kolumn's governance while keeping files unchanged.

## 🛠 External Provider Integration

Kolumn's revolutionary architecture separates governance (this repository) from provider implementations (30+ separate repositories). Each external provider integrates with Kolumn's governance layer.

**Provider Development Options**:
- **Simple 4-Method SDK**: 70% less code with automatic RPC handling
- **Full Terraform Protocol**: 100% Terraform compatibility with 11-method support  
- **Hybrid Approach**: Mix patterns as needed for different resource complexity

**Provider Repositories** (developed separately):
- **Database**: `kolumn-provider-postgres`, `kolumn-provider-mysql`, `kolumn-provider-sqlite`, etc.
- **Streaming**: `kolumn-provider-kafka`, `kolumn-provider-kinesis`, `kolumn-provider-pulsar`
- **Storage**: `kolumn-provider-s3`, `kolumn-provider-gcs`, `kolumn-provider-azure-blob`
- **Orchestration**: `kolumn-provider-dagster`, `kolumn-provider-airflow`, `kolumn-provider-prefect`
- **Cloud**: `kolumn-provider-aws`, `kolumn-provider-azure`, `kolumn-provider-gcp`

**Integration Pattern**: External providers consume `kolumn_data_object`, `kolumn_classification`, `kolumn_role`, and `kolumn_permission` resources for unified governance.

## 🛠 Supporting Files

All supporting files referenced by the examples are structured to demonstrate real-world patterns:

### File Discovery Support Files
> ⚠️ **Important**: These files are discovered by `universal-file-processing.kl` and demonstrate bidirectional file processing.

- **`sql/`** - SQL files with Kolumn resource interpolation
- **`python/`** - Python scripts with cross-provider references
- **`dags/`** - Airflow DAGs with governance integration
- **`k8s/`** - Kubernetes manifests with variable interpolation
- **`config/`** - JSON/YAML configurations with nested objects

### Variable Files (planned)
- **`.klvars`** - Environment-specific variable files
- **`terraform.tfvars`** - Terraform-compatible variable format

## 🚀 Getting Started

### 1. Choose Your Starting Point

**New to Kolumn?** Start with `kolumn-provider-only.kl` to understand the 5 core governance resources.

**Want basic integration?** Try `demo-step1-baseline.kl` to see how external providers integrate with governance.

**Have existing files?** Use `universal-file-processing.kl` to see how Kolumn integrates with your current SQL/Python/YAML workflow.

**Building a data platform?** Study `multi-provider-ecommerce.kl` for complete multi-provider architecture.

### 2. Running Examples

```bash
# Initialize Kolumn workspace  
kolumn init

# Start with governance-only example
kolumn validate examples/kolumn-provider-only.kl
kolumn plan examples/kolumn-provider-only.kl

# Try external provider integration
kolumn validate examples/demo-step1-baseline.kl
kolumn plan examples/demo-step1-baseline.kl

# Note: External providers need to be installed separately from their repositories
```

### 3. Understanding the Architecture

1. **Learn Core Resources**: Study `kolumn-provider-only.kl` for the 5 foundation resources
2. **See Integration**: Review how external providers consume governance in other examples
3. **Explore File Discovery**: Understand bidirectional file processing capabilities
4. **Build Your Own**: Use patterns to create your own governance and provider integration

### 4. External Provider Development

Follow the revolutionary SDK patterns:

```bash
# Simple 4-method approach (recommended)
kolumn-sdk init provider-mydb --type=simple

# Full Terraform compatibility (for migrations)
kolumn-sdk init provider-mydb --type=terraform  

# Hybrid approach (mix patterns)
kolumn-sdk init provider-mydb --type=hybrid
```

## 🎓 Learning Path

### Beginner (Start Here)
1. **Kolumn Provider Only** - Master the 5 core governance resources  
2. **Baseline Schema Demo** - See how external providers integrate with governance
3. **Provider SDK Basics** - Learn external provider development patterns

### Intermediate  
1. **Universal File Processing** - Master bidirectional file discovery
2. **Multi-Provider Coordination** - Understand cross-provider governance
3. **Classification Systems** - Design security and compliance frameworks

### Advanced
1. **Multi-Provider E-Commerce** - Build complete data platform architectures
2. **External Provider Development** - Create custom providers with Kolumn SDK
3. **Enterprise Governance** - Implement complex RBAC and security patterns

## 📊 Feature Matrix

| Feature | Kolumn Provider Only | Baseline Demo | File Processing | Multi-Provider |
|---------|---------------------|---------------|-----------------|----------------|
| **kolumn_data_object** | ✅ Complete | ✅ Basic | ✅ Advanced | ✅ Expert |
| **kolumn_classification** | ✅ Complete | ✅ Basic | ✅ Basic | ✅ Advanced |
| **kolumn_role** | ✅ Complete | ❌ None | ❌ None | ✅ Advanced |
| **kolumn_permission** | ✅ Complete | ❌ None | ❌ None | ✅ Advanced |
| **kolumn_file** | ✅ Complete | ✅ Basic | ✅ Expert | ❌ None |
| **External Providers** | ❌ None | ✅ Basic | ✅ Advanced | ✅ Expert |
| **Cross-Provider Governance** | 📚 Theory | ✅ Basic | ✅ Advanced | ✅ Expert |

## 💡 Tips for Success

### Starting with Governance
- **Begin with `kolumn-provider-only.kl`** to understand the 5 core resources
- **Define classifications first** (PII, financial, public) before data objects
- **Use data objects** as single source of truth for schema consistency
- **Implement RBAC early** for proper access control

### File Discovery
- **Keep original files unchanged** - Kolumn reads unidirectionally 
- **Use bidirectional processing** to extract metadata and schemas FROM files
- **Reference Kolumn resources** in existing SQL/Python/YAML files with `${resource.name}`
- **Chain file discoveries** for complex configuration dependencies

### External Provider Integration
- **External providers are separate repositories** - not part of this codebase
- **Use Kolumn SDK** for 70% less code when developing providers
- **Choose your pattern**: Simple 4-method, full Terraform protocol, or hybrid
- **Integrate governance**: Reference `kolumn_data_object` and `kolumn_classification`

### Performance & Security
- **Analytics classification**: No encryption overhead for high-volume data
- **PII classification**: Automatic encryption across all providers
- **Provider-specific configs**: Optimize settings per technology (PostgreSQL vs Kafka)
- **Permission transformations**: Different masking per provider type

## 🔧 Provider Development

Interested in developing external providers? Kolumn's SDK makes it revolutionary:

- **Repository**: https://github.com/SchemaBounce/Kolumn-sdk  
- **Documentation**: See CLAUDE.md in this repository for comprehensive patterns
- **Quick Start**: `kolumn-sdk init provider-name --type=simple`
- **Migration**: Existing Terraform providers migrate in <4 hours

## 🤝 Contributing

Found an issue with an example or want to add a new governance pattern?

1. **Governance improvements**: Focus on the 5 core Kolumn resources
2. **File discovery patterns**: Add new file types or interpolation examples  
3. **Classification examples**: Show new security/compliance patterns
4. **External provider examples**: Demonstrate integration patterns

Submit PRs with clear documentation and test the governance patterns.

---

These examples showcase Kolumn's breakthrough: **Full Terraform compatibility + Universal data governance**. The first infrastructure-as-code tool to unify governance across the entire data stack while maintaining familiar development patterns.