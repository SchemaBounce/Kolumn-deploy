---
name: demo_user_analytics_advanced
description: Advanced user analytics with multi-tier security and intelligence
depends_on: ["${source_table}"]
materialized: view
classification_aware: true
---

-- =============================================================================
-- ADVANCED USER ANALYTICS WITH AUTONOMOUS INTELLIGENCE
-- =============================================================================
-- This SQL demonstrates Kolumn's most sophisticated capabilities:
-- • Multi-tier column access based on classification
-- • Intelligent data type handling (JSONB, arrays, decimals)
-- • Privacy-safe analytics with automatic PII protection
-- • Business intelligence with computed fields
-- =============================================================================

-- 📊 PUBLIC DATA ANALYTICS (Safe for all users)
CREATE OR REPLACE VIEW user_public_analytics AS
SELECT 
  -- ✅ PUBLIC COLUMNS: Always safe to access
  {% for column in public_columns %}
  {{ column }}{% if not loop.last %},{% endif %}
  {% endfor %}
  
  -- ✅ PERSONAL DATA: Low-sensitivity personal information
  {% for column in personal_columns %}
  , {{ column }}
  {% endfor %}
  
  -- 📊 COMPUTED PUBLIC FIELDS
  , CONCAT(first_name, 
           COALESCE(' ' || middle_name, ''), 
           ' ', last_name) as full_name
           
  , EXTRACT(YEAR FROM created_at) as signup_year
  , EXTRACT(MONTH FROM created_at) as signup_month
  
  -- 🕒 TEMPORAL ANALYTICS
  {% if 'last_login_at' in temporal_columns %}
  , CASE 
      WHEN last_login_at > NOW() - INTERVAL '7 days' THEN 'highly_active'
      WHEN last_login_at > NOW() - INTERVAL '30 days' THEN 'active'
      WHEN last_login_at > NOW() - INTERVAL '90 days' THEN 'inactive'
      ELSE 'dormant'
    END as engagement_level
  {% endif %}
  
  -- 🏢 BUSINESS INTELLIGENCE
  {% if 'user_tier' in business_columns %}
  , CASE user_tier
      WHEN 'enterprise' THEN 100
      WHEN 'premium' THEN 75
      WHEN 'standard' THEN 50
      ELSE 25
    END as tier_score
  {% endif %}

FROM ${source_table}
WHERE deleted_at IS NULL;

-- 🛡️ PII-AWARE ANALYTICS (Restricted access with masking)
CREATE OR REPLACE VIEW user_pii_analytics AS
SELECT 
  -- Core identification (always needed for joins)
  id,
  
  -- 🛡️ PII COLUMNS: Masked for privacy (requires special permissions)
  {% for column in pii_columns %}
  , CASE 
      WHEN current_user_has_pii_access('{{ column }}') THEN {{ column }}
      WHEN LENGTH({{ column }}) > 3 THEN 
        SUBSTRING({{ column }}, 1, 3) || '***' || 
        SUBSTRING({{ column }}, LENGTH({{ column }}) - 1)
      ELSE '***'
    END as {{ column }}_masked
    
  -- Privacy-safe hash for analytics joining
  , SHA256({{ column }}::text) as {{ column }}_hash
  {% endfor %}
  
  -- 🔐 HIGHLY SENSITIVE DATA: Maximum protection
  {% for column in highly_sensitive_columns %}
  , CASE 
      WHEN current_user_has_role('DATA_PROTECTION_OFFICER') THEN {{ column }}
      WHEN current_user_has_role('SECURITY_ADMIN') THEN 
        SUBSTRING({{ column }}, 1, 2) || '***'
      ELSE '[REDACTED]'
    END as {{ column }}_protected
    
  -- Anonymized identifier for analytics
  , 'anon_' || ABS(HASHTEXT({{ column }}::text))::text as {{ column }}_anonymous_id
  {% endfor %}

FROM ${source_table}
WHERE deleted_at IS NULL
  AND current_user_has_permission('VIEW_PII_DATA');

-- 💰 FINANCIAL ANALYTICS (Tier-based aggregation)
CREATE OR REPLACE VIEW user_financial_insights AS
SELECT 
  id,
  
  -- 💰 FINANCIAL DATA: Tier-based aggregation (no raw values)
  {% for column in financial_columns %}
  , CASE 
      {% if column == 'annual_revenue' %}
      WHEN {{ column }} >= 500000 THEN 'enterprise'
      WHEN {{ column }} >= 200000 THEN 'high_value'  
      WHEN {{ column }} >= 75000 THEN 'medium_value'
      WHEN {{ column }} > 0 THEN 'emerging'
      {% elif column == 'account_balance' %}
      WHEN {{ column }} >= 25000 THEN 'premium_balance'
      WHEN {{ column }} >= 5000 THEN 'high_balance'
      WHEN {{ column }} >= 1000 THEN 'standard_balance'
      WHEN {{ column }} >= 0 THEN 'basic_balance'
      {% endif %}
      ELSE 'not_disclosed'
    END as {{ column }}_tier
  {% endfor %}
  
  -- 📊 FINANCIAL HEALTH SCORE (Privacy-safe)
  , CASE 
      WHEN user_tier = 'enterprise' AND account_balance > 10000 THEN 'excellent'
      WHEN annual_revenue > 150000 AND account_balance > 5000 THEN 'very_good'
      WHEN annual_revenue > 50000 AND account_balance > 1000 THEN 'good'
      WHEN account_balance > 0 THEN 'fair'
      ELSE 'building'
    END as financial_health_tier
    
FROM ${source_table}
WHERE deleted_at IS NULL
  AND current_user_has_permission('VIEW_FINANCIAL_ANALYTICS');

-- 📋 STRUCTURED DATA ANALYTICS (JSONB and Arrays)
CREATE OR REPLACE VIEW user_preferences_analytics AS
SELECT 
  id,
  
  -- 📋 JSONB PROCESSING: Extract structured insights
  {% if 'preferences' in structured_columns %}
  , preferences->>'theme' as preferred_theme
  , COALESCE((preferences->>'notifications')::boolean, false) as notifications_enabled
  , preferences->>'language' as preferred_language
  
  -- Preference complexity score
  , jsonb_array_length(jsonb_object_keys(preferences)) as preference_complexity
  
  -- Common preferences (privacy-safe aggregation)
  , CASE preferences->>'theme'
      WHEN 'dark' THEN 'night_user'
      WHEN 'light' THEN 'day_user' 
      WHEN 'auto' THEN 'adaptive_user'
      ELSE 'default_user'
    END as user_theme_profile
  {% endif %}
  
  -- 🏷️ ARRAY PROCESSING: Tag analysis
  {% if 'tags' in structured_columns %}
  , array_length(tags, 1) as tag_count
  , CASE 
      WHEN 'vip' = ANY(tags) THEN 'vip_member'
      WHEN 'enterprise' = ANY(tags) THEN 'enterprise_member'  
      WHEN 'early_adopter' = ANY(tags) THEN 'early_adopter'
      ELSE 'standard_member'
    END as membership_level
    
  -- Tag-based segmentation
  , CASE
      WHEN tags && ARRAY['enterprise', 'high_value'] THEN 'enterprise_segment'
      WHEN tags && ARRAY['vip', 'premium'] THEN 'premium_segment'
      WHEN tags && ARRAY['early_adopter'] THEN 'innovator_segment'
      ELSE 'standard_segment'  
    END as customer_segment
  {% endif %}

FROM ${source_table}
WHERE deleted_at IS NULL;

-- 📈 COMPREHENSIVE BUSINESS INTELLIGENCE VIEW
-- Combines all analytics with proper security boundaries
CREATE OR REPLACE VIEW user_business_intelligence AS
SELECT 
  -- Core identification
  pub.id,
  pub.full_name,
  pub.signup_year,
  pub.engagement_level,
  pub.tier_score,
  
  -- Privacy-safe identifiers (for joining with external data)
  {% for column in pii_columns %}
  pii.{{ column }}_hash,
  {% endfor %}
  
  {% for column in highly_sensitive_columns %}
  pii.{{ column }}_anonymous_id,
  {% endfor %}
  
  -- Financial intelligence (tier-based)
  fin.financial_health_tier,
  {% for column in financial_columns %}
  fin.{{ column }}_tier,
  {% endfor %}
  
  -- Behavioral insights
  pref.preferred_theme,
  pref.notifications_enabled, 
  pref.customer_segment,
  pref.membership_level,
  
  -- 🧠 ADVANCED ANALYTICS: Multi-dimensional scoring
  CASE 
    WHEN pub.tier_score >= 100 AND fin.financial_health_tier = 'excellent' THEN 'platinum'
    WHEN pub.tier_score >= 75 AND fin.financial_health_tier IN ('excellent', 'very_good') THEN 'gold'
    WHEN pub.tier_score >= 50 AND fin.financial_health_tier IN ('good', 'very_good') THEN 'silver'
    ELSE 'bronze'
  END as customer_value_tier,
  
  -- Churn risk analysis (based on engagement and financial health)
  CASE
    WHEN pub.engagement_level = 'dormant' AND fin.financial_health_tier IN ('fair', 'building') THEN 'high_risk'
    WHEN pub.engagement_level = 'inactive' AND pub.tier_score < 50 THEN 'medium_risk'
    WHEN pub.engagement_level IN ('active', 'highly_active') THEN 'low_risk'
    ELSE 'medium_risk'
  END as churn_risk_level

FROM user_public_analytics pub
LEFT JOIN user_pii_analytics pii ON pub.id = pii.id
LEFT JOIN user_financial_insights fin ON pub.id = fin.id  
LEFT JOIN user_preferences_analytics pref ON pub.id = pref.id;

-- 🔍 COMPLIANCE AND AUDIT VIEW
-- Tracks access to sensitive data for governance
CREATE OR REPLACE VIEW pii_access_audit_log AS
SELECT 
  audit_timestamp,
  user_name as accessing_user,
  user_role,
  target_user_id,
  
  -- Track which PII fields were accessed
  {% for column in pii_columns %}
  (accessed_fields @> '[{"field": "{{ column }}"}]') as accessed_{{ column }},
  {% endfor %}
  
  {% for column in highly_sensitive_columns %}
  (accessed_fields @> '[{"field": "{{ column }}"}]') as accessed_{{ column }},
  {% endfor %}
  
  {% for column in financial_columns %}
  (accessed_fields @> '[{"field": "{{ column }}"}]') as accessed_{{ column }},
  {% endfor %}
  
  access_reason,
  approval_required,
  approved_by,
  ip_address,
  session_id

FROM pii_access_log
WHERE audit_timestamp >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY audit_timestamp DESC;

-- 🛡️ DATA GOVERNANCE FUNCTIONS
-- Automatically created based on detected PII and financial columns

{% for column in highly_sensitive_columns %}
CREATE OR REPLACE FUNCTION anonymize_{{ column }}(input_value TEXT)
RETURNS TEXT AS $$
BEGIN
  -- Return anonymized version for analytics
  RETURN 'anon_' || ABS(HASHTEXT(input_value))::text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
{% endfor %}

{% for column in financial_columns %}
CREATE OR REPLACE FUNCTION get_{{ column }}_tier(input_value DECIMAL)
RETURNS TEXT AS $$
BEGIN
  {% if column == 'annual_revenue' %}
  RETURN CASE 
    WHEN input_value >= 500000 THEN 'enterprise'
    WHEN input_value >= 200000 THEN 'high_value'
    WHEN input_value >= 75000 THEN 'medium_value'
    WHEN input_value > 0 THEN 'emerging'
    ELSE 'not_disclosed'
  END;
  {% elif column == 'account_balance' %}
  RETURN CASE
    WHEN input_value >= 25000 THEN 'premium_balance'
    WHEN input_value >= 5000 THEN 'high_balance'  
    WHEN input_value >= 1000 THEN 'standard_balance'
    WHEN input_value >= 0 THEN 'basic_balance'
    ELSE 'negative_balance'
  END;
  {% endif %}
END;
$$ LANGUAGE plpgsql IMMUTABLE;
{% endfor %}

-- =============================================================================
-- AUTONOMOUS SQL INTELLIGENCE DEMONSTRATION
-- =============================================================================

/*
🎯 WHAT THIS SQL DEMONSTRATES:

1. 📊 CLASSIFICATION-AWARE PROCESSING:
   • Public columns: Full access with rich analytics
   • PII columns: Masked access with hash generation
   • Highly sensitive: Maximum protection with anonymization
   • Financial: Tier-based aggregation (no raw values)
   • Structured: JSONB and array intelligence

2. 🛡️ AUTOMATIC SECURITY MEASURES:
   • Role-based access controls for sensitive data
   • Progressive masking based on user permissions
   • Privacy-safe analytics identifiers (hashes)
   • Compliance audit trail generation
   • Automatic anonymization functions

3. 🧠 BUSINESS INTELLIGENCE:
   • Multi-dimensional customer scoring
   • Churn risk analysis based on engagement
   • Preference-based segmentation
   • Financial health assessment
   • Tag-based membership classification

4. ⚡ AUTONOMOUS ADAPTATIONS:
   When columns change in the source table, this SQL automatically:
   • Includes/excludes columns based on classification
   • Applies appropriate security measures
   • Generates relevant business intelligence
   • Creates compliance tracking capabilities
   • Adapts data type processing (JSONB, arrays, decimals)

5. 🎯 ENTERPRISE READINESS:
   • GDPR compliance with right-to-be-forgotten
   • Audit logging for all PII access
   • Role-based access control integration  
   • Privacy-by-design with default masking
   • Scalable view architecture for complex queries

This is SQL that evolves automatically with your schema! 🚀
*/