-- PostgreSQL-specific users table template
-- Enhanced with PostgreSQL-specific features: BIGSERIAL, JSONB, full-text search
-- Variables: {{.table_name}}, {{.enable_audit}}, {{.schema_name}}

CREATE TABLE {{.schema_name}}.{{.table_name}} (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),

    -- PostgreSQL-specific: JSONB for flexible user metadata
    profile_data JSONB DEFAULT '{}',
    preferences JSONB DEFAULT '{}',

    -- PostgreSQL-specific: Full-text search vector
    search_vector TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english',
            COALESCE(first_name, '') || ' ' ||
            COALESCE(last_name, '') || ' ' ||
            COALESCE(username, '') || ' ' ||
            COALESCE(email, '')
        )
    ) STORED,

    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP

    {{if .enable_audit}}
    ,
    -- Enhanced audit columns for PostgreSQL
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    version INTEGER DEFAULT 1,
    audit_log JSONB DEFAULT '[]'
    {{end}}
);

-- PostgreSQL-specific indexes
CREATE INDEX idx_{{.table_name}}_email ON {{.schema_name}}.{{.table_name}}(email);
CREATE INDEX idx_{{.table_name}}_username ON {{.schema_name}}.{{.table_name}}(username);
CREATE INDEX idx_{{.table_name}}_active ON {{.schema_name}}.{{.table_name}}(is_active);

-- PostgreSQL-specific: GIN indexes for JSONB
CREATE INDEX idx_{{.table_name}}_profile_data ON {{.schema_name}}.{{.table_name}} USING GIN (profile_data);
CREATE INDEX idx_{{.table_name}}_preferences ON {{.schema_name}}.{{.table_name}} USING GIN (preferences);

-- PostgreSQL-specific: Full-text search index
CREATE INDEX idx_{{.table_name}}_search ON {{.schema_name}}.{{.table_name}} USING GIN (search_vector);

{{if .enable_audit}}
-- PostgreSQL-specific audit trigger with JSONB logging
CREATE OR REPLACE FUNCTION update_{{.table_name}}_audit()
RETURNS TRIGGER AS $$
DECLARE
    audit_entry JSONB;
BEGIN
    -- Create audit entry
    audit_entry = jsonb_build_object(
        'timestamp', CURRENT_TIMESTAMP,
        'user', COALESCE(current_setting('app.current_user', true), 'system'),
        'operation', TG_OP,
        'old_values', CASE WHEN TG_OP != 'INSERT' THEN to_jsonb(OLD) ELSE NULL END,
        'new_values', CASE WHEN TG_OP != 'DELETE' THEN to_jsonb(NEW) ELSE NULL END
    );

    IF TG_OP = 'UPDATE' THEN
        NEW.updated_at = CURRENT_TIMESTAMP;
        NEW.version = OLD.version + 1;
        NEW.audit_log = COALESCE(OLD.audit_log, '[]'::jsonb) || audit_entry;
        RETURN NEW;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_{{.table_name}}_audit
    BEFORE INSERT OR UPDATE ON {{.schema_name}}.{{.table_name}}
    FOR EACH ROW
    EXECUTE FUNCTION update_{{.table_name}}_audit();
{{end}}

-- PostgreSQL-specific: Row Level Security setup
ALTER TABLE {{.schema_name}}.{{.table_name}} ENABLE ROW LEVEL SECURITY;

-- Example RLS policy (can be customized per use case)
CREATE POLICY {{.table_name}}_access_policy ON {{.schema_name}}.{{.table_name}}
    FOR ALL
    TO PUBLIC
    USING (true); -- Customize based on your security requirements