library(bigrquery)
library(dplyr)

# Global configuration
MAX_QUERY_ROWS <- 50000

# Function to authenticate and connect to BigQuery
connect_to_bigquery <- function(project_id, service_account_file) {
  bq_auth(path = service_account_file)
  return(project_id)
}

# Function to query BigQuery
query_bigquery <- function(project_id, sql_query, max_rows = MAX_QUERY_ROWS) {
  tryCatch({
    message("Executing query:")
    message(sql_query)
    
    start_time <- Sys.time()
    result <- bq_project_query(project_id, sql_query, use_legacy_sql = FALSE)
    data <- bq_table_download(result, max_results = max_rows)
    
    end_time <- Sys.time()
    elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))
    message(sprintf("Query returned %s rows in %.2f seconds", nrow(data), elapsed))
    
    return(data)
    
  }, error = function(e) {
    message("Query failed with error:")
    message(e$message)
    stop(paste("BigQuery query failed:", e$message))
  })
}

# Function to check if table exists
table_exists <- function(project_id, dataset_id, table_id) {
  tryCatch({
    table <- bq_table(project_id, dataset_id, table_id)
    bq_table_exists(table)
  }, error = function(e) {
    return(FALSE)
  })
}

# ============================================================
# PARENT TABLE FUNCTIONS (Load on startup)
# ============================================================

# Function to get ALL set rearray records (parent table only)
get_all_sets <- function(project_id, dataset_id) {
  
  if (!table_exists(project_id, dataset_id, "tbl_set_rearray")) {
    stop(paste("Table not found:", 
               sprintf("%s.%s.tbl_set_rearray", project_id, dataset_id)))
  }
  
  query <- sprintf(
    "SELECT sel_list_id, set_rearray_name 
     FROM `%s.%s.tbl_set_rearray` 
     WHERE sel_list_id IS NOT NULL AND set_rearray_name IS NOT NULL
     ORDER BY set_rearray_name",
    project_id, dataset_id
  )
  
  return(query_bigquery(project_id, query))
}

# ============================================================
# CHILD TABLE FUNCTIONS (Load on demand based on selected sets)
# ============================================================

# Function to get source IDs for SELECTED sets only
get_source_ids_for_sets <- function(project_id, dataset_id, set_ids) {
  
  if (is.null(set_ids) || length(set_ids) == 0) {
    return(data.frame(src_id = character(0)))
  }
  
  set_ids_str <- paste0( set_ids, collapse = ", ")
  
  query <- sprintf(
    "SELECT DISTINCT src_id 
     FROM `%s.%s.tbl_set_rearray_clones` 
     WHERE sel_list_id IN (%s) AND src_id IS NOT NULL
     ORDER BY src_id",
    project_id, dataset_id, set_ids_str
  )
  
  return(query_bigquery(project_id, query))
}

# Function to get clone IDs for SELECTED sets only
get_clone_ids_for_sets <- function(project_id, dataset_id, set_ids) {
  
  if (is.null(set_ids) || length(set_ids) == 0) {
    return(data.frame(clone_id = character(0)))
  }
  
  set_ids_str <- paste0( set_ids, collapse = ", ")
  
  query <- sprintf(
    "SELECT DISTINCT clone_id 
     FROM `%s.%s.tbl_set_rearray_clones` 
     WHERE sel_list_id IN (%s) AND clone_id IS NOT NULL
     ORDER BY clone_id",
    project_id, dataset_id, set_ids_str
  )
  
  return(query_bigquery(project_id, query))
}

# ============================================================
# DATA RETRIEVAL FUNCTIONS
# ============================================================

# Function to get filtered data
get_filtered_data <- function(project_id, dataset_id, set_ids = NULL, src_ids = NULL, clone_ids = NULL) {
  
  if (is.null(set_ids) || length(set_ids) == 0) {
    return(data.frame(
      sel_list_id = character(0),
      set_rearray_name = character(0),
      child_sel_list_id = character(0),
      src_id = character(0),
      clone_id = character(0)
    ))
  }
  
  where_clauses <- c()
  
  # Set filter (required)
  set_ids_str <- paste0(  set_ids, collapse = ", ")
  where_clauses <- c(where_clauses, sprintf("sr.sel_list_id IN (%s)", set_ids_str))
  
  # Source filter (optional)
  if (!is.null(src_ids) && length(src_ids) > 0) {
    src_ids_str <- paste0(  src_ids, collapse = ", ")
    where_clauses <- c(where_clauses, sprintf("src.src_id IN (%s)", src_ids_str))
  }
  
  # Clone filter (optional)
  if (!is.null(clone_ids) && length(clone_ids) > 0) {
    clone_ids_str <- paste0("'", clone_ids, "'", collapse = ", ")
    where_clauses <- c(where_clauses, sprintf("src.clone_id IN (%s)", clone_ids_str))
  }
  
  where_clause <- paste("WHERE", paste(where_clauses, collapse = " AND "))
  
  query <- sprintf(
    "SELECT 
      sr.sel_list_id,
      sr.set_rearray_name,
      src.sel_list_id as child_sel_list_id,
      src.src_id,
      src.clone_id
     FROM `%s.%s.tbl_set_rearray` sr
     LEFT JOIN `%s.%s.tbl_set_rearray_clones` src
       ON sr.sel_list_id = src.sel_list_id
     %s
     ORDER BY sr.set_rearray_name, src.src_id, src.clone_id
     LIMIT %s",
    project_id, dataset_id,
    project_id, dataset_id,
    where_clause,
    MAX_QUERY_ROWS
  )
  
  return(query_bigquery(project_id, query))
}

# Function to get summary statistics
get_summary_stats <- function(project_id, dataset_id, set_ids = NULL, src_ids = NULL, clone_ids = NULL) {
  
  if (is.null(set_ids) || length(set_ids) == 0) {
    return(data.frame(
      total_sets = 0,
      total_sel_lists = 0,
      total_sources = 0,
      total_clones = 0,
      total_records = 0
    ))
  }
  
  where_clauses <- c()
  
  set_ids_str <- paste0(  set_ids,  collapse = ", ")
  where_clauses <- c(where_clauses, sprintf("sr.sel_list_id IN (%s)", set_ids_str))
  
  if (!is.null(src_ids) && length(src_ids) > 0) {
    src_ids_str <- paste0(  src_ids,  collapse = ", ")
    where_clauses <- c(where_clauses, sprintf("src.src_id IN (%s)", src_ids_str))
  }
  
  if (!is.null(clone_ids) && length(clone_ids) > 0) {
    clone_ids_str <- paste0("'", clone_ids,  "'", collapse = ", ")
    where_clauses <- c(where_clauses, sprintf("src.clone_id IN (%s)", clone_ids_str))
  }
  
  where_clause <- paste("WHERE", paste(where_clauses, collapse = " AND "))
  
  query <- sprintf(
    "SELECT 
      COUNT(DISTINCT sr.sel_list_id) as total_sets,
      COUNT(DISTINCT src.sel_list_id) as total_sel_lists,
      COUNT(DISTINCT src.src_id) as total_sources,
      COUNT(DISTINCT src.clone_id) as total_clones,
      COUNT(*) as total_records
     FROM `%s.%s.tbl_set_rearray` sr
     LEFT JOIN `%s.%s.tbl_set_rearray_clones` src
       ON sr.sel_list_id = src.sel_list_id
     %s",
    project_id, dataset_id,
    project_id, dataset_id,
    where_clause
  )
  
  return(query_bigquery(project_id, query, max_rows = 1))
}

# Function to get clone distribution by set
get_clones_by_set <- function(project_id, dataset_id, set_ids = NULL, src_ids = NULL, clone_ids = NULL) {
  
  if (is.null(set_ids) || length(set_ids) == 0) {
    return(data.frame(
      set_rearray_name = character(0),
      clone_count = numeric(0),
      source_count = numeric(0)
    ))
  }
  
  where_clauses <- c()
  
  set_ids_str <- paste0( set_ids, collapse = ", ")
  where_clauses <- c(where_clauses, sprintf("sr.sel_list_id IN (%s)", set_ids_str))
  
  if (!is.null(src_ids) && length(src_ids) > 0) {
    src_ids_str <- paste0( src_ids, collapse = ", ")
    where_clauses <- c(where_clauses, sprintf("src.src_id IN (%s)", src_ids_str))
  }
  
  if (!is.null(clone_ids) && length(clone_ids) > 0) {
    clone_ids_str <- paste0("'", clone_ids, "'", collapse = ", ")
    where_clauses <- c(where_clauses, sprintf("src.clone_id IN (%s)", clone_ids_str))
  }
  
  where_clause <- paste("WHERE", paste(where_clauses, collapse = " AND "))
  
  query <- sprintf(
    "SELECT 
      sr.set_rearray_name,
      COUNT(DISTINCT src.clone_id) as clone_count,
      COUNT(DISTINCT src.src_id) as source_count
     FROM `%s.%s.tbl_set_rearray` sr
     LEFT JOIN `%s.%s.tbl_set_rearray_clones` src
       ON sr.sel_list_id = src.sel_list_id
     %s
     GROUP BY sr.set_rearray_name
     ORDER BY clone_count DESC",
    project_id, dataset_id,
    project_id, dataset_id,
    where_clause
  )
  
  return(query_bigquery(project_id, query))
}

# Function to get source to clone mapping counts
get_source_clone_mapping <- function(project_id, dataset_id, set_ids = NULL) {
  
  if (is.null(set_ids) || length(set_ids) == 0) {
    return(data.frame(
      src_id = character(0),
      clone_count = numeric(0)
    ))
  }
  
  set_ids_str <- paste0( set_ids,  collapse = ", ")
  where_clause <- sprintf("WHERE sr.sel_list_id IN (%s)", set_ids_str)
  
  query <- sprintf(
    "SELECT 
      src.src_id,
      COUNT(DISTINCT src.clone_id) as clone_count
     FROM `%s.%s.tbl_set_rearray` sr
     LEFT JOIN `%s.%s.tbl_set_rearray_clones` src
       ON sr.sel_list_id = src.sel_list_id
     %s
     GROUP BY src.src_id
     HAVING src.src_id IS NOT NULL
     ORDER BY clone_count DESC
     LIMIT 20",
    project_id, dataset_id,
    project_id, dataset_id,
    where_clause
  )
  
  return(query_bigquery(project_id, query))
}