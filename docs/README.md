# Kolumn Documentation API

This directory provides versioned JSON documentation manifests for the Kolumn CLI.

## 📡 API Endpoints

### Latest Documentation
- **URL**: `https://schemabounce.github.io/Kolumn-deploy/docs/latest/docs.json`
- **Description**: Always points to the most recent version
- **Cache**: 5 minutes
- **Usage**: Ideal for applications that need the latest CLI documentation

### Versioned Documentation  
- **URL Pattern**: `https://schemabounce.github.io/Kolumn-deploy/docs/v{VERSION}/docs.json`
- **Example**: `https://schemabounce.github.io/Kolumn-deploy/docs/v1.0.0/docs.json`
- **Cache**: 1 hour
- **Usage**: Pin to specific versions for stability

## 📋 Documentation Format

Each JSON manifest contains:

```json
{
  "version": "1.0.0",
  "generated_at": "2025-01-10T10:30:00Z",
  "kolumn_version": "1.0.0",
  "root_command": { /* Root command metadata */ },
  "commands": { /* All CLI commands with full metadata */ },
  "categories": { /* Commands organized by category */ },
  "statistics": { /* Coverage and usage statistics */ }
}
```

## 🚀 Usage Examples

### JavaScript/Node.js
```javascript
// Fetch latest documentation
const response = await fetch('https://schemabounce.github.io/Kolumn-deploy/docs/latest/docs.json');
const docs = await response.json();
console.log(`Kolumn v${docs.kolumn_version} has ${docs.statistics.total_commands} commands`);
```

### cURL/Bash
```bash
# Get latest version info
curl -s https://schemabounce.github.io/Kolumn-deploy/docs/latest/docs.json | jq '.kolumn_version'

# Get all command names
curl -s https://schemabounce.github.io/Kolumn-deploy/docs/latest/docs.json | jq '.commands | keys'
```

### Python
```python
import requests

# Fetch documentation
response = requests.get('https://schemabounce.github.io/Kolumn-deploy/docs/latest/docs.json')
docs = response.json()

# Print command statistics
stats = docs['statistics'] 
print(f"Total commands: {stats['total_commands']}")
print(f"Documentation coverage: {stats['coverage_analysis']['documentation_coverage']:.1f}%")
```

## 📊 Metadata Endpoints

Each version also includes metadata:

- `https://schemabounce.github.io/Kolumn-deploy/docs/latest/metadata.json`
- `https://schemabounce.github.io/Kolumn-deploy/docs/v{VERSION}/metadata.json`

Metadata format:
```json
{
  "version": "1.0.0",
  "deployed_at": "2025-01-10T10:30:00Z", 
  "docs_url": "https://schemabounce.github.io/Kolumn-deploy/docs/v1.0.0/docs.json",
  "latest_url": "https://schemabounce.github.io/Kolumn-deploy/docs/latest/docs.json"
}
```

## 🔄 CORS Support

All endpoints include proper CORS headers for browser-based applications:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, OPTIONS
Access-Control-Allow-Headers: Content-Type, Accept
Content-Type: application/json; charset=UTF-8
```

## ⚡ Caching Strategy

- **Latest docs**: 5 minutes cache for frequent updates
- **Versioned docs**: 1 hour cache for stability  
- **Metadata**: 5 minutes cache

This ensures applications get updates quickly while maintaining performance.