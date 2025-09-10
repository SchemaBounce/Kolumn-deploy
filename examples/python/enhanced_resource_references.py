---
name: enhanced_python_example
description: Comprehensive demonstration of enhanced Python resource references
version: "2.0.0"
author: "Kolumn Data Platform Team"
category: "etl"
purpose: "demonstration"
script_type: "etl"
materialized: "table"
schedule: "0 6 * * *"
timeout: "30m"
replace_on_change: true

# Dependencies using enhanced references
depends_on:
  - postgres_table.raw_customers
  - sql_view.customer_summary  
  - kolumn_data_object.customer
  - kafka_topic.customer_events

# Data objects this script uses
uses_data_objects:
  - kolumn_data_object.customer
  - kolumn_data_object.order

# Objects this script generates
generates_objects:
  - postgres_table.customer_analytics
  - s3_object.customer_export

# Environment support
environment: ["dev", "staging", "prod"]
tags: ["pii", "customer", "analytics", "enhanced_references"]

# Python-specific metadata
python_version: ">=3.8"
requirements:
  - "pandas>=1.5.0"
  - "sqlalchemy>=1.4.0"
  - "boto3>=1.26.0"
  - "kafka-python>=2.0.0"

# Performance configuration
memory_limit: "4GB"
cpu_limit: "2"
optimizations: ["multiprocessing", "vectorization"]

# Cross-provider configuration
provider_config:
  postgres:
    schema: "analytics"
    connection_pool_size: 10
  kafka:
    consumer_group: "python-etl"
    batch_size: 1000
  s3:
    bucket: "data-exports"
    prefix: "customers/"

# Data processing optimization
indexes: ["customer_id", "created_at"]
partition_by: "DATE(created_at)"
unique_key: ["customer_id"]

# Governance and compliance
data_classification: ["pii"]
compliance_frameworks: ["gdpr", "ccpa"]

# Transforms metadata
transforms:
  from_tables: ["postgres_table.raw_customers"]
  from_views: ["sql_view.customer_summary"]
  from_apis: ["kafka_topic.customer_events"]
  to_table: "postgres_table.customer_analytics"
  to_file: "s3://exports/customer_analytics.parquet"
  strategy: "incremental"
  framework: "pandas"

# ML metadata (if applicable)
ml_metadata:
  model_type: "feature_engineering"
  framework: "pandas"
  features: ["ltv_score", "churn_risk", "segment"]
  training_dataset: "postgres_table.customer_analytics"
---

"""
Enhanced Python Resource References Demo

This script demonstrates all the advanced resource reference patterns available
in Kolumn's Phase 2 Python processor:

1. Basic References: ${postgres_table.customers}
2. Property Access: ${postgres_table.customers.schema}
3. Conditional References: ${when environment == 'prod'}${postgres_table.customers}${else}${postgres_table.customers_dev}${end}
4. Function Calls: ${fn.date_trunc('month', created_at)}
5. Environment Variables: ${env.DATABASE_URL}
6. Data Object References: ${kolumn_data_object.customer.columns}
7. Cross-Provider References: ${bigquery.bigquery_table.customers.dataset}

This represents a breakthrough in infrastructure-as-code for data platforms,
where Python scripts can seamlessly reference resources across multiple providers
with type safety and environment-aware resolution.

Author: Data Platform Team
Version: 2.0.0 (Phase 2 Enhanced)
"""

import pandas as pd
import numpy as np
from sqlalchemy import create_engine, text
import boto3
from kafka import KafkaConsumer
import logging
from datetime import datetime, timedelta
import os
import json
from typing import Dict, List, Optional

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class EnhancedCustomerETL:
    """
    Advanced ETL pipeline demonstrating enhanced resource references
    across multiple providers (PostgreSQL, Kafka, S3, BigQuery)
    """
    
    def __init__(self):
        """Initialize ETL with enhanced resource references"""
        
        # 1. BASIC RESOURCE REFERENCES
        # Traditional ${resource_type.name} pattern
        self.source_table = "${postgres_table.raw_customers}"
        self.target_table = "${postgres_table.customer_analytics}"
        
        # 2. PROPERTY ACCESS REFERENCES
        # Access specific properties of resources
        self.source_schema = "${postgres_table.raw_customers.schema}"  # → "public"
        self.target_schema = "${postgres_table.customer_analytics.schema}"  # → "analytics"
        self.table_owner = "${postgres_table.raw_customers.owner}"  # → "postgres"
        
        # 3. CONDITIONAL REFERENCES (Environment-aware)
        # Different resources based on environment
        self.database_url = "${when environment == 'prod'}${env.PROD_DATABASE_URL}${else}${env.DEV_DATABASE_URL}${end}"
        self.redis_url = "${when environment == 'prod'}${env.PROD_REDIS_URL}${else}${env.DEV_REDIS_URL}${end}"
        
        # Environment-specific table selection
        self.events_table = "${when environment == 'prod'}${postgres_table.customer_events}${else}${postgres_table.customer_events_dev}${end}"
        
        # 4. FUNCTION CALLS (Provider-aware)
        # Functions that translate across database providers
        self.date_trunc_func = "${fn.date_trunc('month', created_at)}"  # → DATE_TRUNC for Postgres, DATE_FORMAT for MySQL
        self.json_extract_func = "${fn.json_extract(metadata, '$.source')}"  # → Provider-specific JSON functions
        
        # 5. ENVIRONMENT VARIABLE REFERENCES
        # Direct access to environment variables
        self.api_base_url = "${env.API_BASE_URL}"
        self.batch_size = int("${env.BATCH_SIZE}" or "1000")
        self.max_retries = int("${env.MAX_RETRIES}" or "3")
        
        # 6. DATA OBJECT REFERENCES
        # Access to Kolumn data object definitions
        self.customer_columns = json.loads("${kolumn_data_object.customer.columns}")
        self.customer_classification = "${kolumn_data_object.customer.classification}"
        self.data_retention = "${kolumn_data_object.customer.retention}"
        
        # 7. CROSS-PROVIDER REFERENCES
        # Reference resources in other providers
        self.bigquery_dataset = "${bigquery.bigquery_table.customers.dataset}"  # → "analytics"
        self.kafka_topic_partitions = int("${kafka.kafka_topic.customer_events.partitions}")  # → 12
        self.s3_bucket_region = "${s3.s3_bucket.data_lake.region}"  # → "us-west-2"
        
        logger.info(f"Initialized ETL with enhanced resource references")
        logger.info(f"Source schema: {self.source_schema}")
        logger.info(f"Target schema: {self.target_schema}")
        logger.info(f"BigQuery dataset: {self.bigquery_dataset}")
        logger.info(f"Kafka partitions: {self.kafka_topic_partitions}")
        
    def setup_connections(self) -> Dict:
        """Setup database connections using enhanced references"""
        
        connections = {}
        
        # PostgreSQL connection using environment-aware URL
        postgres_url = "${when environment == 'prod'}postgresql://prod-host:5432/analytics${else}postgresql://localhost:5432/dev${end}"
        connections['postgres'] = create_engine(postgres_url)
        logger.info(f"Connected to PostgreSQL: {postgres_url[:20]}...")
        
        # Kafka consumer with cross-provider topic configuration
        kafka_config = {
            'bootstrap_servers': ["${env.KAFKA_BROKERS}"],
            'group_id': 'enhanced-python-etl',
            'auto_offset_reset': 'latest',
            'value_deserializer': lambda x: json.loads(x.decode('utf-8'))
        }
        connections['kafka'] = KafkaConsumer(
            "${kafka.kafka_topic.customer_events}",
            **kafka_config
        )
        logger.info(f"Connected to Kafka topic: ${kafka.kafka_topic.customer_events}")
        
        # S3 client with cross-provider bucket configuration
        connections['s3'] = boto3.client(
            's3',
            region_name="${s3.s3_bucket.data_lake.region}"
        )
        logger.info(f"Connected to S3 in region: {self.s3_bucket_region}")
        
        return connections
    
    def extract_customer_data(self, connections: Dict) -> pd.DataFrame:
        """Extract customer data using enhanced SQL with function calls"""
        
        # Advanced SQL query with cross-provider function calls
        query = f"""
        SELECT 
            id,
            email,
            first_name,
            last_name,
            created_at,
            {self.date_trunc_func} as cohort_month,
            {self.json_extract_func} as acquisition_source,
            updated_at
        FROM {self.source_table}
        WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
        AND status = 'active'
        ORDER BY created_at DESC
        """
        
        logger.info(f"Extracting from source: {self.source_table}")
        logger.info(f"Using schema: {self.source_schema}")
        
        df = pd.read_sql(query, connections['postgres'])
        logger.info(f"Extracted {len(df)} customer records")
        
        return df
    
    def enrich_with_kafka_events(self, df: pd.DataFrame, connections: Dict) -> pd.DataFrame:
        """Enrich customer data with Kafka events using cross-provider references"""
        
        logger.info(f"Enriching with events from Kafka (partitions: {self.kafka_topic_partitions})")
        
        # Consume recent events from Kafka
        consumer = connections['kafka']
        events_by_customer = {}
        
        # Process events with timeout
        timeout = 30  # seconds
        start_time = datetime.now()
        
        for message in consumer:
            if (datetime.now() - start_time).seconds > timeout:
                break
                
            event_data = message.value
            customer_id = event_data.get('customer_id')
            event_type = event_data.get('event_type')
            
            if customer_id not in events_by_customer:
                events_by_customer[customer_id] = []
            events_by_customer[customer_id].append(event_type)
        
        # Enrich DataFrame with event data
        df['recent_events'] = df['id'].map(
            lambda cid: len(events_by_customer.get(cid, []))
        )
        df['event_types'] = df['id'].map(
            lambda cid: ','.join(set(events_by_customer.get(cid, [])))
        )
        
        logger.info(f"Enriched {len(df)} records with Kafka events")
        return df
    
    def calculate_customer_metrics(self, df: pd.DataFrame) -> pd.DataFrame:
        """Calculate advanced customer metrics using data object definitions"""
        
        logger.info(f"Calculating metrics based on data classification: {self.customer_classification}")
        
        # Customer Lifetime Value estimation
        df['days_since_signup'] = (
            pd.Timestamp.now() - pd.to_datetime(df['created_at'])
        ).dt.days
        
        # Engagement score based on recent events
        df['engagement_score'] = np.clip(
            df['recent_events'] * 10 + (100 - df['days_since_signup'] * 0.1),
            0, 100
        )
        
        # Customer segmentation
        df['segment'] = pd.cut(
            df['engagement_score'],
            bins=[0, 25, 50, 75, 100],
            labels=['bronze', 'silver', 'gold', 'platinum']
        )
        
        # Risk scoring (for compliance with data classification)
        df['churn_risk'] = np.where(
            (df['days_since_signup'] > 365) & (df['recent_events'] == 0),
            'high',
            np.where(df['engagement_score'] < 30, 'medium', 'low')
        )
        
        logger.info(f"Calculated metrics for {len(df)} customers")
        return df
    
    def load_to_analytics_table(self, df: pd.DataFrame, connections: Dict) -> None:
        """Load processed data to analytics table with enhanced configuration"""
        
        logger.info(f"Loading to target: {self.target_table}")
        logger.info(f"Target schema: {self.target_schema}")
        logger.info(f"Partition by: ${partition_by}")
        logger.info(f"Unique key: ${unique_key}")
        
        # Load with enhanced metadata-driven configuration
        df.to_sql(
            name='customer_analytics',
            con=connections['postgres'],
            schema=self.target_schema,
            if_exists='append',  # Incremental loading
            index=False,
            method='multi',  # Batch insert for performance
            chunksize=self.batch_size
        )
        
        logger.info(f"Successfully loaded {len(df)} records to {self.target_table}")
    
    def export_to_s3(self, df: pd.DataFrame, connections: Dict) -> None:
        """Export processed data to S3 using cross-provider bucket configuration"""
        
        s3_bucket = "${s3.s3_bucket.data_lake.name}"  # Cross-provider reference
        s3_key = f"analytics/customer_metrics/date={datetime.now().strftime('%Y-%m-%d')}/data.parquet"
        
        logger.info(f"Exporting to S3: s3://{s3_bucket}/{s3_key}")
        logger.info(f"S3 region: {self.s3_bucket_region}")
        
        # Convert to Parquet and upload
        parquet_buffer = df.to_parquet(index=False)
        
        connections['s3'].put_object(
            Bucket=s3_bucket,
            Key=s3_key,
            Body=parquet_buffer,
            Metadata={
                'source': 'enhanced-python-etl',
                'data_classification': self.customer_classification,
                'retention_period': self.data_retention,
                'record_count': str(len(df))
            }
        )
        
        logger.info(f"Successfully exported {len(df)} records to S3")
    
    def sync_to_bigquery(self, df: pd.DataFrame) -> None:
        """Sync data to BigQuery using cross-provider references"""
        
        # BigQuery destination using cross-provider references
        bq_project = "${bigquery.bigquery_table.customers.project}"
        bq_dataset = "${bigquery.bigquery_table.customers.dataset}"
        bq_table = "customer_analytics"
        
        logger.info(f"Syncing to BigQuery: {bq_project}.{bq_dataset}.{bq_table}")
        
        # In a real implementation, would use BigQuery client
        # This demonstrates the cross-provider reference resolution
        destination = f"{bq_project}.{bq_dataset}.{bq_table}"
        logger.info(f"BigQuery sync target resolved: {destination}")
    
    def run_comprehensive_pipeline(self) -> Dict:
        """Execute the complete ETL pipeline with enhanced resource references"""
        
        start_time = datetime.now()
        logger.info("🚀 Starting Enhanced Python ETL Pipeline")
        
        try:
            # Setup connections using enhanced references
            connections = self.setup_connections()
            
            # Extract data with advanced SQL and function calls
            customer_data = self.extract_customer_data(connections)
            
            # Enrich with real-time Kafka events
            enriched_data = self.enrich_with_kafka_events(customer_data, connections)
            
            # Calculate metrics using data object definitions
            processed_data = self.calculate_customer_metrics(enriched_data)
            
            # Load to PostgreSQL analytics table
            self.load_to_analytics_table(processed_data, connections)
            
            # Export to S3 for data lake
            self.export_to_s3(processed_data, connections)
            
            # Sync to BigQuery for analytics
            self.sync_to_bigquery(processed_data)
            
            # Calculate execution metrics
            execution_time = (datetime.now() - start_time).total_seconds()
            
            results = {
                'status': 'success',
                'records_processed': len(processed_data),
                'execution_time_seconds': execution_time,
                'source_table': self.source_table,
                'target_table': self.target_table,
                'kafka_partitions': self.kafka_topic_partitions,
                'bq_dataset': self.bigquery_dataset,
                's3_region': self.s3_bucket_region,
                'data_classification': self.customer_classification
            }
            
            logger.info(f"✅ Pipeline completed successfully in {execution_time:.2f}s")
            logger.info(f"📊 Processed {results['records_processed']} records")
            
            return results
            
        except Exception as e:
            logger.error(f"❌ Pipeline failed: {str(e)}")
            raise
        
        finally:
            # Close connections
            for conn_name, conn in connections.items():
                if hasattr(conn, 'close'):
                    conn.close()
                    logger.info(f"Closed {conn_name} connection")

def main():
    """
    Main execution function demonstrating enhanced Python resource references
    
    This script showcases Kolumn's Phase 2 breakthrough:
    - Python files as first-class citizens alongside SQL
    - Advanced resource reference patterns
    - Cross-provider resource resolution
    - Environment-aware configuration
    - Type-safe property access
    - Conditional resource selection
    """
    
    # Environment configuration using enhanced references
    current_env = "${env.ENVIRONMENT}" or "development"
    log_level = "${env.LOG_LEVEL}" or "INFO"
    
    logger.info(f"🐍 Enhanced Python ETL Demo - Phase 2")
    logger.info(f"Environment: {current_env}")
    logger.info(f"Log Level: {log_level}")
    logger.info(f"Python Version: ${python_version}")
    
    # Initialize and run ETL
    etl = EnhancedCustomerETL()
    results = etl.run_comprehensive_pipeline()
    
    # Display results
    print("\n🎉 Enhanced Python ETL Results:")
    print(f"Status: {results['status']}")
    print(f"Records: {results['records_processed']}")
    print(f"Duration: {results['execution_time_seconds']:.2f}s")
    print(f"Source: {results['source_table']}")
    print(f"Target: {results['target_table']}")
    print(f"Kafka Partitions: {results['kafka_partitions']}")
    print(f"BigQuery Dataset: {results['bq_dataset']}")
    print(f"S3 Region: {results['s3_region']}")
    print(f"Data Classification: {results['data_classification']}")
    
    print("\n🚀 Phase 2 Enhanced Resource References Demonstrated!")
    print("✅ Basic References: ${postgres_table.customers}")
    print("✅ Property Access: ${postgres_table.customers.schema}")
    print("✅ Conditional Refs: ${when env}${resource}${else}${other}${end}")
    print("✅ Function Calls: ${fn.date_trunc('month', created_at)}")
    print("✅ Environment Vars: ${env.DATABASE_URL}")
    print("✅ Data Objects: ${kolumn_data_object.customer.columns}")
    print("✅ Cross-Provider: ${bigquery.bigquery_table.customers.dataset}")
    print("")
    print("🎯 Python files are now first-class citizens in Kolumn!")
    
if __name__ == "__main__":
    main()