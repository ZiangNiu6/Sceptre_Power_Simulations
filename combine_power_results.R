#!/usr/bin/env Rscript

# Script to combine power analysis results from all num_trt_* subdirectories
# and compute averaged power with treatment and control cell counts

library(dplyr)
library(readr)

# Get all subdirectories that match the pattern num_trt_* (now in simulation folder)
all_dirs <- list.dirs(path = "simulation", full.names = TRUE, recursive = FALSE)
subdirs <- grep("num_trt_", all_dirs, value = TRUE)

# Initialize empty list to store results
all_results <- list()

# Note: Total cells will be calculated per treatment group as: num_treatment_cells * 5 + 6000

# Loop through each subdirectory
for (subdir in subdirs) {
  # Extract number of treatment cells from directory name
  num_trt <- as.numeric(gsub(".*num_trt_(\\d+).*", "\\1", basename(subdir)))
  
  # Path to power analysis results
  results_file <- file.path(subdir, "results", "test_data", "power_analysis_results.tsv")
  
  if (file.exists(results_file)) {
    message(paste("Reading", results_file))
    
    # Read the results
    results <- read_tsv(results_file, show_col_types = FALSE)
    
    # Calculate total cells for this specific treatment count: num_treatment_cells * 5 + 6000
    total_cells_for_this_trt <- num_trt * 5 + 6000
    
    # Add treatment and control cell columns
    results$num_treatment_cells <- num_trt
    results$num_control_cells <- total_cells_for_this_trt - num_trt
    results$total_cells <- total_cells_for_this_trt
    
    # Store in list
    all_results[[as.character(num_trt)]] <- results
  } else {
    warning(paste("File not found:", results_file))
  }
}

# Combine all results
combined_results <- bind_rows(all_results)

# Compute averaged power across all target-response pairs for each treatment cell count
# This should result in just 8 values (one per treatment cell count)
averaged_results <- combined_results %>%
  group_by(num_treatment_cells, num_control_cells, total_cells, effect_size) %>%
  summarise(
    averaged_power = mean(power, na.rm = TRUE),
    n_observations = n(),
    .groups = "drop"
  ) %>%
  arrange(num_treatment_cells)

# Display summary
message(paste("Total combined observations:", nrow(combined_results)))
message(paste("Total averaged observations:", nrow(averaged_results)))
message(paste("Treatment cell counts analyzed:", paste(sort(unique(averaged_results$num_treatment_cells)), collapse = ", ")))

# Save both datasets as RDS files
saveRDS(combined_results, "combined_power_results.rds")
saveRDS(averaged_results, "averaged_power_results.rds")

message("Results saved to:")
message("- combined_power_results.rds (all individual results)")
message("- averaged_power_results.rds (averaged by treatment cell count)")

# Display first few rows of averaged results
message("\nFirst few rows of averaged results:")
print(head(averaged_results))