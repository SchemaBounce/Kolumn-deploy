---
name: user_summary
description: Summary view of user data with order statistics
depends_on: [users, orders]
materialized: view
---

-- =============================================================================
-- KOLUMN FILE DISCOVERY EXAMPLE: SQL with Interpolation
-- =============================================================================
-- 
-- PURPOSE: Demonstrates how Kolumn's File Discovery System reads external SQL
-- files and interpolates them with Kolumn data objects and variables.
--
-- USED BY: /examples/universal-file-processing.kl
--
-- HOW IT WORKS:
-- 1. The universal-file-processing.kl example discovers this file:
--
--    discover "kolumn_file" "user_summary_view" {
--      location = "./sql/user_summary.sql"  # <-- This file!
--      inputs = {
--        schema_name = "public"
--        user_columns = kolumn_data_object.users.columns
--        source_table = postgres_table.users.full_name
--        # ... more inputs
--      }
--    }
--
-- 2. Kolumn interpolates ${input.*} patterns with actual values
-- 3. Result is used to create a postgres_view resource
--
-- INTERPOLATION EXAMPLES:
-- - ${input.schema_name} -> "public" 
-- - ${input.source_table} -> "public.users"
-- - ${input.user_columns} -> ["id", "email", "name", ...]
-- =============================================================================

CREATE OR REPLACE VIEW ${input.schema_name}.${input.table_prefix}user_summary AS
SELECT 
    u.id as user_id,
    u.email,
    u.name,
    u.created_at,
    COUNT(o.id) as total_orders,
    COALESCE(SUM(o.amount), 0) as total_spent,
    AVG(o.amount) as avg_order_amount,
    MAX(o.created_at) as last_order_date
FROM ${input.schema_name}.users u
LEFT JOIN ${input.schema_name}.orders o ON u.id = o.user_id
GROUP BY u.id, u.email, u.name, u.created_at;

-- Grant permissions based on user columns: ${input.user_columns}
-- Total columns discovered: ${discover.users.column_count}
-- Classification handling: automatic PII masking for ${input.user_columns}