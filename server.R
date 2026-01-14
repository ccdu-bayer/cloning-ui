server <- function(input, output, session) {
  
  # Reactive values
  rv <- reactiveValues(
    all_sets = NULL,
    filtered_data = NULL,
    summary_stats = NULL,
    filter_options_loaded = FALSE
  )
  
  # ============================================================
  # STEP 1: Load ONLY parent table on startup (fast!)
  # ============================================================
  observe({
    
    cat("\n=== Loading Parent Table (Sets) ===\n")
    
    showModal(modalDialog(
      title = "Loading Application",
      "Loading set rearray list...",
      footer = NULL,
      easyClose = FALSE
    ))
    
    tryCatch({
      # Load ALL sets (only 4,865 rows - fast!)
      rv$all_sets <- get_all_sets(project_id, BQ_DATASET_ID)
      cat(sprintf("✓ Loaded %s sets\n", nrow(rv$all_sets)))
      
      # Populate set filter
      updateSelectInput(
        session, 
        "set_rearray",
        choices = setNames(rv$all_sets$sel_list_id, rv$all_sets$set_rearray_name)
      )
      
      rv$filter_options_loaded <- TRUE
      
      removeModal()
      
      showNotification(
        HTML("<b>Ready!</b><br/>
             1. Select one or more sets<br/>
             2. Source and Clone filters will load automatically<br/>
             3. Click 'Apply Filters' to view data"),
        type = "message",
        duration = 10
      )
      
      cat("=== Ready! ===\n\n")
      
    }, error = function(e) {
      cat(sprintf("✗ ERROR: %s\n", e$message))
      removeModal()
      showModal(modalDialog(
        title = "Error",
        paste("Failed to load sets:", e$message),
        footer = modalButton("Close"),
        easyClose = TRUE
      ))
    })
  })
  
  # ============================================================
  # STEP 2: When user selects sets, load child filters
  # ============================================================
  observeEvent(input$set_rearray, {
    
    req(rv$filter_options_loaded)
    
    selected_sets <- input$set_rearray
    
    if (is.null(selected_sets) || length(selected_sets) == 0) {
      # Clear child filters when no sets selected
      updateSelectInput(session, "source_id", choices = character(0))
      updateSelectInput(session, "clone_id", choices = character(0))
      cat("No sets selected - child filters cleared\n")
      return()
    }
    
    cat(sprintf("\n=== Loading child filters for %s selected set(s) ===\n", length(selected_sets)))
    
    showNotification(
      "Loading source and clone options for selected sets...",
      id = "loading_child",
      duration = NULL,
      type = "message"
    )
    
    tryCatch({
      # Load sources for selected sets
      cat("Loading sources...\n")
      sources <- get_source_ids_for_sets(project_id, BQ_DATASET_ID, selected_sets)
      cat(sprintf("  ✓ Found %s unique sources\n", nrow(sources)))
      
      updateSelectInput(session, "source_id", 
                        choices = sources$src_id,
                        selected = character(0))
      
      # Load clones for selected sets
      cat("Loading clones...\n")
      clones <- get_clone_ids_for_sets(project_id, BQ_DATASET_ID, selected_sets)
      cat(sprintf("  ✓ Found %s unique clones\n", nrow(clones)))
      
      updateSelectInput(session, "clone_id", 
                        choices = clones$clone_id,
                        selected = character(0))
      
      removeNotification("loading_child")
      
      showNotification(
        sprintf("✓ Loaded %s sources and %s clones", 
                nrow(sources), nrow(clones)),
        type = "message",
        duration = 3
      )
      
      cat("=== Child filters loaded ===\n\n")
      
    }, error = function(e) {
      cat(sprintf("✗ ERROR: %s\n", e$message))
      removeNotification("loading_child")
      showNotification(
        paste("Error loading child filters:", e$message),
        type = "warning",
        duration = 5
      )
    })
    
  }, ignoreInit = TRUE, ignoreNULL = FALSE)
  
  # ============================================================
  # STEP 3: Apply filters and load data
  # ============================================================
  observeEvent(input$apply_filters, {
    
    req(rv$filter_options_loaded)
    
    if (is.null(input$set_rearray) || length(input$set_rearray) == 0) {
      showNotification(
        "Please select at least one set first!",
        type = "warning",
        duration = 5
      )
      return()
    }
    
    cat("\n=== Applying Filters and Loading Data ===\n")
    
    withProgress(message = 'Loading data...', value = 0, {
      
      tryCatch({
        
        incProgress(0.3, detail = "Fetching records...")
        
        cat(sprintf("Filters: Sets=%s, Sources=%s, Clones=%s\n",
                    length(input$set_rearray), 
                    length(input$source_id), 
                    length(input$clone_id)))
        
        # Get filtered data
        rv$filtered_data <- get_filtered_data(
          project_id, 
          BQ_DATASET_ID,
          set_ids = input$set_rearray,
          src_ids = if(length(input$source_id) > 0) input$source_id else NULL,
          clone_ids = if(length(input$clone_id) > 0) input$clone_id else NULL
        )
        
        cat(sprintf("  ✓ Retrieved %s records\n", nrow(rv$filtered_data)))
        
        incProgress(0.7, detail = "Calculating statistics...")
        
        # Get summary stats
        rv$summary_stats <- get_summary_stats(
          project_id, 
          BQ_DATASET_ID,
          set_ids = input$set_rearray,
          src_ids = if(length(input$source_id) > 0) input$source_id else NULL,
          clone_ids = if(length(input$clone_id) > 0) input$clone_id else NULL
        )
        
        cat("  ✓ Statistics calculated\n")
        
        incProgress(1, detail = "Complete!")
        
        showNotification(
          sprintf("✓ Loaded %s records", format(nrow(rv$filtered_data), big.mark = ",")),
          type = "message",
          duration = 3
        )
        
        cat("=== Data Load Complete ===\n\n")
        
      }, error = function(e) {
        cat(sprintf("✗ ERROR: %s\n", e$message))
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
  })
  
  # Reset filters
  observeEvent(input$reset_filters, {
    updateSelectInput(session, "set_rearray", selected = character(0))
    updateSelectInput(session, "source_id", selected = character(0))
    updateSelectInput(session, "clone_id", selected = character(0))
    
    rv$filtered_data <- NULL
    rv$summary_stats <- NULL
    
    showNotification("Filters reset!", type = "message", duration = 2)
  })
  
  # Refresh - reload everything
  observeEvent(input$refresh_data, {
    session$reload()
  })
  
  # manually added: # Select All / Clear buttons for Sets
  observeEvent(input$select_all_sets, {
    req(rv$all_sets)
    updateSelectInput(session, "set_rearray", 
                      selected = rv$all_sets$sel_list_id)
  })
  
  observeEvent(input$clear_sets, {
    updateSelectInput(session, "set_rearray", selected = character(0))
  })
  
  # Select All / Clear buttons for Sources
  observeEvent(input$select_all_sources, {
    choices <- isolate(input$source_id)
    all_choices <- names(isolate(session$clientData$output_source_id_choices))
    if (is.null(all_choices)) {
      # Get from selectize directly
      all_choices <- getSelectizeOptions(session, "source_id")
    }
    updateSelectInput(session, "source_id", selected = all_choices)
  })
  
  observeEvent(input$clear_sources, {
    updateSelectInput(session, "source_id", selected = character(0))
  })
  
  # Select All / Clear buttons for Clones
  observeEvent(input$select_all_clones, {
    choices <- isolate(input$clone_id)
    all_choices <- names(isolate(session$clientData$output_clone_id_choices))
    if (is.null(all_choices)) {
      all_choices <- getSelectizeOptions(session, "clone_id")
    }
    updateSelectInput(session, "clone_id", selected = all_choices)
  })
  
  observeEvent(input$clear_clones, {
    updateSelectInput(session, "clone_id", selected = character(0))
  })
  
  # Helper function to get selectize options
  getSelectizeOptions <- function(session, inputId) {
    # This is a workaround - store choices in reactive value when updating
    return(character(0))
  }
  #end of manually added
  
  # ============================================================
  # VALUE BOXES
  # ============================================================
  
  output$total_sets <- renderValueBox({
    req(rv$summary_stats)
    valueBox(
      format(rv$summary_stats$total_sets, big.mark = ","),
      "Total Sets",
      icon = icon("layer-group"),
      color = "blue"
    )
  })
  
  output$total_sources <- renderValueBox({
    req(rv$summary_stats)
    valueBox(
      format(rv$summary_stats$total_sources, big.mark = ","),
      "Total Sources",
      icon = icon("database"),
      color = "green"
    )
  })
  
  output$total_clones <- renderValueBox({
    req(rv$summary_stats)
    valueBox(
      format(rv$summary_stats$total_clones, big.mark = ","),
      "Total Clones",
      icon = icon("copy"),
      color = "yellow"
    )
  })
  
  output$total_records <- renderValueBox({
    req(rv$summary_stats)
    valueBox(
      format(rv$summary_stats$total_records, big.mark = ","),
      "Total Records",
      icon = icon("list"),
      color = "red"
    )
  })
  # manually added:
  # Display current filter summary
  output$filter_summary <- renderUI({
    sets_selected <- length(input$set_rearray)
    sources_selected <- length(input$source_id)
    clones_selected <- length(input$clone_id)
    
    if (sets_selected == 0) {
      return(tags$p(
        tags$i(class = "fa fa-info-circle"),
        " Please select at least one set to begin."
      ))
    }
    
    tags$div(
      tags$p(
        tags$strong("Sets: "), 
        if(sets_selected > 0) paste(sets_selected, "selected") else "All",
        tags$span(style = "margin-left: 20px;"),
        tags$strong("Sources: "), 
        if(sources_selected > 0) paste(sources_selected, "selected") else "All available",
        tags$span(style = "margin-left: 20px;"),
        tags$strong("Clones: "), 
        if(clones_selected > 0) paste(clones_selected, "selected") else "All available"
      ),
      if (!is.null(rv$filtered_data)) {
        tags$p(
          tags$i(class = "fa fa-check-circle", style = "color: green;"),
          " Last loaded: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
          " | Records: ", format(nrow(rv$filtered_data), big.mark = ",")
        )
      }
    )
  }) # end of manually added
  # ============================================================
  # CHARTS
  # ============================================================
  
  output$clones_by_set_chart <- renderPlotly({
    req(rv$filtered_data)
    
    chart_data <- get_clones_by_set(
      project_id, BQ_DATASET_ID,
      set_ids = input$set_rearray,
      src_ids = if(length(input$source_id) > 0) input$source_id else NULL,
      clone_ids = if(length(input$clone_id) > 0) input$clone_id else NULL
    )
    
    if (nrow(chart_data) == 0) {
      return(plotly_empty(type = "bar") %>% layout(title = "No data available"))
    }
    
    plot_ly(chart_data, x = ~set_rearray_name, y = ~clone_count, type = 'bar',
            name = 'Clones', marker = list(color = '#3c8dbc')) %>%
      add_trace(y = ~source_count, name = 'Sources', marker = list(color = '#00a65a')) %>%
      layout(
        xaxis = list(title = "Set Rearray Name", tickangle = -45),
        yaxis = list(title = "Count"),
        barmode = 'group',
        hovermode = 'closest'
      )
  })
  
  output$source_clone_chart <- renderPlotly({
    req(rv$filtered_data)
    
    chart_data <- get_source_clone_mapping(
      project_id, BQ_DATASET_ID,
      set_ids = input$set_rearray
    )
    
    if (nrow(chart_data) == 0) {
      return(plotly_empty(type = "bar") %>% layout(title = "No data available"))
    }
    
    plot_ly(chart_data, x = ~reorder(src_id, clone_count), y = ~clone_count, 
            type = 'bar', marker = list(color = '#f39c12')) %>%
      layout(
        xaxis = list(title = "Source ID", tickangle = -45),
        yaxis = list(title = "Number of Clones"),
        hovermode = 'closest'
      )
  })
  
  output$set_summary_chart <- renderPlotly({
    req(rv$filtered_data)
    
    summary_data <- rv$filtered_data %>%
      filter(!is.na(set_rearray_name)) %>%
      group_by(set_rearray_name) %>%
      summarise(count = n(), .groups = 'drop')
    
    if (nrow(summary_data) == 0) {
      return(plotly_empty(type = "pie") %>% layout(title = "No data available"))
    }
    
    plot_ly(summary_data, labels = ~set_rearray_name, values = ~count, type = 'pie') %>%
      layout(title = "Records Distribution by Set")
  })
  
  output$scatter_analysis <- renderPlotly({
    req(rv$filtered_data)
    
    scatter_data <- rv$filtered_data %>%
      filter(!is.na(src_id), !is.na(set_rearray_name)) %>%
      group_by(set_rearray_name, src_id) %>%
      summarise(clone_count = n_distinct(clone_id), .groups = 'drop')
    
    if (nrow(scatter_data) == 0) {
      return(plotly_empty(type = "scatter") %>% layout(title = "No data available"))
    }
    
    plot_ly(scatter_data, x = ~src_id, y = ~clone_count, 
            color = ~set_rearray_name, type = 'scatter', mode = 'markers',
            marker = list(size = 10, opacity = 0.7)) %>%
      layout(
        title = "Source vs Clone Count by Set",
        xaxis = list(title = "Source ID"),
        yaxis = list(title = "Number of Clones"),
        hovermode = 'closest'
      )
  })
  
  output$source_distribution <- renderPlotly({
    req(rv$filtered_data)
    
    source_dist <- rv$filtered_data %>%
      filter(!is.na(src_id)) %>%
      group_by(src_id) %>%
      summarise(count = n(), .groups = 'drop') %>%
      arrange(desc(count)) %>%
      head(20)
    
    if (nrow(source_dist) == 0) {
      return(plotly_empty(type = "bar") %>% layout(title = "No data available"))
    }
    
    plot_ly(source_dist, x = ~reorder(src_id, count), y = ~count, 
            type = 'bar', marker = list(color = '#dd4b39')) %>%
      layout(
        xaxis = list(title = "Source ID", tickangle = -45),
        yaxis = list(title = "Frequency"),
        hovermode = 'closest'
      )
  })
  
  output$clone_distribution <- renderPlotly({
    req(rv$filtered_data)
    
    clone_dist <- rv$filtered_data %>%
      filter(!is.na(clone_id)) %>%
      group_by(clone_id) %>%
      summarise(count = n(), .groups = 'drop') %>%
      arrange(desc(count)) %>%
      head(20)
    
    if (nrow(clone_dist) == 0) {
      return(plotly_empty(type = "bar") %>% layout(title = "No data available"))
    }
    
    plot_ly(clone_dist, x = ~reorder(clone_id, count), y = ~count, 
            type = 'bar', marker = list(color = '#00c0ef')) %>%
      layout(
        xaxis = list(title = "Clone ID", tickangle = -45),
        yaxis = list(title = "Frequency"),
        hovermode = 'closest'
      )
  })
  
  # ============================================================
  # TABLES
  # ============================================================
  
  output$parent_table <- renderDT({
    req(rv$all_sets)
    
    datatable(
      rv$all_sets,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons',
      filter = 'top',
      rownames = FALSE,
      colnames = c('Sel List ID', 'Set Rearray Name')
    )
  })
  
  output$child_table <- renderDT({
    req(rv$filtered_data)
    
    datatable(
      rv$filtered_data,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      extensions = 'Buttons',
      filter = 'top',
      rownames = FALSE,
      colnames = c('Sel List ID', 'Set Rearray Name', 'Child Sel List ID', 'Source ID', 'Clone ID')
    )
  })
  
  # Download filtered data
  output$download_full_data <- downloadHandler(
    filename = function() {
      paste0("set_rearray_filtered_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(rv$filtered_data)
      write.csv(rv$filtered_data, file, row.names = FALSE)
    }
  )
  
  # Download summary statistics
  output$download_summary <- downloadHandler(
    filename = function() {
      paste0("set_rearray_summary_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(rv$summary_stats, rv$filtered_data)
      
      # Create detailed summary
      summary_df <- data.frame(
        Metric = c("Total Sets", "Total Sources", "Total Clones", "Total Records",
                   "Sets Selected", "Sources Selected", "Clones Selected",
                   "Export Date", "Export Time"),
        Value = c(
          rv$summary_stats$total_sets,
          rv$summary_stats$total_sources,
          rv$summary_stats$total_clones,
          rv$summary_stats$total_records,
          length(input$set_rearray),
          length(input$source_id),
          length(input$clone_id),
          as.character(Sys.Date()),
          format(Sys.time(), "%H:%M:%S")
        )
      )
      
      write.csv(summary_df, file, row.names = FALSE)
    }
  )
  
  # Download parent table
  output$download_parent <- downloadHandler(
    filename = function() {
      paste0("set_rearray_parent_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(rv$all_sets)
      write.csv(rv$all_sets, file, row.names = FALSE)
    }
  )
}