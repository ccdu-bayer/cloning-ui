# Cloning UI - RShiny Dashboard

R-based RShiny application to display cloning data from Google Cloud Platform BigQuery.

## Features

- **BigQuery Integration**: Connects to GCP BigQuery to fetch cloning data
- **Interactive Dashboard**: Visual analytics with charts and statistics
- **Data Table View**: Browse and filter data with an interactive table
- **Real-time Updates**: Refresh data on-demand from BigQuery
- **Responsive Design**: Clean and modern dashboard interface

## Prerequisites

- R (version 4.0 or higher recommended)
- GCP Account with BigQuery access
- Service Account JSON key file (for authentication)

## Installation

### 1. Install R Packages

Install the required R packages:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "DT",
  "ggplot2",
  "dplyr",
  "bigrquery"
))
```

### 2. Configure GCP Credentials

1. Copy the example configuration file:
   ```bash
   cp config.example.R config.R
   ```

2. Edit `config.R` with your GCP project details:
   - `GCP_PROJECT_ID`: Your GCP project ID
   - `BQ_DATASET`: Your BigQuery dataset name
   - `BQ_TABLE`: Your BigQuery table name
   - `GCP_KEY_PATH`: Path to your service account JSON key file

3. Download your GCP service account key:
   - Go to GCP Console → IAM & Admin → Service Accounts
   - Create a new service account or use an existing one
   - Grant BigQuery Data Viewer and BigQuery Job User roles
   - Create and download a JSON key file
   - Save it securely and update the path in `config.R`

### 3. Alternative: Environment Variables

Instead of using `config.R`, you can set environment variables:

```bash
export GCP_PROJECT_ID="your-project-id"
export BQ_DATASET="your-dataset-name"
export BQ_TABLE="your-table-name"
export GCP_KEY_PATH="/path/to/service-account-key.json"
```

## Usage

### Running the Application

1. Start the RShiny app:
   ```r
   shiny::runApp()
   ```

2. Or from the command line:
   ```bash
   Rscript -e "shiny::runApp()"
   ```

3. The app will open in your default browser at `http://127.0.0.1:XXXX`

### Dashboard Sections

- **Dashboard**: Overview with key metrics and visualizations
- **Data Table**: Interactive table to browse and filter data
- **Statistics**: Detailed summary statistics and column information
- **About**: Application information and data source details

### Refreshing Data

Click the "Refresh Data" button in the sidebar to fetch the latest data from BigQuery.

## Project Structure

```
cloning-ui/
├── app.R                 # Main RShiny application
├── config.example.R      # Example configuration file
├── config.R             # Your configuration (git-ignored)
├── .gitignore           # Git ignore rules
└── README.md            # This file
```

## Security Notes

- Never commit `config.R` or service account JSON files to version control
- These files are automatically ignored by `.gitignore`
- Store credentials securely and limit access
- Use environment variables in production environments

## Demo Mode

If no configuration is provided, the app will run in demo mode with sample data. This is useful for testing the UI without BigQuery access.

## Troubleshooting

### Authentication Issues

- Ensure your service account has the necessary BigQuery permissions
- Verify the path to your JSON key file is correct
- Check that the JSON key file is valid

### Connection Issues

- Verify your GCP project ID, dataset, and table names are correct
- Ensure your GCP project has billing enabled
- Check network connectivity to GCP services

### Data Issues

- Confirm the BigQuery table exists and has data
- Review the query in `app.R` and adjust if needed
- Check the BigQuery job logs in GCP Console for errors

## Development

### Customizing the Dashboard

Edit `app.R` to:
- Modify the SQL query in `fetch_bigquery_data()`
- Add new visualizations to the UI
- Create additional dashboard tabs
- Customize the color scheme and styling

### Testing

The application includes error handling and will fall back to demo data if BigQuery is unavailable.

## License

This project is part of the cloning-ui repository.
