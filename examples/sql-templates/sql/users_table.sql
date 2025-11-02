-- Default users table template
-- Variables: {{.table_name}}, {{.enable_audit}}, {{.schema_name}}

CREATE TABLE {{.schema_name}}.{{.table_name}} (
    id BIGINT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    {{if .enable_audit}}
    ,
    -- Audit columns
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    version INTEGER DEFAULT 1
    {{end}}
);

-- Indexes
CREATE INDEX idx_{{.table_name}}_email ON {{.schema_name}}.{{.table_name}}(email);
CREATE INDEX idx_{{.table_name}}_username ON {{.schema_name}}.{{.table_name}}(username);
CREATE INDEX idx_{{.table_name}}_active ON {{.schema_name}}.{{.table_name}}(is_active);

{{if .enable_audit}}
-- Audit trigger (generic version)
CREATE OR REPLACE FUNCTION update_{{.table_name}}_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    NEW.version = OLD.version + 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_{{.table_name}}_update
    BEFORE UPDATE ON {{.schema_name}}.{{.table_name}}
    FOR EACH ROW
    EXECUTE FUNCTION update_{{.table_name}}_timestamp();
{{end}}