-- Default products table template
-- Variables: {{.table_name}}, {{.enable_versioning}}

CREATE TABLE {{.table_name}} (
    id BIGINT PRIMARY KEY,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    price DECIMAL(10,2),
    cost DECIMAL(10,2),
    weight DECIMAL(8,2),
    dimensions VARCHAR(100),

    -- Inventory tracking
    stock_quantity INTEGER DEFAULT 0,
    reserved_quantity INTEGER DEFAULT 0,
    reorder_level INTEGER DEFAULT 0,

    -- Status and flags
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    requires_shipping BOOLEAN DEFAULT true,

    -- Metadata
    metadata TEXT, -- JSON string for flexibility
    tags TEXT,     -- Comma-separated tags

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP

    {{if .enable_versioning}}
    ,
    -- Versioning columns
    version INTEGER DEFAULT 1,
    version_notes TEXT,
    previous_version_id BIGINT,
    is_current_version BOOLEAN DEFAULT true
    {{end}}
);

-- Basic indexes
CREATE INDEX idx_{{.table_name}}_sku ON {{.table_name}}(sku);
CREATE INDEX idx_{{.table_name}}_name ON {{.table_name}}(name);
CREATE INDEX idx_{{.table_name}}_category ON {{.table_name}}(category);
CREATE INDEX idx_{{.table_name}}_active ON {{.table_name}}(is_active);
CREATE INDEX idx_{{.table_name}}_featured ON {{.table_name}}(is_featured);

{{if .enable_versioning}}
-- Versioning indexes
CREATE INDEX idx_{{.table_name}}_version ON {{.table_name}}(version);
CREATE INDEX idx_{{.table_name}}_current ON {{.table_name}}(is_current_version);
CREATE INDEX idx_{{.table_name}}_previous ON {{.table_name}}(previous_version_id);

-- Versioning constraint: only one current version per product
CREATE UNIQUE INDEX idx_{{.table_name}}_current_unique
    ON {{.table_name}}(sku)
    WHERE is_current_version = true;
{{end}}

-- Constraints
ALTER TABLE {{.table_name}} ADD CONSTRAINT chk_{{.table_name}}_price_positive
    CHECK (price >= 0);

ALTER TABLE {{.table_name}} ADD CONSTRAINT chk_{{.table_name}}_cost_positive
    CHECK (cost >= 0);

ALTER TABLE {{.table_name}} ADD CONSTRAINT chk_{{.table_name}}_stock_non_negative
    CHECK (stock_quantity >= 0);

ALTER TABLE {{.table_name}} ADD CONSTRAINT chk_{{.table_name}}_reserved_non_negative
    CHECK (reserved_quantity >= 0);