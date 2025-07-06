#!/usr/bin/env Rscript

# Script to extract simulation timing information from simulation_timing.log files

library(dplyr)
library(stringr)

# Function to parse timing log file
parse_timing_log <- function(log_file) {
  if (!file.exists(log_file)) {
    return(NULL)
  }
  
  # Read the log file
  lines <- readLines(log_file, warn = FALSE)
  
  # Initialize result list
  result <- list()
  
  # Extract information using regex patterns
  for (line in lines) {
    if (grepl("^Effect size:", line)) {
      result$effect_size <- as.numeric(str_extract(line, "[0-9.]+"))
    } else if (grepl("^Cell count:", line)) {
      cell_count_match <- str_extract(line, "[0-9]+")
      result$cell_count <- as.numeric(cell_count_match)
    } else if (grepl("^Start time:", line)) {
      result$start_time <- str_trim(gsub("^Start time:", "", line))
    } else if (grepl("^Start timestamp:", line)) {
      result$start_timestamp <- as.numeric(str_extract(line, "[0-9]+"))
    } else if (grepl("^End time:", line)) {
      result$end_time <- str_trim(gsub("^End time:", "", line))
    } else if (grepl("^End timestamp:", line)) {
      result$end_timestamp <- as.numeric(str_extract(line, "[0-9]+"))
    } else if (grepl("^Duration:", line)) {
      result$duration_formatted <- str_trim(gsub("^Duration:", "", line))
    } else if (grepl("^Total seconds:", line)) {
      result$total_seconds <- as.numeric(str_extract(line, "[0-9]+"))
    } else if (grepl("^Status:", line)) {
      result$status <- str_trim(gsub("^Status:", "", line))
    }
  }
  
  return(result)
}

# Function to extract simulation type from directory path
extract_simulation_type <- function(dir_path) {
  dirname <- basename(dir_path)
  
  if (grepl("^num_trt_", dirname)) {
    num_trt <- as.numeric(gsub("num_trt_(\\d+)", "\\1", dirname))
    return(list(simulation_type = "num_trt", parameter_value = num_trt, parameter_name = "num_treatment_cells"))
  } else if (grepl("^effect_size_", dirname)) {
    effect_size <- as.numeric(gsub("effect_size_(\\d+\\.\\d+)", "\\1", dirname))
    return(list(simulation_type = "effect_size", parameter_value = effect_size, parameter_name = "effect_size"))
  } else {
    return(list(simulation_type = "unknown", parameter_value = NA, parameter_name = NA))
  }
}

# Get all simulation directories
all_dirs <- list.dirs(path = "simulation", full.names = TRUE, recursive = FALSE)

# Initialize empty list to store timing data
timing_data <- list()

# Process each simulation directory
for (sim_dir in all_dirs) {
  # Check for timing log file
  timing_log_file <- file.path(sim_dir, "simulation_timing.log")
  
  if (file.exists(timing_log_file)) {
    message(paste("Processing timing log:", timing_log_file))
    
    # Parse timing information
    timing_info <- parse_timing_log(timing_log_file)
    
    if (!is.null(timing_info)) {
      # Extract simulation type and parameters
      sim_info <- extract_simulation_type(sim_dir)
      
      # Combine timing and simulation information
      combined_info <- c(timing_info, sim_info)
      combined_info$simulation_directory <- basename(sim_dir)
      
      # Add to timing data list
      timing_data[[basename(sim_dir)]] <- combined_info
    }
  } else {
    message(paste("No timing log found for:", sim_dir))
  }
}

# Convert to data frame
if (length(timing_data) > 0) {
  # Convert list to data frame
  timing_df <- do.call(rbind, lapply(timing_data, function(x) {
    data.frame(
      simulation_directory = x$simulation_directory %||% NA,
      simulation_type = x$simulation_type %||% NA,
      parameter_name = x$parameter_name %||% NA,
      parameter_value = x$parameter_value %||% NA,
      effect_size = x$effect_size %||% NA,
      cell_count = x$cell_count %||% NA,
      start_time = x$start_time %||% NA,
      start_timestamp = x$start_timestamp %||% NA,
      end_time = x$end_time %||% NA,
      end_timestamp = x$end_timestamp %||% NA,
      duration_formatted = x$duration_formatted %||% NA,
      total_seconds = x$total_seconds %||% NA,
      status = x$status %||% NA,
      stringsAsFactors = FALSE
    )
  }))
  
  # Add computed columns
  timing_df <- timing_df %>%
    mutate(
      duration_hours = total_seconds / 3600,
      duration_minutes = total_seconds / 60,
      start_datetime = as.POSIXct(start_timestamp, origin = "1970-01-01"),
      end_datetime = as.POSIXct(end_timestamp, origin = "1970-01-01")
    ) %>%
    arrange(simulation_type, parameter_value)
  
  # Display summary
  message("\n=== TIMING ANALYSIS SUMMARY ===")
  message(paste("Total simulations with timing data:", nrow(timing_df)))
  message(paste("Simulation types:", paste(unique(timing_df$simulation_type), collapse = ", ")))
  
  # Summary by simulation type
  if (nrow(timing_df) > 0) {
    summary_stats <- timing_df %>%
      group_by(simulation_type) %>%
      summarise(
        count = n(),
        min_hours = min(duration_hours, na.rm = TRUE),
        max_hours = max(duration_hours, na.rm = TRUE),
        mean_hours = mean(duration_hours, na.rm = TRUE),
        median_hours = median(duration_hours, na.rm = TRUE),
        .groups = "drop"
      )
    
    message("\nTiming statistics by simulation type:")
    print(summary_stats)
  }
  
  # Save timing data
  saveRDS(timing_df, "simulation_timing_data.rds")
  message("\nTiming data saved to: simulation_timing_data.rds")
  
  # Display first few rows
  message("\nFirst few rows of timing data:")
  print(head(timing_df %>% select(simulation_directory, parameter_value, duration_formatted, duration_hours, status)))
  
} else {
  message("No timing data found in any simulation directories!")
}

# Helper function for null coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x