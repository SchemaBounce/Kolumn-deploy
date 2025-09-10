# Kolumn Examples

This directory contains comprehensive examples for using Kolumn CLI.

## Quick Start

### Basic Project Templates
- [`project-structures/minimal-project/`](project-structures/minimal-project/) - Simple single-file project
- [`project-structures/standard-project/`](project-structures/standard-project/) - Multi-file organized project
- [`project-structures/data-platform-project/`](project-structures/data-platform-project/) - Data platform with governance
- [`project-structures/enterprise-project/`](project-structures/enterprise-project/) - Complete enterprise setup

### Configuration Examples
- [`backends/`](backends/) - Backend configuration examples (SchemaBounce, S3, etc.)
- [`config/`](config/) - API and application configuration files

### Demo Files
- [`demo-step1-baseline.kl`](demo-step1-baseline.kl) - Step 1: Basic table creation
- [`demo-step2-add-column.kl`](demo-step2-add-column.kl) - Step 2: Schema evolution
- [`demo-step3-add-pii.kl`](demo-step3-add-pii.kl) - Step 3: Adding PII columns
- [`demo-step4-complex-evolution.kl`](demo-step4-complex-evolution.kl) - Step 4: Complex changes

### Enterprise Examples
- [`enterprise/`](enterprise/) - Enterprise-grade configurations
  - [`governance-lineage-complete.kl`](enterprise/governance-lineage-complete.kl) - Complete governance setup
  - [`sso-rbac-complete.kl`](enterprise/sso-rbac-complete.kl) - SSO and RBAC configuration
  - [`hsm-encryption-advanced.kl`](enterprise/hsm-encryption-advanced.kl) - HSM encryption setup

### Multi-Provider Examples
- [`multi-provider-ecommerce.kl`](multi-provider-ecommerce.kl) - E-commerce platform spanning multiple providers
- [`universal-file-processing.kl`](universal-file-processing.kl) - File processing across providers

### File Processing Examples
- [`files/`](files/) - SQL, Python, and configuration files
- [`sql/`](sql/) - SQL file examples for discovery
- [`python/`](python/) - Python file examples for discovery

### Variable Configuration
- [`variables.klvars`](variables.klvars) - Development variables
- [`production.klvars`](production.klvars) - Production variables
- [`staging.klvars`](staging.klvars) - Staging variables
- [`variables-README.md`](variables-README.md) - Variables documentation

### Kubernetes and DAGs
- [`k8s/`](k8s/) - Kubernetes deployment examples
- [`dags/`](dags/) - Airflow DAG examples

### Documentation
- [`DEMO_INSTRUCTIONS.md`](DEMO_INSTRUCTIONS.md) - Step-by-step demo instructions
- [`FILE_DISCOVERY_README.md`](FILE_DISCOVERY_README.md) - File discovery system documentation
- [`AUTONOMOUS_COLUMN_PROPAGATION.md`](AUTONOMOUS_COLUMN_PROPAGATION.md) - Advanced column propagation

## Getting Started

1. **Choose a template** from [`project-structures/`](project-structures/)
2. **Copy the template** to your local machine
3. **Customize variables** using the `.klvars` files
4. **Run Kolumn commands**:
   ```bash
   kolumn init
   kolumn plan
   kolumn apply
   ```

## Browse Online

You can browse these examples online at: https://github.com/schemabounce/Kolumn-deploy/tree/main/examples

## Download

Download the complete examples archive:
```bash
curl -L https://github.com/schemabounce/Kolumn-deploy/archive/refs/heads/main.zip -o kolumn-examples.zip
unzip kolumn-examples.zip
cd Kolumn-deploy-main/examples
```
