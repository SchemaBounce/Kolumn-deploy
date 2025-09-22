# DNS Validation Example

This example demonstrates how Kolumn's DNS TXT record validation works for provider versions.

## Overview

Kolumn CLI now includes DNS TXT record validation to verify provider versions against a central registry. This helps ensure you're using valid, published versions of providers and can detect version compatibility issues early.

## DNS TXT Record Format

Provider versions are published as DNS TXT records using this format:

```
v1=version1:hash1,version2:hash2,version3:hash3
```

### Example DNS Records

For the `postgres` provider:
```
postgres.registry.kolumn.schemabounce.com TXT "v1=1.0.0:sha256abc123,1.0.1:sha256def456,1.1.0:sha256ghi789"
```

For external providers like `hashicorp/aws`:
```
hashicorp.aws.registry.kolumn.schemabounce.com TXT "v1=3.0.0:sha256xyz123,3.0.1:sha256uvw456"
```

## Usage Examples

### Standard Init with DNS Validation (Default)
```bash
kolumn init
```

This will:
1. Discover required providers
2. Download and install providers
3. Perform DNS validation to verify versions
4. Display validation results

### Skip DNS Validation
```bash
kolumn init --skip-dns-validation
```

Use this when:
- Working offline
- Using custom/development providers
- DNS registry is unavailable

### Example Output

```
🔄 Initializing Kolumn providers...

📦 Installing provider postgres...
✅ Installed postgres successfully

🔍 Performing DNS validation for provider versions...
✅ DNS validation successful postgres: 1.0.1 (hash: sha256defghi09...)

🔍 DNS Validation Results:
   DNS Validation Summary: 1 successful, 0 failed, 0 skipped

   Details:
   ✅ postgres: 1.0.1 (hash: sha256defghi09...)

✅ Kolumn workspace initialized successfully!
   Providers: postgres
```

### When DNS Validation Fails

```
🔍 DNS Validation Results:
   DNS Validation Summary: 0 successful, 1 failed, 0 skipped

   Details:
   ❌ postgres: DNS TXT lookup failed for postgres.registry.kolumn.schemabounce.com: no such host

💡 DNS validation warnings detected. This is normal if:
   • You're working offline
   • Using custom or development providers
   • DNS registry is temporarily unavailable

   Use --skip-dns-validation to disable this check.
```

## Configuration

### Environment Variables

You can configure DNS validation behavior via environment variables:

```bash
# Disable DNS validation globally
export KOLUMN_SKIP_DNS_VALIDATION=true

# Use custom DNS domain
export KOLUMN_DNS_DOMAIN="custom.registry.example.com"

# Set custom DNS timeout
export KOLUMN_DNS_TIMEOUT=30s
```

### Provider Configuration

DNS validation works with all provider source formats:

```hcl
# Simple provider name (uses default registry)
provider "postgres" {
  # ...
}

# Kolumn namespace (uses default registry)
provider "kolumn/postgres" {
  # ...
}

# External namespace (uses namespaced DNS records)
provider "hashicorp/aws" {
  # ...
}
```

## DNS Registry Architecture

### Domain Structure

- **Default providers**: `{provider}.registry.kolumn.schemabounce.com`
- **Namespaced providers**: `{namespace}.{provider}.registry.kolumn.schemabounce.com`

### TXT Record Format

```
v1=1.0.0:sha256abcdef1234567890,1.0.1:sha256defghi0987654321
```

- `v1=` - Version format identifier
- `version:hash` - Semantic version and SHA256 hash
- `,` - Separator for multiple versions

## Benefits

1. **Version Verification**: Ensures you're using published, valid versions
2. **Security**: Verifies provider integrity via SHA256 hashes
3. **Early Detection**: Catches version issues before expensive downloads
4. **Registry Integration**: Seamless integration with provider registry
5. **Graceful Degradation**: Works offline with warnings

## Best Practices

1. **Keep DNS validation enabled** for production environments
2. **Use --skip-dns-validation** only when necessary (offline, custom providers)
3. **Monitor DNS validation warnings** in CI/CD pipelines
4. **Update providers regularly** based on DNS registry information
5. **Document custom providers** when DNS validation is disabled

## Troubleshooting

### Common Issues

1. **DNS timeout errors**: Increase timeout or work offline
2. **Version not found**: Check if requested version is published
3. **Hash mismatch**: Provider binary may be corrupted
4. **No DNS records**: Provider may not be published yet

### Debug Mode

Enable verbose logging to debug DNS validation:

```bash
kolumn init --verbose
```

This shows detailed DNS query information and validation steps.