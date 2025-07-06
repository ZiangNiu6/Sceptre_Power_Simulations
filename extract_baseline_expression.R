#!/usr/bin/env Rscript

# Script to extract rowData from simulated_sce_disp and save as baseline_expression.rds

library(SingleCellExperiment)

# Load one of the simulated_sce_disp objects (they should all have the same rowData)
message("Loading simulated_sce_disp object...")
simulated_sce_disp <- readRDS("results/test_data_original/simulated_sce_disp.rds")

# Extract rowData as data.frame
message("Extracting rowData...")
baseline_expression <- data.frame(rowData(simulated_sce_disp))

# Add gene_id column from row names
baseline_expression$gene_id <- rownames(baseline_expression)

# Reorder columns to put gene_id first
baseline_expression <- baseline_expression[, c("gene_id", setdiff(colnames(baseline_expression), "gene_id"))]

# Display structure
message("Baseline expression data structure:")
message(paste("Dimensions:", nrow(baseline_expression), "rows x", ncol(baseline_expression), "columns"))
message("\nColumn names:")
print(colnames(baseline_expression))

message("\nFirst few rows:")
print(head(baseline_expression))

# Save as RDS
message("Saving baseline_expression.rds...")
saveRDS(baseline_expression, "baseline_expression.rds")

message("Successfully saved baseline_expression.rds")