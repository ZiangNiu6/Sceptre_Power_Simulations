#!/usr/bin/env Rscript

# Script to validate and display timing data

library(dplyr)

# Read timing data
timing_data <- readRDS("simulation_timing_data.rds")

message("=== SIMULATION TIMING DATA VALIDATION ===")
message(paste("Total records:", nrow(timing_data)))
message(paste("Columns:", ncol(timing_data)))

message("\nColumn names:")
print(colnames(timing_data))

message("\nComplete timing data:")
print(timing_data)

message("\n=== TIMING ANALYSIS ===")
message("Summary statistics:")
summary_stats <- timing_data %>%
  summarise(
    min_duration_hours = min(duration_hours, na.rm = TRUE),
    max_duration_hours = max(duration_hours, na.rm = TRUE),
    mean_duration_hours = mean(duration_hours, na.rm = TRUE),
    median_duration_hours = median(duration_hours, na.rm = TRUE),
    sd_duration_hours = sd(duration_hours, na.rm = TRUE)
  )
print(summary_stats)

message("\nTiming by effect size:")
timing_by_effect <- timing_data %>%
  select(effect_size, duration_hours, duration_formatted, status) %>%
  arrange(effect_size)
print(timing_by_effect)

message("\n=== POTENTIAL OUTLIERS ===")
# Check for any unusually long or short runs
mean_duration <- mean(timing_data$duration_hours, na.rm = TRUE)
sd_duration <- sd(timing_data$duration_hours, na.rm = TRUE)
outliers <- timing_data %>%
  filter(abs(duration_hours - mean_duration) > 2 * sd_duration) %>%
  select(simulation_directory, effect_size, duration_hours, duration_formatted, status)

if (nrow(outliers) > 0) {
  message("Found potential outliers (>2 SD from mean):")
  print(outliers)
} else {
  message("No significant outliers detected.")
}