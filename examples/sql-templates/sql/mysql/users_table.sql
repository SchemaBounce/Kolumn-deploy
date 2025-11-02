-- MySQL-specific users table template
-- Enhanced with MySQL-specific features: AUTO_INCREMENT, JSON columns, full-text search
-- Variables: {{.table_name}}, {{.enable_audit}}, {{.schema_name}}

CREATE TABLE {{.schema_name}}.{{.table_name}} (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),

    -- MySQL-specific: JSON columns for user metadata
    profile_data JSON DEFAULT NULL,
    preferences JSON DEFAULT NULL,

    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

    {{if .enable_audit}}
    ,
    -- MySQL audit columns
    created_by VARCHAR(100),
    updated_by VARCHAR(100),
    version INTEGER DEFAULT 1
    {{end}}
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- MySQL-specific indexes
CREATE INDEX idx_{{.table_name}}_email ON {{.schema_name}}.{{.table_name}}(email);
CREATE INDEX idx_{{.table_name}}_username ON {{.schema_name}}.{{.table_name}}(username);
CREATE INDEX idx_{{.table_name}}_active ON {{.schema_name}}.{{.table_name}}(is_active);

-- MySQL-specific: Full-text search index
CREATE FULLTEXT INDEX idx_{{.table_name}}_fulltext
    ON {{.schema_name}}.{{.table_name}}(first_name, last_name, username, email);

-- MySQL-specific: JSON functional indexes (MySQL 8.0+)
CREATE INDEX idx_{{.table_name}}_profile_email
    ON {{.schema_name}}.{{.table_name}}((CAST(profile_data->>'$.email_verified' AS UNSIGNED)));

{{if .enable_audit}}
-- MySQL-specific audit trigger
DELIMITER $$

CREATE TRIGGER trg_{{.table_name}}_update
    BEFORE UPDATE ON {{.schema_name}}.{{.table_name}}
    FOR EACH ROW
BEGIN
    SET NEW.version = OLD.version + 1;
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END$$

DELIMITER ;
{{end}}

-- MySQL-specific: Add constraints
ALTER TABLE {{.schema_name}}.{{.table_name}}
    ADD CONSTRAINT chk_{{.table_name}}_email_format
    CHECK (email REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

ALTER TABLE {{.schema_name}}.{{.table_name}}
    ADD CONSTRAINT chk_{{.table_name}}_username_length
    CHECK (CHAR_LENGTH(username) >= 3);