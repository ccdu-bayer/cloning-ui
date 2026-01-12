# Testing Guide - Cloning UI RShiny Dashboard

## Overview

This guide explains how to test the RShiny application locally and in production.

## Prerequisites for Testing

- R 4.0 or higher installed
- All required packages installed (run `Rscript install.R`)
- GCP account with BigQuery access (for integration testing)

## Testing Modes

### 1. Demo Mode (No GCP Required)

Test the UI and functionality without BigQuery:

```r
# Run the app without configuration
shiny::runApp()
```

The app will use sample data. Verify:
- ✅ App loads without errors
- ✅ All tabs are accessible
- ✅ Charts render correctly
- ✅ Data table displays sample data
- ✅ Refresh button works
- ✅ No console errors

### 2. Local Testing with GCP

Test with real BigQuery connection:

1. Set up configuration:
   ```bash
   cp config.example.R config.R
   # Edit config.R with your GCP details
   ```

2. Run the app:
   ```r
   shiny::runApp()
   ```

3. Verify:
   - ✅ Authentication succeeds
   - ✅ Data loads from BigQuery
   - ✅ Correct table name shown in About tab
   - ✅ Data refreshes when button clicked
   - ✅ Charts reflect actual data

### 3. Docker Testing

Test the containerized application:

```bash
# Build the image
docker build -t cloning-ui .

# Run with demo mode
docker run -p 3838:3838 cloning-ui

# Run with GCP credentials
docker run -p 3838:3838 \
  -v $(pwd)/credentials:/srv/shiny-server/cloning-ui/credentials:ro \
  -e GCP_PROJECT_ID=your-project \
  -e BQ_DATASET=your-dataset \
  -e BQ_TABLE=your-table \
  -e GCP_KEY_PATH=/srv/shiny-server/cloning-ui/credentials/key.json \
  cloning-ui
```

Access at http://localhost:3838

## Manual Test Cases

### TC1: Application Startup
**Steps:**
1. Start the application
2. Wait for loading screen

**Expected:**
- Loading progress shown
- Dashboard tab opens by default
- No error messages

### TC2: Dashboard Tab
**Steps:**
1. Navigate to Dashboard tab
2. Observe value boxes and charts

**Expected:**
- Three value boxes show metrics
- Timeline chart displays
- Status distribution chart displays
- Score distribution chart displays

### TC3: Data Table Tab
**Steps:**
1. Navigate to Data Table tab
2. Try searching and filtering

**Expected:**
- Table displays with all columns
- Search box works
- Column filters work
- Pagination works

### TC4: Statistics Tab
**Steps:**
1. Navigate to Statistics tab
2. Review summary information

**Expected:**
- Data summary displays
- Column statistics table shows
- All numeric summaries correct

### TC5: About Tab
**Steps:**
1. Navigate to About tab
2. Verify information

**Expected:**
- Project details shown
- Dataset information correct
- Last update timestamp displays

### TC6: Data Refresh
**Steps:**
1. Note current data
2. Click "Refresh Data" button
3. Wait for completion

**Expected:**
- Progress indicator shown
- Success notification appears
- Data updates (if source changed)
- Last update time changes

### TC7: Error Handling
**Steps:**
1. Provide invalid credentials
2. Run the application

**Expected:**
- App starts in demo mode
- Error logged to console
- User sees sample data
- No crash or hang

### TC8: Responsive Design
**Steps:**
1. Resize browser window
2. Test on different screen sizes

**Expected:**
- Layout adjusts appropriately
- All elements remain accessible
- No overlapping content

## Integration Testing

### BigQuery Connection Test

Create a test script:

```r
library(bigrquery)

# Set credentials
GCP_PROJECT_ID <- "your-project"
BQ_DATASET <- "your-dataset"
BQ_TABLE <- "your-table"

# Test query
sql <- paste0("SELECT * FROM `", GCP_PROJECT_ID, ".", BQ_DATASET, ".", BQ_TABLE, "` LIMIT 1")

tryCatch({
  result <- bq_project_query(GCP_PROJECT_ID, sql)
  data <- bq_table_download(result)
  print("✓ BigQuery connection successful")
  print(head(data))
}, error = function(e) {
  print(paste("✗ BigQuery connection failed:", e$message))
})
```

## Performance Testing

### Load Test

Test with large datasets:

1. Modify SQL query to remove LIMIT
2. Time the data load
3. Monitor memory usage

```r
# In app.R, modify fetch_bigquery_data():
sql <- paste0("SELECT * FROM `", table_ref, "`")  # Remove LIMIT

# Monitor with:
system.time({
  data <- fetch_bigquery_data()
})
```

**Acceptable Performance:**
- Initial load: < 10 seconds for 1000 rows
- Refresh: < 5 seconds for subsequent loads
- Memory: < 500MB for typical datasets

### Concurrent Users

Test multiple users:

```bash
# Run multiple instances
for i in {1..5}; do
  xdg-open http://localhost:3838 &
done
```

## Automated Testing (Optional)

### Using shinytest2

```r
# Install shinytest2
install.packages("shinytest2")

# Create tests
library(shinytest2)
test_that("app loads", {
  app <- AppDriver$new()
  expect_true(app$is_running())
  app$stop()
})
```

## Security Testing

### Checklist
- ✅ config.R not in git
- ✅ JSON keys not in git
- ✅ No credentials in logs
- ✅ SQL queries not user-controlled
- ✅ Error messages don't leak info
- ✅ HTTPS enabled (production)

### Penetration Testing
- SQL injection: Not applicable (parameterized queries)
- XSS: Not applicable (Shiny handles escaping)
- CSRF: Protected by Shiny's token system
- Authentication: Add if required

## Debugging

### Enable Debug Mode

```r
options(shiny.trace = TRUE)
shiny::runApp()
```

### Check Logs

```r
# View reactive log
options(shiny.reactlog = TRUE)
shiny::runApp()
# Press Ctrl+F3 in browser
```

### Common Issues

**Issue:** App won't start
- Check R version
- Verify all packages installed
- Check for syntax errors

**Issue:** Can't connect to BigQuery
- Verify credentials path
- Check service account permissions
- Test network connectivity

**Issue:** Charts not displaying
- Check data structure
- Verify column names match
- Look for ggplot2 errors in console

## Continuous Testing

### Before Each Commit
1. Run app in demo mode
2. Check all tabs load
3. Verify no console errors

### Before Each Release
1. Full manual test suite
2. Integration test with BigQuery
3. Security checklist review
4. Performance benchmarks

## Test Data

For testing, use this sample BigQuery table structure:

```sql
CREATE TABLE dataset.cloning_data (
  id INT64,
  clone_name STRING,
  date_created DATE,
  status STRING,
  score FLOAT64
);
```

## Reporting Issues

When reporting bugs, include:
- R version (`R.version`)
- Package versions (`packageVersion("shiny")`, etc.)
- Error messages (full stack trace)
- Steps to reproduce
- Expected vs actual behavior

## Success Criteria

Application passes testing when:
- ✅ All manual test cases pass
- ✅ No errors in console
- ✅ Performance within acceptable range
- ✅ Security checklist complete
- ✅ Documentation accurate
- ✅ Demo mode works
- ✅ BigQuery integration works

---

Last Updated: 2026-01-12
