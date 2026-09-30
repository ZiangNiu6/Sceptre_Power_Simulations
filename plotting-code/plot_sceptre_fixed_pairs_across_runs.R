#!/usr/bin/env Rscript

# Recalculate SCEPTRE power in fixed, nested pair panels across the 200
# manuscript simulation runs. Requires the original run-level p-values;
# averaged pair powers cannot be used to reconstruct this distribution.

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 2L) {
  stop(paste(
    "Usage: Rscript --vanilla plot_sceptre_fixed_pairs_across_runs.R",
    "[RAW_TSV_OR_SPLIT_DIRECTORY] [OUTPUT_DIRECTORY]"
  ))
}
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) stop("Run this script with Rscript.")
script_dir <- dirname(normalizePath(sub("^--file=", "", script_arg)))
repo_dir <- dirname(script_dir)
scenario_results_dir <- file.path(
  repo_dir, "simulation", "effect_size_0.15", "results", "test_data"
)
output_dir <- if (length(args) == 2L) args[2] else script_dir
data_dir <- file.path(output_dir, "figure-data")
figure_dir <- file.path(output_dir, "figures")

pair_file <- file.path(scenario_results_dir, "power_analysis_results.tsv")
pairs <- fread(pair_file, select = c("grna_target", "response_id", "power"))
pair_count <- nrow(pairs)
if (pair_count != 7364L ||
    anyNA(pairs[, .(grna_target, response_id)]) ||
    anyDuplicated(pairs[, .(grna_target, response_id)]) ||
    any(!is.finite(pairs$power)) ||
    any(pairs$power < 0 | pairs$power > 1)) {
  stop("Expected 7,364 distinct manuscript non-null pairs with valid saved powers.")
}

combined_raw_file <- file.path(scenario_results_dir, "power_analysis_output.tsv")
split_raw_dir <- file.path(scenario_results_dir, "power_analysis_split")
raw_path <- if (length(args) >= 1L) {
  args[1]
} else if (file.exists(combined_raw_file)) {
  combined_raw_file
} else {
  split_raw_dir
}
if (dir.exists(raw_path)) {
  raw_files <- file.path(raw_path, paste0("power_analysis_output_", 1:14, ".tsv"))
  if (!all(file.exists(raw_files))) {
    stop("Split directory must contain power_analysis_output_1.tsv through _14.tsv.")
  }
} else if (file.exists(raw_path)) {
  raw_files <- raw_path
} else {
  stop("Run-level SCEPTRE output does not exist: ", raw_path)
}

required_columns <- c("grna_target", "response_id", "rep", "p_value")
read_run_file <- function(path) {
  header <- names(fread(path, nrows = 0L))
  if (!all(required_columns %in% header)) {
    stop("Missing required columns in ", path)
  }
  fread(path, select = required_columns, showProgress = FALSE)
}
raw <- rbindlist(lapply(raw_files, read_run_file), use.names = TRUE)
n_runs <- 200L
expected_rows <- pair_count * n_runs
if (nrow(raw) != expected_rows ||
    anyNA(raw[, .(grna_target, response_id, rep)]) ||
    anyNA(match(raw$rep, seq_len(n_runs))) ||
    any(!is.na(raw$p_value) &
        (!is.finite(raw$p_value) | raw$p_value < 0 | raw$p_value > 1))) {
  stop("Expected exactly 200 runs of all 7,364 pairs with valid p-values.")
}

# The saved pair-power file is sorted by power. Randomize it once before
# taking prefixes; re-randomizing for each run would change the pair panel.
set.seed(20260929L)
pair_order <- sample.int(pair_count)
pair_key <- paste(pairs$grna_target, pairs$response_id, sep = "\r")
raw_key <- paste(raw$grna_target, raw$response_id, sep = "\r")
pair_idx <- match(raw_key, pair_key)
if (anyNA(pair_idx)) stop("Run-level output contains pairs outside the manuscript panel.")
rep_idx <- match(raw$rep, seq_len(n_runs))
matrix_idx <- (rep_idx - 1L) * pair_count + pair_idx
if (anyDuplicated(matrix_idx)) stop("Duplicate pair/run rows in run-level output.")

p_matrix <- matrix(NA_real_, nrow = pair_count, ncol = n_runs)
p_matrix[matrix_idx] <- raw$p_value
rm(raw, raw_key, pair_idx, rep_idx, matrix_idx)

panel_sizes <- c(50L, 100L, 200L, 400L, 800L, 1600L, 3200L,
                 6400L, pair_count)
fdr <- 0.10
nulls_per_positive <- 19L  # 5% non-null tests, as in the manuscript
power <- matrix(NA_real_, nrow = n_runs, ncol = length(panel_sizes))
set.seed(20260930L)

for (run in seq_len(n_runs)) {
  # One independent null stream per simulation run. Its prefixes are reused
  # across panel sizes so that the null part of the family is nested too.
  null_p <- runif(nulls_per_positive * pair_count)
  for (size_index in seq_along(panel_sizes)) {
    n_positive <- panel_sizes[size_index]
    positive_p <- p_matrix[pair_order[seq_len(n_positive)], run]
    positive_p[is.na(positive_p)] <- 1  # retain these tests in the BH family
    adjusted <- p.adjust(
      c(positive_p, null_p[seq_len(nulls_per_positive * n_positive)]),
      method = "BH"
    )
    power[run, size_index] <-
      sum(adjusted[seq_len(n_positive)] < fdr) / n_positive
  }
}

results <- data.frame(
  rep = rep(seq_len(n_runs), times = length(panel_sizes)),
  n_positive = rep(panel_sizes, each = n_runs),
  n_null = rep(nulls_per_positive * panel_sizes, each = n_runs),
  n_total = rep((nulls_per_positive + 1L) * panel_sizes, each = n_runs),
  power = as.vector(power)
)
if (nrow(results) != n_runs * length(panel_sizes) ||
    any(!is.finite(results$power))) {
  stop("Incomplete simulation power output.")
}

summary <- do.call(rbind, lapply(panel_sizes, function(n) {
  x <- results$power[results$n_positive == n]
  data.frame(
    n_positive = n, n_null = nulls_per_positive * n,
    n_total = (nulls_per_positive + 1L) * n,
    mean_power = mean(x), sd_power = sd(x),
    q025 = unname(quantile(x, 0.025)),
    q25 = unname(quantile(x, 0.25)),
    median = median(x),
    q75 = unname(quantile(x, 0.75)),
    q975 = unname(quantile(x, 0.975))
  )
}))
historical_full_pool_mean <- mean(pairs$power)
if (abs(summary$mean_power[nrow(summary)] - historical_full_pool_mean) > 0.02) {
  warning(sprintf(
    "Full-pool mean %.4f differs from retained manuscript mean %.4f by more than 0.02; check that the raw file is the effect-size 0.15 scenario. Fresh Uniform null draws can cause smaller differences.",
    summary$mean_power[nrow(summary)], historical_full_pool_mean
  ))
}

dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(
  data.frame(selection_order = seq_len(pair_count),
             grna_target = pairs$grna_target[pair_order],
             response_id = pairs$response_id[pair_order]),
  file.path(data_dir, "sceptre-fixed-pair-order.csv"), row.names = FALSE
)
write.csv(results, file.path(data_dir, "sceptre-fixed-panel-run-power.csv"),
          row.names = FALSE)
write.csv(summary, file.path(data_dir, "sceptre-fixed-panel-run-summary.csv"),
          row.names = FALSE)

results$pair_count_label <- factor(
  results$n_positive, levels = panel_sizes,
  labels = format(panel_sizes, big.mark = ",", trim = TRUE)
)
full_pool_mean <- summary$mean_power[nrow(summary)]
plot <- ggplot(results, aes(x = pair_count_label, y = power)) +
  geom_hline(yintercept = full_pool_mean, color = "#B05B43",
             linetype = "dashed", linewidth = 0.65) +
  geom_boxplot(width = 0.60, fill = "#BDD6E7", color = "#315D80",
               outlier.shape = NA, linewidth = 0.60) +
  geom_point(position = position_jitter(width = 0.15, height = 0,
                                        seed = 20260929L),
             color = "#315D80", alpha = 0.18, size = 1.45) +
  scale_y_continuous(labels = function(y) paste0(round(100 * y), "%"),
                     breaks = seq(0, 1, by = 0.05),
                     expand = expansion(mult = c(0.04, 0.06))) +
  labs(title = "SCEPTRE power across simulated runs",
       x = "Number of non-null perturbation-gene pairs",
       y = "Non-null rejection proportion") +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(size = 18, face = "bold", hjust = 0.5,
                              margin = margin(b = 12)),
    axis.title = element_text(size = 13),
    axis.text = element_text(size = 11),
    axis.text.x = element_text(margin = margin(t = 6)),
    axis.line = element_line(linewidth = 0.5),
    axis.ticks = element_line(linewidth = 0.5),
    panel.grid.major.y = element_line(color = "#E8E8E8", linewidth = 0.3)
  )

ggsave(file.path(figure_dir, "sceptre-power-across-runs-fixed-pairs.png"),
       plot, width = 10.5, height = 6.3, dpi = 300, bg = "white")
ggsave(file.path(figure_dir, "sceptre-power-across-runs-fixed-pairs.pdf"),
       plot, width = 10.5, height = 6.3, bg = "white")

cat(sprintf(
  "Saved 200 run-level power values at each of %d fixed panel sizes; full-pool mean = %.4f.\n",
  length(panel_sizes), full_pool_mean
))
