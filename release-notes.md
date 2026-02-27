# Kolumn 0.1.107

Infrastructure-as-code tool for the modern data stack with enterprise governance.

## 🚀 Installation

### Quick Install (Recommended)
```bash
curl -fsSL https://schemabounce.github.io/Kolumn-deploy/install.sh | bash
```

### Manual Download
Download the appropriate package for your platform:
- Linux AMD64: [kolumn-0.1.107-linux-amd64.tar.gz](https://github.com/schemabounce/Kolumn-deploy/releases/download/v0.1.107/kolumn-0.1.107-linux-amd64.tar.gz)
- Linux ARM64: [kolumn-0.1.107-linux-arm64.tar.gz](https://github.com/schemabounce/Kolumn-deploy/releases/download/v0.1.107/kolumn-0.1.107-linux-arm64.tar.gz)
- macOS AMD64: [kolumn-0.1.107-darwin-amd64.tar.gz](https://github.com/schemabounce/Kolumn-deploy/releases/download/v0.1.107/kolumn-0.1.107-darwin-amd64.tar.gz)
- macOS ARM64: [kolumn-0.1.107-darwin-arm64.tar.gz](https://github.com/schemabounce/Kolumn-deploy/releases/download/v0.1.107/kolumn-0.1.107-darwin-arm64.tar.gz)
- Windows AMD64: [kolumn-0.1.107-windows-amd64.zip](https://github.com/schemabounce/Kolumn-deploy/releases/download/v0.1.107/kolumn-0.1.107-windows-amd64.zip)
- Windows ARM64: [kolumn-0.1.107-windows-arm64.zip](https://github.com/schemabounce/Kolumn-deploy/releases/download/v0.1.107/kolumn-0.1.107-windows-arm64.zip)

## ✨ What's Included
- **kolumn**: Main CLI binary
- **kolumn-provider-kolumn**: Governance provider binary
- Multi-platform support (Linux, macOS, Windows)
- Both AMD64 and ARM64 architectures
- **📚 Complete examples directory** with project templates, demos, and documentation

## 🎯 Getting Started
```bash
# Verify installation
kolumn version

# Browse examples online or download them
curl -L https://github.com/schemabounce/Kolumn-deploy/archive/refs/heads/main.zip -o kolumn-examples.zip
unzip kolumn-examples.zip
cd Kolumn-deploy-main/examples

# Create a new project from template
cp -r project-structures/minimal-project/ my-project
cd my-project

# Initialize and apply
kolumn init
kolumn plan
kolumn apply
```

## 📚 Examples & Documentation
- **🌐 Browse Examples**: [https://github.com/schemabounce/Kolumn-deploy/tree/main/examples](https://github.com/schemabounce/Kolumn-deploy/tree/main/examples)
- **📁 Project Templates**: Ready-to-use project structures (minimal, standard, data-platform, enterprise)
- **🎯 Step-by-Step Demos**: Progressive examples showing Kolumn capabilities
- **🏢 Enterprise Examples**: Governance, RBAC, encryption, and compliance configurations
- **🔗 Multi-Provider**: Examples spanning databases, streaming, ETL, and orchestration
- **📋 Configuration**: Backend configs, variables, and deployment patterns

## 🔗 Links
- 📖 [Documentation](https://schemabounce.github.io/Kolumn-deploy)
- 📚 [Examples](https://github.com/schemabounce/Kolumn-deploy/tree/main/examples)
- 💬 [Support](https://github.com/schemabounce/Kolumn-deploy/issues)
