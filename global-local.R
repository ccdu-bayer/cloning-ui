library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(DT)
library(plotly)
library(bigrquery)

# Source helper functions
source("bigquery_helper.R")

# Configuration
GCP_PROJECT_ID <- Sys.getenv("GCP_PROJECT_ID")
BQ_DATASET_ID <- Sys.getenv("BQ_DATASET_ID")
DEV_MODE <- Sys.getenv("DEV_MODE", "FALSE") == "TRUE"
LOCAL_CRED_FILE <- Sys.getenv("LOCAL_CRED_FILE", "")

# Validate configuration
if (GCP_PROJECT_ID == "" || BQ_DATASET_ID == "") {
  stop("Please set GCP_PROJECT_ID and BQ_DATASET_ID in .Renviron file")
}

if (DEV_MODE && !file.exists(LOCAL_CRED_FILE)) {
  stop(paste("Credentials file not found:", LOCAL_CRED_FILE))
}

# Initialize BigQuery connection
project_id <- NULL

cat("==========================================\n")
cat("Starting Shiny App Initialization\n")
cat("==========================================\n")

if (DEV_MODE) {
  cat("Mode: DEVELOPMENT\n")
  cat(paste("Project:", GCP_PROJECT_ID, "\n"))
  cat(paste("Dataset:", BQ_DATASET_ID, "\n"))
  cat(paste("Credentials:", LOCAL_CRED_FILE, "\n"))
  
  cat("\nConnecting to BigQuery...\n")
  project_id <- connect_to_bigquery(GCP_PROJECT_ID, LOCAL_CRED_FILE)
  cat("✓ Connected successfully!\n")
  
  # Quick validation
  cat("\nValidating tables...\n")
  if (table_exists(project_id, BQ_DATASET_ID, "tbl_set_rearray")) {
    cat("✓ tbl_set_rearray found\n")
  } else {
    stop("✗ tbl_set_rearray NOT FOUND")
  }
  
  if (table_exists(project_id, BQ_DATASET_ID, "tbl_set_rearray_clones")) {
    cat("✓ tbl_set_rearray_clones found\n")
  } else {
    stop("✗ tbl_set_rearray_clones NOT FOUND")
  }
  
} else {
  stop("DEV_MODE not enabled. Set DEV_MODE=TRUE in .Renviron")
}

cat("==========================================\n")
cat("Initialization Complete - Starting App\n")
cat("==========================================\n\n")