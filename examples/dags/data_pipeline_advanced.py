# Advanced Data Pipeline with Output Extraction Demo
# This Python file demonstrates bidirectional processing where Kolumn:
# 1. Interpolates inputs INTO the Python file (table names, configurations)
# 2. Extracts structured outputs FROM the processed Python (DAG config, functions, dependencies)

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres_operator import PostgresOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
import pandas as pd

# DAG Configuration (extractable by Kolumn)
DAG_ID = "${input.dag_name}"
SCHEDULE_INTERVAL = "${input.schedule}"
DEFAULT_ARGS = {
    'owner': 'data-team',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': ${input.max_retries},
    'retry_delay': timedelta(minutes=5)
}

# Database configuration from Kolumn resources
SOURCE_TABLE = "${input.source_table}"
TARGET_SCHEMA = "${input.target_schema}"
CONNECTION_ID = "${input.postgres_connection}"

# Create the DAG
dag = DAG(
    DAG_ID,
    default_args=DEFAULT_ARGS,
    description='Advanced analytics data pipeline',
    schedule_interval=SCHEDULE_INTERVAL,
    catchup=False,
    tags=['analytics', 'etl', 'kolumn-managed']
)

def extract_customer_data(**context):
    """Extract customer data from source system"""
    hook = PostgresHook(postgres_conn_id=CONNECTION_ID)
    
    # Dynamic SQL using Kolumn interpolated table name
    sql = f"""
    SELECT 
        id,
        email,
        name,
        department,
        created_at
    FROM {SOURCE_TABLE}
    WHERE created_at >= %s
    """
    
    # Get data from last 24 hours
    cutoff_date = context['ds']
    df = hook.get_pandas_df(sql, parameters=[cutoff_date])
    
    return df.to_json()

def transform_customer_data(**context):
    """Transform customer data with business rules"""
    import json
    
    # Get data from previous task
    raw_data = context['ti'].xcom_pull(task_ids='extract_customers')
    df = pd.read_json(raw_data)
    
    # Apply business transformations
    df['email_domain'] = df['email'].str.split('@').str[1]
    df['name_length'] = df['name'].str.len()
    df['is_corporate'] = df['email_domain'].isin(['company.com', 'enterprise.org'])
    
    # Data quality checks
    df = df[df['email'].notna() & (df['email'] != '')]
    df = df[df['name'].str.len() >= 2]
    
    return df.to_json()

def load_customer_analytics(**context):
    """Load transformed data into analytics schema"""
    import json
    
    hook = PostgresHook(postgres_conn_id=CONNECTION_ID)
    transformed_data = context['ti'].xcom_pull(task_ids='transform_customers')
    df = pd.read_json(transformed_data)
    
    # Load data using Kolumn interpolated schema
    df.to_sql(
        name='customer_analytics',
        con=hook.get_sqlalchemy_engine(),
        schema=TARGET_SCHEMA,
        if_exists='append',
        index=False
    )

def data_quality_check(**context):
    """Perform data quality validations"""
    hook = PostgresHook(postgres_conn_id=CONNECTION_ID)
    
    # Check row counts
    count_sql = f"SELECT COUNT(*) FROM {TARGET_SCHEMA}.customer_analytics"
    row_count = hook.get_first(count_sql)[0]
    
    if row_count == 0:
        raise ValueError("No data loaded - pipeline failure!")
    
    # Check data freshness
    freshness_sql = f"""
    SELECT MAX(created_at) 
    FROM {TARGET_SCHEMA}.customer_analytics 
    WHERE created_at >= CURRENT_DATE - INTERVAL '1 day'
    """
    max_date = hook.get_first(freshness_sql)[0]
    
    if not max_date:
        raise ValueError("No fresh data found - check source systems!")
    
    print(f"Data quality check passed: {row_count} rows, latest: {max_date}")

# Define task dependencies
extract_task = PythonOperator(
    task_id='extract_customers',
    python_callable=extract_customer_data,
    dag=dag
)

transform_task = PythonOperator(
    task_id='transform_customers', 
    python_callable=transform_customer_data,
    dag=dag
)

load_task = PythonOperator(
    task_id='load_analytics',
    python_callable=load_customer_analytics,
    dag=dag
)

quality_task = PythonOperator(
    task_id='data_quality_check',
    python_callable=data_quality_check,
    dag=dag
)

# Create schema if it doesn't exist
create_schema_task = PostgresOperator(
    task_id='create_target_schema',
    postgres_conn_id=CONNECTION_ID,
    sql=f"CREATE SCHEMA IF NOT EXISTS {TARGET_SCHEMA}",
    dag=dag
)

# Pipeline flow
create_schema_task >> extract_task >> transform_task >> load_task >> quality_task