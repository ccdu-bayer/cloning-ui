# Clone Selection View Dashboard

Shiny dashboard for viewing selected clone data for rearray from BigQuery.

## Features
- Interactive filtering by set, source, and clone
- Real-time data visualization
- Export capabilities (CSV, Excel)
- Role-based access control

## Local Development Setup

### Prerequisites
- R 4.2+
- RStudio
- GCP service account with BigQuery access

### Installation

1. Clone the repository:
```bash
git clone https://github.com/ccdu-bayer/clone-selection-viewer.git
cd clone-selection-viewer

# Clone Selection Viewer

R-based Shiny application to display selected clone data from Google Cloud BigQuery.

## Quick Start

### Prerequisites
- R (>= 4.5.1)
- RStudio Desktop
- Google Cloud Platform account with BigQuery access
- GCP service account key file (JSON) for local develop/test
- Vault account and its credentials

### Setup

1. **Open the project in RStudio**
   - Open `clone-selection-viewer.Rproj` in RStudio

2. **Install dependencies**
   ```r
   renv::restore()
   ```

3. **Configure GCP credentials**
   - Copy `.Renviron.template` to `.Renviron`
   - Update with your GCP project details and service account key path
   - If developing in local for DEV mode, set the 
   - Restart RStudio

4. **Test connection to BigQuery**
   ```r
   source("test_bigquery_connection.R")
   ```

5. **Run the app**
   ```r
   shiny::runApp()
   ```

## Documentation
 

## Project Structure

- `app.R` - Main Shiny application
- `config.yml` - Application configuration
- `renv.lock` - R package dependencies
- `.Renviron.template` - Environment variable template
- `test_bigquery_connection.R` - Connection testing script

## Features

- Interactive dashboard for cloning data visualization
- Direct connection to Google BigQuery
- Configurable environments (development, production)
- Secure credential management
- Reproducible package management with renv

## Technology Stack

- **R 4.3.2+** - Programming language
- **Shiny** - Web application framework
- **shinydashboard** - Dashboard components
- **bigrquery** - BigQuery interface
- **DT** - Interactive tables
- **plotly** - Interactive visualizations
- **renv** - Dependency management

## License

[Add your license here]
