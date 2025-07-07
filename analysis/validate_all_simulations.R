#!/usr/bin/env Rscript

# Script to validate and display structure of all simulation results

library(dplyr)

# Read all the results files
all_simulation_results <- readRDS("results_summary/all_simulation_results.rds")
averaged_simulation_results <- readRDS("results_summary/averaged_simulation_results.rds")
averaged_num_trt_results <- readRDS("results_summary/averaged_num_trt_results.rds")
averaged_effect_size_results <- readRDS("results_summary/averaged_effect_size_results.rds")

message("=== ALL SIMULATION RESULTS SUMMARY ===")
message(paste("Total observations:", nrow(all_simulation_results)))
message(paste("Simulation types:", paste(unique(all_simulation_results$simulation_type), collapse = ", ")))

# Summary by simulation type
sim_type_summary <- all_simulation_results %>%
  group_by(simulation_type) %>%
  summarise(
    n_observations = n(),
    unique_parameters = n_distinct(ifelse(simulation_type == "num_trt", num_treatment_cells, simulation_effect_size)),
    .groups = "drop"
  )
print(sim_type_summary)

message("\n=== NUM TRT RESULTS ===")
message(paste("Dimensions:", nrow(averaged_num_trt_results), "rows x", ncol(averaged_num_trt_results), "columns"))
print(averaged_num_trt_results %>% 
      select(num_treatment_cells, num_control_cells, total_cells, simulation_effect_size, averaged_power) %>%
      arrange(num_treatment_cells))

message("\n=== EFFECT SIZE RESULTS ===")
message(paste("Dimensions:", nrow(averaged_effect_size_results), "rows x", ncol(averaged_effect_size_results), "columns"))
print(averaged_effect_size_results %>% 
      select(simulation_effect_size, num_treatment_cells, num_control_cells, total_cells, averaged_power) %>%
      arrange(simulation_effect_size))

message("\n=== COMBINED AVERAGED RESULTS ===")
message(paste("Total averaged observations:", nrow(averaged_simulation_results)))
print(averaged_simulation_results %>% 
      select(simulation_type, simulation_effect_size, num_treatment_cells, averaged_power) %>%
      arrange(simulation_type, ifelse(simulation_type == "num_trt", num_treatment_cells, simulation_effect_size)))

# Summary statistics
message("\n=== POWER ANALYSIS SUMMARY ===")
num_trt_power_range <- range(averaged_num_trt_results$averaged_power)
effect_size_power_range <- range(averaged_effect_size_results$averaged_power)

message(paste("NUM TRT Power Range:", 
              sprintf("%.1f%% - %.1f%%", num_trt_power_range[1]*100, num_trt_power_range[2]*100)))
message(paste("EFFECT SIZE Power Range:", 
              sprintf("%.1f%% - %.1f%%", effect_size_power_range[1]*100, effect_size_power_range[2]*100)))

# Check for consistent treatment cell counts in effect size simulations
effect_size_trt_cells <- unique(averaged_effect_size_results$num_treatment_cells)
message(paste("Treatment cells in effect size simulations:", paste(effect_size_trt_cells, collapse = ", ")))