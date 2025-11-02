-- User summary view template
-- Variables: {{.source_table}}, {{.include_metrics}}

CREATE VIEW user_summary AS
SELECT
    u.id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    u.is_active,
    u.created_at,
    u.updated_at

    {{if .include_metrics}}
    ,
    -- Calculated metrics
    CASE
        WHEN u.updated_at > CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 'active'
        WHEN u.updated_at > CURRENT_TIMESTAMP - INTERVAL '90 days' THEN 'dormant'
        ELSE 'inactive'
    END as activity_status,

    EXTRACT(DAY FROM CURRENT_TIMESTAMP - u.created_at) as account_age_days,

    CASE
        WHEN u.created_at > CURRENT_TIMESTAMP - INTERVAL '7 days' THEN 'new'
        WHEN u.created_at > CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 'recent'
        ELSE 'established'
    END as user_segment
    {{end}}

FROM {{.source_table}} u
WHERE u.is_active = true

{{if .include_metrics}}
ORDER BY
    CASE activity_status
        WHEN 'active' THEN 1
        WHEN 'dormant' THEN 2
        WHEN 'inactive' THEN 3
    END,
    u.created_at DESC
{{else}}
ORDER BY u.created_at DESC
{{end}};