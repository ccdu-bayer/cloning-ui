# GCP BigQuery Configuration Example
# Copy this file to config.R and fill in your actual values
# config.R is in .gitignore to prevent committing credentials

# GCP Project ID
GCP_PROJECT_ID <- "your-gcp-project-id"

# BigQuery Dataset and Table
BQ_DATASET <- "your-dataset-name"
BQ_TABLE <- "your-table-name"

# Path to your GCP service account JSON key file
# This file should be downloaded from GCP Console
GCP_KEY_PATH <- "path/to/your-service-account-key.json"

# Optional: Set BigQuery billing project if different from GCP_PROJECT_ID
BQ_BILLING_PROJECT <- GCP_PROJECT_ID
