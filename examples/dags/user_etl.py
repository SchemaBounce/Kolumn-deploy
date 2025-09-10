"""
User ETL Pipeline - Kolumn File Discovery Demo
This DAG demonstrates ${var.} and ${resource.} interpolation in Python
"""

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.postgres_operator import PostgresOperator
from airflow.operators.python_operator import PythonOperator

# Configuration from Kolumn interpolation
DATABASE_URL = "${input.database_url}"
SOURCE_TABLE = "${input.source_table}"
TARGET_TABLE = "${input.target_table}"
BATCH_SIZE = ${input.batch_size}
SCHEDULE_INTERVAL = "${input.schedule}"

default_args = {
    'owner': 'kolumn-generated',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'user_etl_pipeline',
    default_args=default_args,
    description='User ETL pipeline generated from Kolumn file discovery',
    schedule_interval='${input.schedule}',
    catchup=False,
    tags=['kolumn-generated', 'etl', 'users'],
)

def extract_users(**context):
    """Extract users from source database"""
    import psycopg2
    import pandas as pd
    
    # Connect to source database
    conn = psycopg2.connect("${input.database_url}")
    
    # Extract with batch processing
    query = f"""
        SELECT id, email, name, created_at 
        FROM {SOURCE_TABLE}
        WHERE created_at >= %s
        ORDER BY id
        LIMIT {BATCH_SIZE}
    """
    
    execution_date = context['execution_date']
    df = pd.read_sql(query, conn, params=[execution_date])
    
    print(f"Extracted {len(df)} users from {SOURCE_TABLE}")
    return df.to_json()

def transform_users(**context):
    """Transform user data with business logic"""
    import json
    import pandas as pd
    
    # Get extracted data
    users_json = context['task_instance'].xcom_pull(task_ids='extract_users')
    df = pd.read_json(users_json)
    
    # Apply transformations
    df['email_domain'] = df['email'].str.split('@').str[1]
    df['is_gmail'] = df['email_domain'] == 'gmail.com'
    df['user_age_days'] = (datetime.now() - pd.to_datetime(df['created_at'])).dt.days
    
    # Add metadata from Kolumn discovery
    df['processed_by'] = 'kolumn-file-discovery'
    df['source_table'] = "${input.source_table}"
    df['target_table'] = "${input.target_table}"
    
    print(f"Transformed {len(df)} users")
    return df.to_json()

def load_users(**context):
    """Load transformed data to target"""
    import json
    import pandas as pd
    from google.cloud import bigquery
    
    # Get transformed data
    users_json = context['task_instance'].xcom_pull(task_ids='transform_users')
    df = pd.read_json(users_json)
    
    # Load to BigQuery (target configured via Kolumn)
    client = bigquery.Client()
    table_id = "${input.target_table}"
    
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
    )
    
    job = client.load_table_from_dataframe(df, table_id, job_config=job_config)
    job.result()  # Wait for job to complete
    
    print(f"Loaded {len(df)} users to {table_id}")

# Define task dependencies
extract_task = PythonOperator(
    task_id='extract_users',
    python_callable=extract_users,
    dag=dag,
)

transform_task = PythonOperator(
    task_id='transform_users',
    python_callable=transform_users,
    dag=dag,
)

load_task = PythonOperator(
    task_id='load_users',
    python_callable=load_users,
    dag=dag,
)

# Validation task using Kolumn resource references
validate_task = PostgresOperator(
    task_id='validate_load',
    postgres_conn_id='postgres_default',
    sql=f"""
        -- Validate the ETL process
        SELECT 
            COUNT(*) as loaded_count,
            MAX(processed_at) as last_processed
        FROM ${input.target_table}
        WHERE DATE(processed_at) = '{{ ds }}';
    """,
    dag=dag,
)

# Task dependencies
extract_task >> transform_task >> load_task >> validate_task

# Add monitoring and alerting
# Source and target references: ${input.source_table} -> ${input.target_table}
# Configured via Kolumn with batch size: ${input.batch_size}