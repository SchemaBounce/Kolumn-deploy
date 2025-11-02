-- Snowflake-specific users table template
-- Enhanced with Snowflake-specific features: IDENTITY, VARIANT, clustering
-- Variables: {{.table_name}}, {{.enable_audit}}, {{.schema_name}}

CREATE TABLE {{.schema_name}}.{{.table_name}} (
    id NUMBER(38,0) IDENTITY PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),

    -- Snowflake-specific: VARIANT for semi-structured data
    profile_data VARIANT DEFAULT NULL,
    preferences VARIANT DEFAULT NULL,

    -- Snowflake-specific: Additional metadata columns
    user_segments ARRAY DEFAULT NULL,
    tags OBJECT DEFAULT NULL,

    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    updated_at TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()

    {{if .enable_audit}}
    ,
    -- Snowflake audit columns
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    version INTEGER DEFAULT 1,
    audit_history VARIANT DEFAULT NULL
    {{end}}
);

-- Snowflake-specific: Clustering key for performance
ALTER TABLE {{.schema_name}}.{{.table_name}}
    CLUSTER BY (is_active, created_at);

-- Snowflake-specific: Search optimization
ALTER TABLE {{.schema_name}}.{{.table_name}}
    ADD SEARCH OPTIMIZATION ON EQUALITY(email, username),
    SUBSTRING(first_name, last_name);

{{if .enable_audit}}
-- Snowflake-specific: Stream for change tracking
CREATE STREAM {{.table_name}}_changes ON TABLE {{.schema_name}}.{{.table_name}};

-- Snowflake-specific: Task for audit processing
CREATE OR REPLACE TASK process_{{.table_name}}_audit
    WAREHOUSE = 'COMPUTE_WH'
    SCHEDULE = '1 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('{{.table_name}}_changes')
AS
    INSERT INTO {{.schema_name}}.{{.table_name}}_audit_log
    SELECT
        METADATA$ACTION as action_type,
        METADATA$ISUPDATE as is_update,
        METADATA$ROW_ID as row_id,
        CURRENT_TIMESTAMP() as audit_timestamp,
        CURRENT_USER() as audit_user,
        *
    FROM {{.table_name}}_changes;

-- Create audit log table
CREATE TABLE {{.schema_name}}.{{.table_name}}_audit_log (
    action_type VARCHAR(10),
    is_update BOOLEAN,
    row_id VARCHAR(100),
    audit_timestamp TIMESTAMP_LTZ,
    audit_user VARCHAR(100),
    -- All original table columns for full audit trail
    id NUMBER(38,0),
    email VARCHAR(255),
    username VARCHAR(100),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    profile_data VARIANT,
    preferences VARIANT,
    user_segments ARRAY,
    tags OBJECT,
    is_active BOOLEAN,
    created_at TIMESTAMP_LTZ,
    updated_at TIMESTAMP_LTZ,
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    version INTEGER,
    audit_history VARIANT
);
{{end}}

-- Snowflake-specific: Dynamic data masking policies
CREATE OR REPLACE MASKING POLICY email_mask AS (val string) RETURNS string ->
    CASE
        WHEN CURRENT_ROLE() IN ('ADMIN', 'DATA_ENGINEER') THEN val
        ELSE REGEXP_REPLACE(val, '.+@', '*****@')
    END;

-- Apply masking policy
ALTER TABLE {{.schema_name}}.{{.table_name}}
    MODIFY COLUMN email SET MASKING POLICY email_mask;

-- Snowflake-specific: Row access policy
CREATE OR REPLACE ROW ACCESS POLICY {{.table_name}}_access_policy AS (is_active boolean) RETURNS boolean ->
    CASE
        WHEN CURRENT_ROLE() IN ('ADMIN') THEN true
        ELSE is_active = true
    END;

-- Apply row access policy
ALTER TABLE {{.schema_name}}.{{.table_name}}
    ADD ROW ACCESS POLICY {{.table_name}}_access_policy ON (is_active);