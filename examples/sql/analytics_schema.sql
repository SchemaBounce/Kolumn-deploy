---
-- Analytics Schema with Output Extraction Demo
-- This file demonstrates bidirectional processing where Kolumn:
-- 1. Interpolates inputs INTO the SQL file
-- 2. Extracts structured outputs FROM the processed SQL
---

-- Create schema with interpolated name
CREATE SCHEMA IF NOT EXISTS ${input.schema_name};

-- Create customer table with dynamic columns
CREATE TABLE ${input.schema_name}.customers (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    department VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create orders table that references customers
CREATE TABLE ${input.schema_name}.orders (
    id BIGSERIAL PRIMARY KEY,
    customer_id BIGINT REFERENCES ${input.schema_name}.customers(id),
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    order_date TIMESTAMP DEFAULT NOW()
);

-- Create performance-optimized indexes
CREATE INDEX idx_customers_email ON ${input.schema_name}.customers(email);
CREATE INDEX idx_customers_dept ON ${input.schema_name}.customers(department);
CREATE INDEX idx_orders_customer ON ${input.schema_name}.orders(customer_id);
CREATE INDEX idx_orders_date ON ${input.schema_name}.orders(order_date);

-- Create analytical views
CREATE VIEW ${input.schema_name}.customer_summary AS
SELECT 
    c.id,
    c.name,
    c.email,
    c.department,
    COUNT(o.id) as total_orders,
    SUM(o.amount) as total_spent,
    AVG(o.amount) as avg_order_value
FROM ${input.schema_name}.customers c
LEFT JOIN ${input.schema_name}.orders o ON c.id = o.customer_id
GROUP BY c.id, c.name, c.email, c.department;

-- Create business intelligence functions
CREATE OR REPLACE FUNCTION ${input.schema_name}.get_customer_stats(customer_id BIGINT) 
RETURNS TABLE(total_orders INT, total_spent DECIMAL, avg_order DECIMAL) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(o.id)::INT,
        COALESCE(SUM(o.amount), 0),
        COALESCE(AVG(o.amount), 0)
    FROM ${input.schema_name}.orders o
    WHERE o.customer_id = get_customer_stats.customer_id;
END;
$$ LANGUAGE plpgsql;

-- Create data quality function
CREATE OR REPLACE FUNCTION ${input.schema_name}.validate_email(email_addr TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN email_addr ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$$ LANGUAGE plpgsql;