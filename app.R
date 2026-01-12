# RShiny Application for Cloning Data Dashboard
# This app connects to GCP BigQuery and displays cloning data in an interactive dashboard

library(shiny)
library(shinydashboard)
library(DT)
library(ggplot2)
library(dplyr)
library(bigrquery)

# Load configuration (if config.R exists)
if (file.exists("config.R")) {
  source("config.R")
} else {
  # Default/demo configuration
  GCP_PROJECT_ID <- Sys.getenv("GCP_PROJECT_ID", "demo-project")
  BQ_DATASET <- Sys.getenv("BQ_DATASET", "demo_dataset")
  BQ_TABLE <- Sys.getenv("BQ_TABLE", "cloning_data")
  BQ_BILLING_PROJECT <- Sys.getenv("BQ_BILLING_PROJECT", GCP_PROJECT_ID)
  GCP_KEY_PATH <- Sys.getenv("GCP_KEY_PATH", "")
}

# Function to authenticate with GCP
authenticate_gcp <- function() {
  tryCatch({
    if (file.exists(GCP_KEY_PATH) && GCP_KEY_PATH != "") {
      # Authenticate using service account key
      bigrquery::bq_auth(path = GCP_KEY_PATH)
      return(TRUE)
    } else {
      # Try default authentication or interactive
      bigrquery::bq_auth(use_oob = TRUE)
      return(TRUE)
    }
  }, error = function(e) {
    message("Authentication error: ", e$message)
    return(FALSE)
  })
}

# Function to fetch data from BigQuery
fetch_bigquery_data <- function() {
  tryCatch({
    # Construct the full table reference
    table_ref <- paste0(GCP_PROJECT_ID, ".", BQ_DATASET, ".", BQ_TABLE)
    
    # SQL query to fetch data
    sql <- paste0("SELECT * FROM `", table_ref, "` LIMIT 1000")
    
    # Execute query
    data <- bigrquery::bq_project_query(
      x = BQ_BILLING_PROJECT,
      query = sql
    )
    
    # Download results
    result <- bigrquery::bq_table_download(data)
    
    return(result)
  }, error = function(e) {
    message("Error fetching data: ", e$message)
    # Return demo data if BigQuery fails
    return(data.frame(
      id = 1:10,
      clone_name = paste0("Clone_", 1:10),
      date_created = Sys.Date() - sample(1:100, 10),
      status = sample(c("Active", "Pending", "Completed"), 10, replace = TRUE),
      score = round(runif(10, 50, 100), 2),
      stringsAsFactors = FALSE
    ))
  })
}

# Define UI
ui <- dashboardPage(
  skin = "blue",
  
  # Dashboard Header
  dashboardHeader(
    title = "Cloning Data Dashboard",
    titleWidth = 300
  ),
  
  # Dashboard Sidebar
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Data Table", tabName = "datatable", icon = icon("table")),
      menuItem("Statistics", tabName = "statistics", icon = icon("chart-bar")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    ),
    br(),
    actionButton("refresh_data", "Refresh Data", icon = icon("sync"), 
                 class = "btn-primary", width = "90%", 
                 style = "margin-left: 5%;")
  ),
  
  # Dashboard Body
  dashboardBody(
    tabItems(
      # Dashboard Tab
      tabItem(
        tabName = "dashboard",
        fluidRow(
          valueBoxOutput("total_records"),
          valueBoxOutput("active_clones"),
          valueBoxOutput("avg_score")
        ),
        fluidRow(
          box(
            title = "Cloning Activity Over Time",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotOutput("timeline_plot", height = 300)
          )
        ),
        fluidRow(
          box(
            title = "Status Distribution",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotOutput("status_plot", height = 300)
          ),
          box(
            title = "Score Distribution",
            status = "success",
            solidHeader = TRUE,
            width = 6,
            plotOutput("score_plot", height = 300)
          )
        )
      ),
      
      # Data Table Tab
      tabItem(
        tabName = "datatable",
        fluidRow(
          box(
            title = "Cloning Data",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("data_table")
          )
        )
      ),
      
      # Statistics Tab
      tabItem(
        tabName = "statistics",
        fluidRow(
          box(
            title = "Data Summary",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            verbatimTextOutput("data_summary")
          )
        ),
        fluidRow(
          box(
            title = "Column Statistics",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            tableOutput("column_stats")
          )
        )
      ),
      
      # About Tab
      tabItem(
        tabName = "about",
        fluidRow(
          box(
            title = "About This Dashboard",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            h4("Cloning Data Dashboard"),
            p("This RShiny application connects to Google Cloud Platform BigQuery 
               to retrieve and display cloning data in an interactive dashboard."),
            h4("Features:"),
            tags$ul(
              tags$li("Real-time data fetching from BigQuery"),
              tags$li("Interactive data tables with search and filter capabilities"),
              tags$li("Visual analytics and statistics"),
              tags$li("Responsive dashboard design")
            ),
            h4("Data Source:"),
            p(paste0("Project: ", GCP_PROJECT_ID)),
            p(paste0("Dataset: ", BQ_DATASET)),
            p(paste0("Table: ", BQ_TABLE)),
            h4("Last Updated:"),
            textOutput("last_update")
          )
        )
      )
    )
  )
)

# Define Server Logic
server <- function(input, output, session) {
  
  # Reactive value to store data
  data_store <- reactiveValues(
    data = NULL,
    last_update = NULL,
    auth_status = FALSE
  )
  
  # Authenticate on app start
  observe({
    data_store$auth_status <- authenticate_gcp()
  })
  
  # Load data on app start
  observeEvent(TRUE, {
    withProgress(message = 'Loading data from BigQuery...', value = 0, {
      incProgress(0.5)
      data_store$data <- fetch_bigquery_data()
      data_store$last_update <- Sys.time()
      incProgress(1)
    })
  }, once = TRUE)
  
  # Refresh data when button is clicked
  observeEvent(input$refresh_data, {
    withProgress(message = 'Refreshing data from BigQuery...', value = 0, {
      incProgress(0.5)
      data_store$data <- fetch_bigquery_data()
      data_store$last_update <- Sys.time()
      incProgress(1)
    })
    showNotification("Data refreshed successfully!", type = "message")
  })
  
  # Value boxes
  output$total_records <- renderValueBox({
    req(data_store$data)
    valueBox(
      nrow(data_store$data),
      "Total Records",
      icon = icon("database"),
      color = "blue"
    )
  })
  
  output$active_clones <- renderValueBox({
    req(data_store$data)
    data <- data_store$data
    active_count <- if("status" %in% names(data)) {
      sum(data$status == "Active", na.rm = TRUE)
    } else {
      "N/A"
    }
    valueBox(
      active_count,
      "Active Clones",
      icon = icon("check-circle"),
      color = "green"
    )
  })
  
  output$avg_score <- renderValueBox({
    req(data_store$data)
    data <- data_store$data
    avg <- if("score" %in% names(data)) {
      round(mean(data$score, na.rm = TRUE), 2)
    } else {
      "N/A"
    }
    valueBox(
      avg,
      "Average Score",
      icon = icon("star"),
      color = "yellow"
    )
  })
  
  # Timeline plot
  output$timeline_plot <- renderPlot({
    req(data_store$data)
    data <- data_store$data
    
    if("date_created" %in% names(data)) {
      data %>%
        mutate(date = as.Date(date_created)) %>%
        count(date) %>%
        ggplot(aes(x = date, y = n)) +
        geom_line(color = "#3c8dbc", size = 1.2) +
        geom_point(color = "#3c8dbc", size = 2) +
        theme_minimal() +
        labs(title = "", x = "Date", y = "Number of Clones") +
        theme(text = element_text(size = 12))
    } else {
      ggplot() + 
        annotate("text", x = 0.5, y = 0.5, 
                label = "No date column available", size = 6) +
        theme_void()
    }
  })
  
  # Status distribution plot
  output$status_plot <- renderPlot({
    req(data_store$data)
    data <- data_store$data
    
    if("status" %in% names(data)) {
      data %>%
        count(status) %>%
        ggplot(aes(x = status, y = n, fill = status)) +
        geom_bar(stat = "identity") +
        theme_minimal() +
        labs(title = "", x = "Status", y = "Count") +
        theme(legend.position = "none", text = element_text(size = 12))
    } else {
      ggplot() + 
        annotate("text", x = 0.5, y = 0.5, 
                label = "No status column available", size = 6) +
        theme_void()
    }
  })
  
  # Score distribution plot
  output$score_plot <- renderPlot({
    req(data_store$data)
    data <- data_store$data
    
    if("score" %in% names(data)) {
      ggplot(data, aes(x = score)) +
        geom_histogram(binwidth = 5, fill = "#00a65a", color = "white") +
        theme_minimal() +
        labs(title = "", x = "Score", y = "Frequency") +
        theme(text = element_text(size = 12))
    } else {
      ggplot() + 
        annotate("text", x = 0.5, y = 0.5, 
                label = "No score column available", size = 6) +
        theme_void()
    }
  })
  
  # Data table
  output$data_table <- renderDT({
    req(data_store$data)
    datatable(
      data_store$data,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        searchHighlight = TRUE
      ),
      filter = "top",
      rownames = FALSE
    )
  })
  
  # Data summary
  output$data_summary <- renderPrint({
    req(data_store$data)
    summary(data_store$data)
  })
  
  # Column statistics
  output$column_stats <- renderTable({
    req(data_store$data)
    data <- data_store$data
    
    stats <- data.frame(
      Column = names(data),
      Type = sapply(data, class),
      Missing = sapply(data, function(x) sum(is.na(x))),
      Unique = sapply(data, function(x) length(unique(x))),
      stringsAsFactors = FALSE
    )
    rownames(stats) <- NULL
    stats
  })
  
  # Last update time
  output$last_update <- renderText({
    req(data_store$last_update)
    format(data_store$last_update, "%Y-%m-%d %H:%M:%S")
  })
}

# Run the application
shinyApp(ui = ui, server = server)
