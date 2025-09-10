# Minimal Project Structure

This example demonstrates the **minimal** Kolumn project structure using a single configuration file.

## Project Structure

```
minimal-project/
├── main.kl          # Single configuration file
└── README.md        # This documentation
```

## Features Demonstrated

- **Single-file configuration**: All resources in one file
- **Basic provider setup**: PostgreSQL provider configuration
- **Simple resource creation**: Table with columns and an index
- **Resource references**: Index referencing the table resource

## Usage

Initialize and apply the minimal project:

```bash
# Navigate to the project directory
cd examples/project-structures/minimal-project

# Initialize the project (creates .kolumn/ directory and state)
kolumn init

# View the execution plan
kolumn plan

# Apply the configuration
kolumn apply
```

## When to Use

The minimal structure is ideal for:

- **Quick prototypes**: Testing ideas rapidly
- **Learning**: Understanding basic Kolumn concepts
- **Simple projects**: Single database, few resources
- **Demos**: Showcasing specific features

## Template Generation

Generate this structure using:

```bash
kolumn init --template minimal
```

## Key Characteristics

- **Single file**: Everything in `main.kl`
- **No variables**: Direct configuration values
- **No modules**: All resources defined inline
- **No environments**: Single configuration for all contexts
- **Minimal dependencies**: Only requires one provider

This structure follows the principle of **progressive complexity** - start simple and add structure as your project grows.