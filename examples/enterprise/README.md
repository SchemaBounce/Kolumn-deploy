# Kolumn Enterprise HCL Examples

This directory contains comprehensive examples demonstrating the transformation from CLI-based operations to declarative HCL resources in Kolumn Enterprise.

## 🎯 Architecture Transformation

**Before**: CLI commands for configuration and operations
**After**: Declarative HCL resources for infrastructure-as-code + focused CLI for operations

### Key Benefits
- **Infrastructure as Code**: Enterprise configurations version-controlled and reproducible
- **Type Safety**: HCL resources provide compile-time validation and IDE support
- **Elegant CLI**: Operational commands complement (don't duplicate) configuration
- **Enterprise Scale**: 22 new HCL resources covering identity, security, compliance, and intelligence

## 📁 Example Configurations

### 1. Complete SSO & RBAC Configuration
**File**: `sso-rbac-complete.kl`

Demonstrates the full enterprise identity and access management stack:

```hcl
# Instead of: kolumn sso configure --provider okta
create "kolumn_sso_provider" "corporate_okta" {
  name          = "Corporate Okta"
  provider_type = "okta"
  # ... full configuration
}

# Instead of: kolumn rbac create-role --name data_engineer
create "kolumn_role" "data_engineer" {
  name = "data_engineer"
  permissions = [kolumn_permission.data_engineer_access.name]
  # ... capability definitions
}
```

**Features Covered**:
- 🔐 SSO Provider with SCIM provisioning
- 🎭 RBAC with classification-based permissions
- 📊 Compliance frameworks (GDPR, PCI-DSS)
- 🤖 AI-powered PII detection
- 📋 Policy enforcement and audit reporting

### 2. Advanced HSM & Encryption
**File**: `hsm-encryption-advanced.kl`

Enterprise-grade key management and encryption:

```hcl
# Instead of: kolumn security hsm configure --provider aws
create "kolumn_hsm_provider" "aws_cloudhsm" {
  name = "AWS CloudHSM Production"
  provider_type = "aws_cloudhsm"
  # ... FIPS 140-2 Level 3 configuration
}

# Instead of: kolumn security encryption-policy create
create "kolumn_encryption_policy" "enterprise_encryption_v2" {
  name = "Enterprise Encryption Policy v2.0"
  # ... classification-based encryption rules
}
```

**Features Covered**:
- 🔐 Multi-cloud HSM integration (AWS CloudHSM, Azure Dedicated HSM)
- 🔄 Automated key rotation with canary testing
- 📦 Envelope encryption with performance optimization
- 🛡️ Zero-knowledge client-side encryption
- 📋 Compliance integration (FIPS 140-2, Common Criteria)

### 3. Data Governance & Lineage
**File**: `governance-lineage-complete.kl`

Complete data governance and lineage tracking:

```hcl
# Instead of: kolumn scan lineage --ai-powered
create "kolumn_discovery_engine" "enterprise_discovery_v2" {
  name = "Enterprise Data Discovery Engine v2.0"
  discovery_types = ["schema", "pii", "lineage", "quality"]
  # ... ML-powered discovery configuration
}

# Instead of: kolumn governance lineage configure
create "kolumn_data_lineage" "enterprise_lineage_v2" {
  name = "Enterprise Data Lineage System v2.0"
  # ... cross-provider lineage tracking
}
```

**Features Covered**:
- 🤖 AI-powered data discovery with ML models
- 🔗 Cross-provider lineage tracking
- 📊 Advanced data quality monitoring
- 📈 Graph-based impact analysis
- 🎯 Real-time lineage updates

## 🔄 CLI vs HCL Resource Mapping

### Identity Management
| CLI Command | HCL Resource |
|-------------|--------------|
| `kolumn sso configure` | `kolumn_sso_provider` |
| `kolumn rbac create-role` | `kolumn_role` |
| `kolumn rbac create-permission` | `kolumn_permission` |
| `kolumn identity create-service-account` | `kolumn_service_account` |

### Security & Encryption
| CLI Command | HCL Resource |
|-------------|--------------|
| `kolumn security hsm configure` | `kolumn_hsm_provider` |
| `kolumn security encryption-policy` | `kolumn_encryption_policy` |
| `kolumn security key-rotation` | `kolumn_key_rotation` |

### Discovery & Intelligence
| CLI Command | HCL Resource |
|-------------|--------------|
| `kolumn scan pii --ai-powered` | `kolumn_discovery_engine` |
| `kolumn governance lineage` | `kolumn_data_lineage` |

### Compliance & Governance
| CLI Command | HCL Resource |
|-------------|--------------|
| `kolumn compliance framework` | `kolumn_compliance_framework` |
| `kolumn governance policy` | `kolumn_policy_library` |
| `kolumn audit configure` | `kolumn_audit_reporter` |

## 🎯 What Remains as CLI Commands

**Operational Tasks** (not configuration):

```bash
# Security Operations
kolumn security ddl validate --impact-analysis migration.sql
kolumn security emergency enable --justification "Incident #123"
kolumn security scrub-secrets --ephemeral-mode

# Compliance Operations  
kolumn compliance validate --framework gdpr
kolumn compliance evidence collect --period quarterly
kolumn compliance gap-analysis --baseline soc2-2017 --target soc2-2023

# Discovery Operations
kolumn scan pii --confidence-threshold 0.9
kolumn scan lineage --cross-provider --export graphml
kolumn scan performance --alert-degradation
```

## 🚀 Getting Started

### 1. Define Your Enterprise Configuration

Start with the SSO and RBAC configuration:

```hcl
# Configure your identity provider
create "kolumn_sso_provider" "company_sso" {
  name = "Company SSO"
  provider_type = "okta"  # or "auth0", "azure_ad"
  
  configuration {
    issuer_url = "https://company.okta.com"
    client_id = var.sso_client_id
    client_secret = var.sso_client_secret
  }
  
  scim {
    enabled = true
    sync_groups = true
    sync_users = true
  }
}
```

### 2. Set Up Classification-Based Governance

Define your data classifications:

```hcl
create "kolumn_classification" "pii" {
  name = "PII"
  description = "Personally Identifiable Information"
  
  requirements = {
    encryption = true
    audit_access = true
    retention_years = 7
  }
  
  encryption_config = {
    postgres = {
      method = "column_encryption"
      algorithm = "AES-256-GCM"
    }
    kafka = {
      method = "field_level"
      algorithm = "AES-256-CTR"
    }
  }
}
```

### 3. Configure AI-Powered Discovery

Enable intelligent data discovery:

```hcl
create "kolumn_discovery_engine" "company_discovery" {
  name = "Company Data Discovery"
  discovery_types = ["schema", "pii", "lineage", "quality"]
  
  ai_configuration {
    enabled = true
    confidence_threshold = 0.9
  }
  
  pii_detection {
    enabled = true
    auto_classification = true
  }
}
```

### 4. Deploy and Operate

```bash
# Initialize and plan
kolumn init
kolumn plan

# Apply enterprise configuration  
kolumn apply

# Use operational commands
kolumn scan pii --ai-powered
kolumn compliance validate --framework gdpr
kolumn security ddl validate important_migration.sql
```

## 🔧 Advanced Patterns

### Cross-Provider Data Objects

Define data objects once, implement across providers:

```hcl
create "kolumn_data_object" "customer" {
  name = "customer"
  
  column "email" {
    type = "VARCHAR(255)"
    classifications = [kolumn_classification.pii.name]
  }
  
  # Provider-specific configurations
  config = {
    postgres = {
      schema = "public"
      table_name = "customers"
    }
    kafka = {
      topic_name = "customer-events"
      partitions = 6
    }
    s3 = {
      bucket_name = "customer-data-lake"
      encryption = "AES256"
    }
  }
}
```

### Compliance-Driven Policies

Automate compliance through policies:

```hcl
create "kolumn_policy_library" "gdpr_policies" {
  name = "GDPR Compliance Policies"
  
  data_access_policies = [
    {
      name = "pii_access_logging"
      rule = "LOG ACCESS WHERE classification = 'PII'"
      retention_days = 2555  # 7 years
    }
  ]
  
  time_based_policies = [
    {
      name = "gdpr_retention"
      rule = "DELETE WHERE age > 7_years AND classification = 'PII'"
      automated = true
    }
  ]
}
```

### Lineage-Aware RBAC

Permissions that understand data flow:

```hcl
create "kolumn_rbac_policy" "lineage_aware_rbac" {
  name = "Lineage-Aware RBAC"
  
  lineage_based_policies = [
    {
      name = "upstream_sensitivity_propagation"
      rule = "IF upstream_classification = 'PII' THEN require_role = 'data_steward'"
      propagation_depth = 5
    }
  ]
}
```

## 📚 Related Documentation

- [Enterprise Architecture Guide](../docs/enterprise/)
- [Security Best Practices](../docs/security/)
- [Compliance Frameworks](../docs/compliance/)
- [CLI Reference](../docs/cli/)

## 🎯 Migration Guide

### From CLI to HCL Resources

1. **Audit Current CLI Usage**: Run `kolumn --help` to see current commands
2. **Map to HCL Resources**: Use the mapping table above
3. **Create Configuration Files**: Start with the examples in this directory
4. **Test in Development**: Use `kolumn plan` to validate configuration
5. **Migrate Gradually**: Move one system at a time (SSO → RBAC → Discovery)

### Breaking Changes

- ✅ **No Breaking Changes**: Existing CLI commands continue to work
- ✅ **Gradual Migration**: Can use CLI and HCL resources together
- ✅ **Backward Compatibility**: Configuration files are additive

## 🚀 Next Steps

1. **Start with SSO**: Configure `kolumn_sso_provider` first
2. **Add Classifications**: Define your data classifications  
3. **Configure Discovery**: Enable AI-powered data discovery
4. **Implement Compliance**: Add compliance frameworks
5. **Optimize Operations**: Use operational CLI commands for day-to-day tasks

The enterprise examples demonstrate how Kolumn's architectural transformation enables enterprise-scale data governance while maintaining operational simplicity.