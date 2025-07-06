#!/usr/bin/env Rscript

# Script to validate and display structure of the generated RDS files

library(dplyr)

# Read the averaged results
averaged_results <- readRDS("averaged_power_results.rds")
combined_results <- readRDS("combined_power_results.rds")

message("=== AVERAGED POWER RESULTS ===")
message(paste("Dimensions:", nrow(averaged_results), "rows x", ncol(averaged_results), "columns"))
message("\nColumn names:")
print(colnames(averaged_results))

message("\nSummary by treatment cell count:")
summary_by_treatment <- averaged_results %>%
  group_by(num_treatment_cells, num_control_cells) %>%
  summarise(
    n_observations = n(),
    mean_power = mean(averaged_power, na.rm = TRUE),
    median_power = median(averaged_power, na.rm = TRUE),
    .groups = "drop"
  )
print(summary_by_treatment)

message("\n=== COMBINED POWER RESULTS ===")
message(paste("Dimensions:", nrow(combined_results), "rows x", ncol(combined_results), "columns"))
message("\nColumn names:")
print(colnames(combined_results))

message("\nAll averaged results:")
print(averaged_results)