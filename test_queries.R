# test_queries.R - Run this BEFORE starting the Shiny app

library(bigrquery)

# Authenticate
bq_auth(path = Sys.getenv("LOCAL_CRED_FILE"))

project_id <- Sys.getenv("GCP_PROJECT_ID")
dataset_id <- Sys.getenv("BQ_DATASET_ID")

cat("=== Testing BigQuery Queries ===\n\n")

# Test 1: Check table sizes
cat("Test 1: Checking table sizes...\n")
query1 <- sprintf("SELECT COUNT(*) as row_count FROM `%s.%s.tbl_set_rearray`", 
                  project_id, dataset_id)
result1 <- bq_project_query(project_id, query1)
count1 <- bq_table_download(result1)
cat(sprintf("  tbl_set_rearray has %s rows\n", format(count1$row_count, big.mark = ",")))

query2 <- sprintf("SELECT COUNT(*) as row_count FROM `%s.%s.tbl_set_rearray_clones`", 
                  project_id, dataset_id)
result2 <- bq_project_query(project_id, query2)
count2 <- bq_table_download(result2)
cat(sprintf("  tbl_set_rearray_clones has %s rows\n\n", format(count2$row_count, big.mark = ",")))

# Test 2: Get distinct counts (this is what's probably hanging)
cat("Test 2: Getting distinct sel_list_id count...\n")
query3 <- sprintf("SELECT COUNT(DISTINCT sel_list_id) as distinct_count FROM `%s.%s.tbl_set_rearray`", 
                  project_id, dataset_id)
result3 <- bq_project_query(project_id, query3)
count3 <- bq_table_download(result3)
cat(sprintf("  Distinct sel_list_ids: %s\n\n", count3$distinct_count))

# Test 3: Try to get the actual list (WITH LIMIT)
cat("Test 3: Getting sel_list_id and names (LIMIT 100)...\n")
query4 <- sprintf(
  "SELECT DISTINCT sel_list_id, set_rearray_name 
   FROM `%s.%s.tbl_set_rearray` 
   WHERE sel_list_id IS NOT NULL 
   LIMIT 100", 
  project_id, dataset_id
)
start_time <- Sys.time()
result4 <- bq_project_query(project_id, query4)
data4 <- bq_table_download(result4)
end_time <- Sys.time()
cat(sprintf("  Retrieved %s rows in %.2f seconds\n\n", nrow(data4), as.numeric(end_time - start_time)))

# Test 4: Get source IDs (WITH LIMIT)
cat("Test 4: Getting source IDs (LIMIT 100)...\n")
query5 <- sprintf(
  "SELECT DISTINCT src_id 
   FROM `%s.%s.tbl_set_rearray_clones` 
   WHERE src_id IS NOT NULL 
   LIMIT 100", 
  project_id, dataset_id
)
start_time <- Sys.time()
result5 <- bq_project_query(project_id, query5)
data5 <- bq_table_download(result5)
end_time <- Sys.time()
cat(sprintf("  Retrieved %s rows in %.2f seconds\n\n", nrow(data5), as.numeric(end_time - start_time)))

# Test 5: Get clone IDs (WITH LIMIT)
cat("Test 5: Getting clone IDs (LIMIT 100)...\n")
query6 <- sprintf(
  "SELECT DISTINCT clone_id 
   FROM `%s.%s.tbl_set_rearray_clones` 
   WHERE clone_id IS NOT NULL 
   LIMIT 100", 
  project_id, dataset_id
)
start_time <- Sys.time()
result6 <- bq_project_query(project_id, query6)
data6 <- bq_table_download(result6)
end_time <- Sys.time()
cat(sprintf("  Retrieved %s rows in %.2f seconds\n\n", nrow(data6), as.numeric(end_time - start_time)))

cat("=== All tests complete ===\n")
cat("\nIf any query took more than 10 seconds, we need to optimize!\n")