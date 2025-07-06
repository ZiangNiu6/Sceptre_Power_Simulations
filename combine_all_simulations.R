#!/usr/bin/env Rscript

# Script to combine power analysis results from both num_trt and effect_size simulations
# and compute averaged power with treatment and control cell counts

library(dplyr)
library(readr)

# Function to extract simulation parameters from directory name
extract_sim_params <- function(subdir) {
  dirname <- basename(subdir)
  
  if (grepl("^num_trt_", dirname)) {
    num_trt <- as.numeric(gsub("num_trt_(\\d+)", "\\1", dirname))
    effect_size <- NA  # Will be read from the data
    sim_type <- "num_trt"
    return(list(num_trt = num_trt, effect_size = effect_size, sim_type = sim_type))
  } else if (grepl("^effect_size_", dirname)) {
    effect_size <- as.numeric(gsub("effect_size_(\\d+\\.\\d+)", "\\1", dirname))
    num_trt <- NA  # Will be read from the data
    sim_type <- "effect_size"
    return(list(num_trt = num_trt, effect_size = effect_size, sim_type = sim_type))
  } else {
    return(NULL)
  }
}

# Get all simulation subdirectories
all_dirs <- list.dirs(path = "simulation", full.names = TRUE, recursive = FALSE)
num_trt_dirs <- grep("num_trt_", all_dirs, value = TRUE)
effect_size_dirs <- grep("effect_size_", all_dirs, value = TRUE)

# Combine all simulation directories
all_sim_dirs <- c(num_trt_dirs, effect_size_dirs)

message(paste("Found", length(num_trt_dirs), "num_trt simulations"))
message(paste("Found", length(effect_size_dirs), "effect_size simulations"))

# Initialize empty list to store results
all_results <- list()

# Loop through each simulation directory
for (subdir in all_sim_dirs) {
  # Extract simulation parameters
  sim_params <- extract_sim_params(subdir)
  if (is.null(sim_params)) next
  
  # Path to power analysis results
  results_file <- file.path(subdir, "results", "test_data", "power_analysis_results.tsv")
  
  if (file.exists(results_file)) {
    message(paste("Reading", results_file))
    
    # Read the results
    results <- read_tsv(results_file, show_col_types = FALSE)
    
    # Add simulation parameters
    results$simulation_type <- sim_params$sim_type
    
    if (sim_params$sim_type == "num_trt") {
      # For num_trt simulations, use the directory name for treatment cells
      num_trt <- sim_params$num_trt
      total_cells_for_this_trt <- num_trt * 5 + 6000
      
      results$num_treatment_cells <- num_trt
      results$num_control_cells <- total_cells_for_this_trt - num_trt
      results$total_cells <- total_cells_for_this_trt
      results$simulation_effect_size <- results$effect_size  # From data
      
    } else if (sim_params$sim_type == "effect_size") {
      # For effect_size simulations, use the directory name for effect size
      # and read treatment cells from the data
      results$simulation_effect_size <- sim_params$effect_size
      
      # Calculate treatment/control cells from mean_pert_cells in data
      num_trt <- round(mean(results$mean_pert_cells, na.rm = TRUE))
      total_cells_for_this_trt <- num_trt * 5 + 6000
      
      results$num_treatment_cells <- num_trt
      results$num_control_cells <- total_cells_for_this_trt - num_trt
      results$total_cells <- total_cells_for_this_trt
    }
    
    # Store in list
    sim_key <- paste(sim_params$sim_type, 
                     ifelse(sim_params$sim_type == "num_trt", sim_params$num_trt, sim_params$effect_size),
                     sep = "_")
    all_results[[sim_key]] <- results
  } else {
    message(paste("File not found:", results_file))
  }
}

if (length(all_results) == 0) {
  stop("No simulation results found!")
}

# Combine all results
combined_results <- bind_rows(all_results)

# Compute averaged power for num_trt simulations (by treatment cell count)
num_trt_results <- combined_results %>%
  filter(simulation_type == "num_trt") %>%
  group_by(num_treatment_cells, num_control_cells, total_cells, simulation_effect_size, simulation_type) %>%
  summarise(
    averaged_power = mean(power, na.rm = TRUE),
    n_observations = n(),
    .groups = "drop"
  ) %>%
  arrange(num_treatment_cells)

# Compute averaged power for effect_size simulations (by effect size)
effect_size_results <- combined_results %>%
  filter(simulation_type == "effect_size") %>%
  group_by(simulation_effect_size, num_treatment_cells, num_control_cells, total_cells, simulation_type) %>%
  summarise(
    averaged_power = mean(power, na.rm = TRUE),
    n_observations = n(),
    .groups = "drop"
  ) %>%
  arrange(simulation_effect_size)

# Combine averaged results
averaged_results <- bind_rows(num_trt_results, effect_size_results)

# Display summary
message(paste("Total combined observations:", nrow(combined_results)))
message(paste("Total averaged observations:", nrow(averaged_results)))

if (nrow(num_trt_results) > 0) {
  message(paste("Treatment cell counts analyzed:", 
                paste(sort(unique(num_trt_results$num_treatment_cells)), collapse = ", ")))
}

if (nrow(effect_size_results) > 0) {
  message(paste("Effect sizes analyzed:", 
                paste(sort(unique(effect_size_results$simulation_effect_size)), collapse = ", ")))
}

# Save datasets as RDS files
saveRDS(combined_results, "all_simulation_results.rds")
saveRDS(averaged_results, "averaged_simulation_results.rds")

# Also save separate files for each simulation type
if (nrow(num_trt_results) > 0) {
  saveRDS(num_trt_results, "averaged_num_trt_results.rds")
}
if (nrow(effect_size_results) > 0) {
  saveRDS(effect_size_results, "averaged_effect_size_results.rds")
}

message("Results saved to:")
message("- all_simulation_results.rds (all individual results)")
message("- averaged_simulation_results.rds (averaged results for all simulations)")
if (nrow(num_trt_results) > 0) {
  message("- averaged_num_trt_results.rds (averaged by treatment cell count)")
}
if (nrow(effect_size_results) > 0) {
  message("- averaged_effect_size_results.rds (averaged by effect size)")
}

# Display first few rows of averaged results
message("\nFirst few rows of averaged results:")
print(head(averaged_results))