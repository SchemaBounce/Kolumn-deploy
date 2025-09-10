# File Discovery Support Files

These directories contain **example files** that demonstrate Kolumn's **File Discovery System**. They are NOT standalone examples, but rather **supporting files** that are discovered and interpolated by the main examples.

## 📁 Directory Structure

```
examples/
├── universal-file-processing.kl    # ← Main example that discovers these files
├── sql/                           # SQL files with interpolation
│   └── user_summary.sql          # ← Discovered by universal-file-processing.kl
├── dags/                         # Python files for orchestration  
│   └── user_etl.py              # ← Discovered by universal-file-processing.kl
├── k8s/                          # Kubernetes YAML manifests
│   └── app-deployment.yaml      # ← Discovered by universal-file-processing.kl
└── config/                       # JSON configuration files
    ├── api-settings.json        # ← Discovered by universal-file-processing.kl
    ├── base.json                # ← Discovered by universal-file-processing.kl
    └── development.json         # ← Discovered by universal-file-processing.kl
```

## 🔗 How File Discovery Works

### 1. Main Example Discovers Files
The `/examples/universal-file-processing.kl` example contains `discover` blocks like this:

```hcl
discover "kolumn_file" "user_summary_view" {
  location = "./sql/user_summary.sql"    # Points to support file
  inputs = {
    schema_name = "public"
    user_columns = kolumn_data_object.users.columns
    source_table = postgres_table.users.full_name
  }
}
```

### 2. Support Files Have Interpolation Patterns
The support files contain `${input.*}` patterns that get replaced:

```sql
-- In sql/user_summary.sql
CREATE VIEW ${input.schema_name}.user_summary AS
SELECT * FROM ${input.source_table}
WHERE department IN ${input.user_columns}
```

### 3. Kolumn Interpolates and Creates Resources
Kolumn reads the files, interpolates the variables, and uses the result:

```hcl
create "postgres_view" "user_summary" {
  # Uses interpolated content from discovered SQL file
  definition = discover.user_summary_view.interpolated_content
}
```

## 🎯 Key Point: These Are NOT Standalone Examples

- ❌ **Don't run these files directly** - they won't work without the main example
- ❌ **Don't expect them to work alone** - they have `${input.*}` patterns that need interpolation
- ✅ **Use them with universal-file-processing.kl** - that's the main example
- ✅ **Study the interpolation patterns** - see how Kolumn bridges HCL and external files

## 🚀 To See File Discovery In Action

1. **Read the main example**: `/examples/universal-file-processing.kl`
2. **Run the main example**: `kolumn plan examples/universal-file-processing.kl`  
3. **See how support files are discovered**: The `discover` blocks read these files
4. **See interpolation results**: The `${input.*}` patterns get replaced with real values

## 💡 Why This Architecture?

This demonstrates Kolumn's **revolutionary capability** that no other infrastructure-as-code tool has:

- **Keep existing files in place** (SQL, Python, YAML, JSON stay where they are)
- **Add universal governance** through Kolumn data objects and classifications
- **Bridge multiple languages** with cross-language resource references
- **Maintain familiar workflows** while gaining infrastructure-as-code benefits

The result is a **seamless migration path** from file-based workflows to unified infrastructure management.