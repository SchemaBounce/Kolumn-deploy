# Composable Enterprise Architecture

**BEFORE**: Monolithic, hard-to-manage HCL resources  
**AFTER**: Small, focused, composable building blocks

## 🎯 Design Philosophy

### **Single Responsibility Principle**
Each resource does one thing well, making it easier to:
- **Understand**: Clear purpose and scope
- **Test**: Isolated functionality
- **Reuse**: Compose across different scenarios
- **Maintain**: Focused updates and changes

### **Composition over Configuration**
Build complex systems from simple, well-defined components:
- **Mix and Match**: Combine components as needed
- **Share Common Patterns**: Reuse across teams and projects
- **Gradual Adoption**: Start small, expand incrementally

## 🔄 Transformation Overview

### **Discovery Engine Decomposition**

#### **BEFORE: Monolithic Discovery**
```hcl
# ❌ TOO BIG - Single massive resource (3000+ lines)
create "kolumn_discovery_engine" "enterprise_discovery" {
  name = "Enterprise Data Discovery Engine v2.0"
  
  # PII detection configuration (500+ lines)
  ai_configuration { ... }
  pii_detection { ... }
  
  # Data quality monitoring (800+ lines) 
  quality_monitoring { ... }
  
  # Anomaly detection (400+ lines)
  anomaly_detection { ... }
  
  # Lineage tracking (600+ lines)
  lineage_tracking { ... }
  
  # Scheduling (300+ lines)
  scheduling { ... }
  
  # Performance optimization (400+ lines)
  performance_optimization { ... }
}
```

#### **AFTER: Composable Discovery**
```hcl
# ✅ FOCUSED - Specialized PII detection
create "kolumn_pii_detector" "enterprise_pii" {
  name = "Enterprise PII Detector"
  confidence_threshold = 0.92
  auto_classification = true
  
  detection_methods = [
    {
      name = "ml_transformer"
      model = "transformer-pii-v3.2"
      confidence_boost = 0.15
    },
    {
      name = "pattern_matching"
      patterns = ["email", "phone", "ssn"]
      confidence_boost = 0.10
    }
  ]
  
  custom_patterns = {
    employee_id = "^EMP[0-9]{6}$"
    customer_id = "^CUST[0-9]{8}$"
  }
}

# ✅ FOCUSED - Quality monitoring
create "kolumn_quality_monitor" "completeness_monitor" {
  name = "Data Completeness Monitor"
  quality_dimension = "completeness"
  
  rules = [
    {
      name = "null_value_check"
      threshold = 0.95
      action = "alert"
    }
  ]
  
  alerts = {
    threshold = 0.90
    notification_channels = ["data-quality-alerts"]
  }
}

# ✅ FOCUSED - Anomaly detection
create "kolumn_anomaly_detector" "statistical_anomalies" {
  name = "Statistical Anomaly Detector"
  detection_method = "isolation_forest"
  contamination_rate = 0.05
  
  monitor_metrics = ["row_count", "null_percentage"]
  
  severity_thresholds = {
    critical = 0.95
    high = 0.85
    medium = 0.70
  }
}

# ✅ ORCHESTRATION - Compose components together
create "kolumn_discovery_orchestrator" "enterprise_discovery" {
  name = "Enterprise Discovery Orchestrator"
  
  pii_detectors = [
    kolumn_pii_detector.enterprise_pii.name
  ]
  
  quality_monitors = [
    kolumn_quality_monitor.completeness_monitor.name
  ]
  
  anomaly_detectors = [
    kolumn_anomaly_detector.statistical_anomalies.name
  ]
  
  execution_strategy = "parallel_with_dependencies"
}
```

### **RBAC Policy Decomposition**

#### **BEFORE: Monolithic RBAC**
```hcl
# ❌ TOO BIG - Single massive policy (2000+ lines)
create "kolumn_rbac_policy" "lineage_aware_rbac" {
  name = "Lineage-Aware RBAC Policy"
  
  # Lineage-based policies (600+ lines)
  lineage_based_policies = [ ... ]
  
  # Dynamic permissions (500+ lines)
  dynamic_permissions = { ... }
  
  # Role hierarchy (400+ lines)
  role_hierarchy = { ... }
  
  # Audit configuration (500+ lines)
  audit_configuration = { ... }
}
```

#### **AFTER: Composable RBAC**
```hcl
# ✅ FOCUSED - Permission building blocks
create "kolumn_permission_rule" "basic_read" {
  name = "Basic Read Access"
  
  actions = {
    select = true
    insert = false
    update = false
    delete = false
  }
  
  audit_requirements = {
    log_access = true
    retention_days = 90
  }
}

# ✅ FOCUSED - Classification-specific permissions
create "kolumn_classification_permission" "pii_read_masked" {
  name = "PII Read with Masking"
  base_permission = kolumn_permission_rule.basic_read.name
  applies_to_classifications = [kolumn_classification.pii.name]
  
  transformations = {
    email = {
      method = "partial_mask"
      preserve_chars = 3
    }
    phone = {
      method = "partial_mask" 
      preserve_chars = 4
    }
  }
}

# ✅ FOCUSED - Provider-specific permissions
create "kolumn_provider_permission" "postgres_database_access" {
  name = "PostgreSQL Database Access"
  provider = "postgres"
  
  operations = ["SELECT", "INSERT", "UPDATE"]
  schema_access = ["public", "analytics"]
  
  limits = {
    max_connections = 10
    query_timeout = "30m"
  }
}

# ✅ FOCUSED - Role composition
create "kolumn_role_policy" "customer_service_policy" {
  name = "Customer Service Access Policy"
  
  permissions = [
    kolumn_classification_permission.pii_read_masked.name
  ]
  
  provider_permissions = [
    kolumn_provider_permission.postgres_database_access.name
  ]
  
  capabilities = {
    max_concurrent_queries = 5
    can_export_data = false
  }
}

# ✅ ORCHESTRATION - Compose RBAC system
create "kolumn_rbac_orchestrator" "enterprise_rbac" {
  name = "Enterprise RBAC Orchestrator"
  
  role_policies = [
    kolumn_role_policy.customer_service_policy.name
  ]
  
  global_settings = {
    conflict_resolution = "most_restrictive"
    cache_policy_decisions = true
  }
}
```

## 🎯 Key Benefits Achieved

### **1. Single Responsibility**
| Component | Purpose | Lines of Code |
|-----------|---------|---------------|
| `kolumn_pii_detector` | PII detection only | ~50 lines |
| `kolumn_quality_monitor` | Quality monitoring only | ~40 lines |
| `kolumn_anomaly_detector` | Anomaly detection only | ~35 lines |
| `kolumn_permission_rule` | Basic permission template | ~25 lines |
| `kolumn_classification_permission` | Classification-specific access | ~45 lines |

**vs. Original monolithic resources: 2000-3000+ lines each**

### **2. Reusability**
```hcl
# Reuse the same PII detector across environments
create "kolumn_pii_detector" "production_pii" {
  name = "Production PII Detector"
  confidence_threshold = 0.95  # Stricter for prod
  # ... same configuration pattern
}

create "kolumn_pii_detector" "development_pii" {
  name = "Development PII Detector"  
  confidence_threshold = 0.85  # More lenient for dev
  # ... same configuration pattern
}
```

### **3. Mix and Match**
```hcl
# Customer Service: Basic permissions + PII masking
create "kolumn_role_policy" "customer_service" {
  permissions = [
    kolumn_permission_rule.basic_read.name,
    kolumn_classification_permission.pii_read_masked.name
  ]
}

# Data Engineer: Full permissions + special access
create "kolumn_role_policy" "data_engineer" {
  permissions = [
    kolumn_permission_rule.basic_write.name,
    kolumn_permission_rule.admin_access.name,
    kolumn_classification_permission.pii_read_masked.name
  ]
}
```

### **4. Incremental Adoption**
```hcl
# Start simple
create "kolumn_pii_detector" "basic_pii" {
  name = "Basic PII Detection"
  confidence_threshold = 0.9
  detection_methods = [
    { name = "pattern_matching", patterns = ["email", "phone"] }
  ]
}

# Add ML later
create "kolumn_pii_detector" "advanced_pii" {
  name = "Advanced PII Detection"
  confidence_threshold = 0.92
  detection_methods = [
    { name = "pattern_matching", patterns = ["email", "phone"] },
    { name = "ml_transformer", model = "bert-pii-v2" }  # Added later
  ]
}
```

### **5. Team Collaboration**
```hcl
# Security team defines permission templates
create "kolumn_permission_rule" "security_approved_read" {
  name = "Security Approved Read Access"
  # Security team controls this
}

# Data team uses templates with their specific needs
create "kolumn_classification_permission" "analytics_pii_access" {
  name = "Analytics PII Access"
  base_permission = kolumn_permission_rule.security_approved_read.name
  # Data team adds their transformations
  transformations = { ... }
}
```

## 🏗️ Resource Architecture

### **Discovery Components**
```
┌─ kolumn_pii_detector
├─ kolumn_quality_monitor  
├─ kolumn_anomaly_detector
├─ kolumn_ml_model
├─ kolumn_discovery_schedule
├─ kolumn_lineage_tracker
├─ kolumn_lineage_rule
├─ kolumn_lineage_analyzer
└─ kolumn_discovery_orchestrator (composes all)
```

### **RBAC Components**
```
┌─ kolumn_permission_rule (templates)
├─ kolumn_classification_permission (PII/Financial/etc)
├─ kolumn_provider_permission (Postgres/Kafka/etc)
├─ kolumn_role_policy (compose permissions)
├─ kolumn_lineage_policy (data flow aware)
├─ kolumn_context_policy (time/freshness aware)
├─ kolumn_role_delegation (temporary elevation)
├─ kolumn_access_policy (enforcement rules)
└─ kolumn_rbac_orchestrator (composes all)
```

## 🚀 Migration Strategy

### **Phase 1: Use Orchestrators**
Keep using the monolithic resources through orchestrators:
```hcl
# Immediate compatibility - no breaking changes
create "kolumn_discovery_orchestrator" "current_system" {
  # Reference existing monolithic discovery_engine
  legacy_discovery_engine = "existing_discovery_engine"
}
```

### **Phase 2: Gradual Migration**
Replace one component at a time:
```hcl
create "kolumn_discovery_orchestrator" "hybrid_system" {
  # New focused components
  pii_detectors = [kolumn_pii_detector.new_pii.name]
  
  # Still using legacy for other parts
  legacy_quality_monitoring = "existing_quality_config"
  legacy_anomaly_detection = "existing_anomaly_config"
}
```

### **Phase 3: Full Composable**
All components are focused and composable:
```hcl
create "kolumn_discovery_orchestrator" "modern_system" {
  pii_detectors = [kolumn_pii_detector.enterprise_pii.name]
  quality_monitors = [kolumn_quality_monitor.completeness.name]
  anomaly_detectors = [kolumn_anomaly_detector.statistical.name]
  # Fully composable system
}
```

## 🎯 Best Practices

### **1. Start with Templates**
```hcl
# Create reusable templates first
create "kolumn_permission_rule" "company_read_template" {
  name = "Company Standard Read Access"
  # Company-wide standards
}

# Then specialize
create "kolumn_classification_permission" "customer_data_read" {
  base_permission = kolumn_permission_rule.company_read_template.name
  # Specific to customer data
}
```

### **2. Use Clear Naming**
```hcl
# ✅ GOOD - Clear purpose
create "kolumn_pii_detector" "financial_data_scanner" { ... }
create "kolumn_quality_monitor" "completeness_checker" { ... }

# ❌ BAD - Vague purpose  
create "kolumn_pii_detector" "detector1" { ... }
create "kolumn_quality_monitor" "monitor" { ... }
```

### **3. Compose Thoughtfully**
```hcl
# ✅ GOOD - Logical grouping
create "kolumn_discovery_orchestrator" "customer_data_discovery" {
  pii_detectors = [
    kolumn_pii_detector.customer_pii.name,
    kolumn_pii_detector.financial_pii.name
  ]
  # Related components grouped together
}

# ❌ BAD - Random grouping
create "kolumn_discovery_orchestrator" "mixed_discovery" {
  pii_detectors = [kolumn_pii_detector.customer_pii.name]
  quality_monitors = [kolumn_quality_monitor.system_metrics.name]
  # Unrelated components mixed together
}
```

### **4. Version Components**
```hcl
create "kolumn_ml_model" "pii_detection_v2" {
  name = "PII Detection Model v2.0"
  model_type = "transformer"
  # Version your components for controlled upgrades
}
```

## 🎉 Result: Clean, Maintainable Architecture

**From this**:
- 1 massive discovery resource (3000+ lines)
- 1 massive RBAC resource (2000+ lines)
- Hard to understand, test, and modify

**To this**:
- 18 focused, composable resources (25-75 lines each)
- 2 orchestrators to compose them
- Easy to understand, test, and extend
- Team-friendly collaboration
- Incremental adoption path

The composable architecture maintains all the power of the original monolithic resources while dramatically improving usability, maintainability, and team collaboration.