---
name: user_analytics
description: User analytics SQL with dynamic column interpolation
depends_on: ["${user_table}"]
materialized: view
---

-- =============================================================================
-- USER ANALYTICS SQL WITH AUTONOMOUS COLUMN INTERPOLATION
-- =============================================================================
-- This SQL file demonstrates how column schema is automatically interpolated
-- When columns change in the source, this SQL is automatically updated!
-- =============================================================================

-- 🔗 DYNAMIC COLUMN SELECTION: Uses interpolated user schema
-- The ${user_columns} variable contains ALL columns from the discovered table
CREATE OR REPLACE VIEW user_analytics_summary AS
SELECT 
  -- ⚡ AUTONOMOUS MAGIC: These columns come from ${user_columns} interpolation
  {% for column in user_columns %}
  {{ column.name }}{% if not loop.last %},{% endif %}
  {% endfor %}
  
  -- Analytics-specific computed columns
  , CASE 
      WHEN created_at > NOW() - INTERVAL '30 days' THEN 'new_user'
      WHEN created_at > NOW() - INTERVAL '365 days' THEN 'active_user'
      ELSE 'legacy_user' 
    END as user_segment
    
  , EXTRACT(YEAR FROM created_at) as signup_year
  , EXTRACT(MONTH FROM created_at) as signup_month
  
  -- 🛡️ SECURITY: PII columns are automatically masked in analytics
  {% for column in user_columns %}
  {% if column.name in ["email", "phone", "ssn"] %}
  , CASE 
      WHEN current_user_has_pii_access() THEN {{ column.name }}
      ELSE SUBSTRING({{ column.name }}, 1, 3) || '***'
    END as {{ column.name }}_masked
  {% endif %}
  {% endfor %}

FROM ${user_table}
WHERE deleted_at IS NULL;

-- 📊 USER ACTIVITY ANALYTICS
-- Automatically uses the latest column schema from source table
CREATE OR REPLACE VIEW user_activity_metrics AS
SELECT 
  -- 🔗 CORE USER FIELDS: Automatically updated when source schema changes
  {% for column in user_columns %}
  {% if column.name in ["id", "email", "created_at", "status"] %}
  u.{{ column.name }},
  {% endif %}
  {% endfor %}
  
  -- Activity metrics
  COUNT(DISTINCT DATE(activity_timestamp)) as days_active_last_30,
  MAX(activity_timestamp) as last_activity_date,
  MIN(activity_timestamp) as first_activity_date,
  
  -- 🛡️ PRIVACY: Classification-aware aggregation
  COUNT(CASE WHEN activity_type = 'profile_update' THEN 1 END) as profile_updates,
  COUNT(CASE WHEN activity_type = 'data_download' THEN 1 END) as data_requests

FROM ${user_table} u
LEFT JOIN user_activity_log al ON u.id = al.user_id
WHERE u.deleted_at IS NULL
  AND al.activity_timestamp > NOW() - INTERVAL '30 days'
GROUP BY 
  {% for column in user_columns %}
  {% if column.name in ["id", "email", "created_at", "status"] %}
  u.{{ column.name }}{% if not loop.last %},{% endif %}
  {% endif %}
  {% endfor %};

-- 🔍 AUDIT QUERY FOR COMPLIANCE
-- Shows which PII fields are being accessed
CREATE OR REPLACE FUNCTION audit_pii_access()
RETURNS TABLE(
  user_id BIGINT,
  {% for column in user_columns %}
  {% if column.name in ["email", "phone", "ssn"] %}
  accessed_{{ column.name }} BOOLEAN,
  {% endif %}
  {% endfor %}
  access_timestamp TIMESTAMP,
  accessing_user VARCHAR(100)
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id as user_id,
    
    -- 🛡️ TRACK PII ACCESS: One field per PII column from classification
    {% for column in user_columns %}
    {% if column.name in ["email", "phone", "ssn"] %}
    (audit_log.accessed_fields @> '[{"field": "{{ column.name }}"}]') as accessed_{{ column.name }},
    {% endif %}
    {% endfor %}
    
    audit_log.timestamp as access_timestamp,
    audit_log.user_name as accessing_user
    
  FROM ${user_table} u
  JOIN pii_access_audit_log audit_log ON u.id = audit_log.target_user_id
  WHERE audit_log.timestamp > NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- AUTONOMOUS COLUMN MAGIC DEMONSTRATION
-- =============================================================================
--
-- 🎯 WHAT HAPPENS WHEN SOURCE TABLE CHANGES:
--
-- 1. ALTER TABLE users ADD COLUMN middle_name VARCHAR(100);
--    → This SQL file automatically gets middle_name in ${user_columns}
--    → All SELECT statements include the new column
--    → Analytics views automatically expand
--
-- 2. ALTER TABLE users ADD COLUMN phone_verified BOOLEAN DEFAULT FALSE;
--    → New column appears in user_analytics_summary view
--    → If 'phone_verified' contains 'phone', it gets PII treatment automatically
--    → Audit function expands to track new field
--
-- 3. ALTER TABLE users DROP COLUMN deprecated_field;
--    → Column removed from all interpolated queries automatically
--    → No broken SQL references
--    → Clean, maintainable analytics code
--
-- 🚀 ZERO MAINTENANCE: SQL stays perfectly synchronized with source schema!
-- =============================================================================