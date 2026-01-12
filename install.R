#!/usr/bin/env Rscript

# Installation script for Cloning UI RShiny Dashboard
# This script installs all required R packages

cat("========================================\n")
cat("Cloning UI - Package Installation\n")
cat("========================================\n\n")

# List of required packages
required_packages <- c(
  "shiny",
  "shinydashboard",
  "DT",
  "ggplot2",
  "dplyr",
  "bigrquery"
)

# Function to check and install packages
install_if_missing <- function(package_name) {
  if (!require(package_name, character.only = TRUE, quietly = TRUE)) {
    cat(paste0("Installing package: ", package_name, "\n"))
    install.packages(package_name, repos = "https://cran.r-project.org")
    
    # Verify installation
    if (require(package_name, character.only = TRUE, quietly = TRUE)) {
      cat(paste0("✓ Successfully installed: ", package_name, "\n"))
      return(TRUE)
    } else {
      cat(paste0("✗ Failed to install: ", package_name, "\n"))
      return(FALSE)
    }
  } else {
    cat(paste0("✓ Already installed: ", package_name, "\n"))
    return(TRUE)
  }
}

# Install all packages
cat("\nChecking and installing required packages...\n\n")
results <- sapply(required_packages, install_if_missing)

# Summary
cat("\n========================================\n")
cat("Installation Summary\n")
cat("========================================\n")
cat(paste0("Total packages: ", length(required_packages), "\n"))
cat(paste0("Installed: ", sum(results), "\n"))
cat(paste0("Failed: ", sum(!results), "\n"))

if (all(results)) {
  cat("\n✓ All packages installed successfully!\n")
  cat("\nNext steps:\n")
  cat("1. Copy config.example.R to config.R\n")
  cat("2. Edit config.R with your GCP credentials\n")
  cat("3. Run: shiny::runApp()\n\n")
} else {
  cat("\n✗ Some packages failed to install.\n")
  cat("Please install them manually and try again.\n\n")
}
