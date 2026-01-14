library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(DT)
library(plotly)
library(bigrquery)

# Source helper functions
source("vault_helper.R")
source("bigquery_helper.R")

# Configuration - Use environment variables for security
VAULT_URL <- Sys.getenv("VAULT_URL")
VAULT_ROLE_ID <- Sys.getenv("VAULT_ROLE_ID")
VAULT_SECRET_ID <- Sys.getenv("VAULT_SECRET_ID")
VAULT_SECRET_PATH <- Sys.getenv("VAULT_SECRET_PATH")
GCP_PROJECT_ID <- Sys.getenv("GCP_PROJECT_ID")
BQ_DATASET_ID <- Sys.getenv("BQ_DATASET_ID")

# Development mode flag
DEV_MODE <- Sys.getenv("DEV_MODE", "FALSE") == "TRUE"
LOCAL_CRED_FILE <- Sys.getenv("LOCAL_CRED_FILE", "")

# Initialize BigQuery connection
project_id <- NULL

tryCatch({
  if (DEV_MODE && file.exists(LOCAL_CRED_FILE)) {
    # Development mode: use local credentials file
    message("Running in DEVELOPMENT MODE with local credentials")
    project_id <- connect_to_bigquery(GCP_PROJECT_ID, LOCAL_CRED_FILE)
    message("Successfully connected to BigQuery in DEV mode")
    
  }
  else if (!DEV_MODE) {
    # Production mode: use Vault
    message("Running in PRODUCTION MODE with Vault credentials")
    
    # Validate environment variables
    if (VAULT_URL == "" || VAULT_ROLE_ID == "" || VAULT_SECRET_ID == "") {
      stop("Missing Vault configuration. Please set VAULT_URL, VAULT_ROLE_ID, and VAULT_SECRET_ID environment variables.")
    }
    
    message(paste("Vault URL:", VAULT_URL))
    message(paste("Vault Secret Path:", VAULT_SECRET_PATH))
    
    cred_file <- get_gcp_credentials(
      VAULT_URL, 
      VAULT_ROLE_ID, 
      VAULT_SECRET_ID, 
      VAULT_SECRET_PATH
    )
    
    project_id <- connect_to_bigquery(GCP_PROJECT_ID, cred_file)
    message("Successfully connected to BigQuery via Vault")
    
  } else {
    stop("Please set DEV_MODE=TRUE and LOCAL_CRED_FILE path for local development, or configure Vault credentials for production.")
  }
  
}, error = function(e) {
  message("ERROR: Failed to initialize BigQuery connection")
  message(paste("Error details:", e$message))
  message("\nFor local development, create a .Renviron file with:")
  message("DEV_MODE=TRUE")
  message("LOCAL_CRED_FILE=/path/to/your/service-account-key.json")
  message("GCP_PROJECT_ID=your-project-id")
  message("BQ_DATASET_ID=your-dataset-id")
  stop(e$message)
})

