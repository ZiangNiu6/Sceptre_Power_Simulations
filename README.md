# Sceptre-based Power Simulations

## Overview

This pipeline estimates the **statistical power** of single-cell CRISPR screens (CRISPRi/CRISPRko) using the [sceptre](https://timothy-barry.github.io/sceptre-book/) R package. The pipeline sweeps over two experimental axes:
- **Cell count per perturbation** at a fixed effect size
- **Effect size** at a fixed cell count

Results are power curves that guide experimental design and feasibility assessment.

## Prerequisites

- **Linux** (the conda environments and cluster integration target linux-64)
- **Conda** or **Miniconda** installed
- **HPC cluster** with a job scheduler (UGE or SLURM) for distributed execution
- `qsub`/`qstat` (UGE) or equivalent SLURM commands available

## Installation & Environment Setup

### 1. Clone the Repository

```bash
git clone https://github.com/ZiangNiu6/Sceptre_Power_Simulations.git
cd Sceptre_Power_Simulations
```

### 2. Create the Snakemake Driver Environment

This is the main environment used to launch the pipeline:

```bash
conda create -n sceptre_power_sim python=3.9
conda activate sceptre_power_sim
conda install -c bioconda snakemake=7.32.4
```

### 3. Rule-Level Conda Environments (Auto-Created)

Snakemake automatically builds two additional R environments on the first run via `--use-conda`. You do **not** need to create these manually:

| Environment | Defined in | Key packages | Used by |
|---|---|---|---|
| `sceptre_power_simulations` | `workflow/envs/sceptre_power_simulations.yml` | R 4.1.2, sceptre, tidyverse, data.table | Most pipeline rules |
| `analyze_crispr_screen` | `workflow/envs/analyze_crispr_screen.yml` | R 4.1.1, DESeq2, MAST, scran | `fit_dispersions`, `visualize_power_results` |

## Input Data Preparation

Place your raw counts matrix in the `resources/` directory:

```
resources/<sample_name>/raw_counts.rds
```

- **Format**: sparse matrix in `dgRMatrix` format, saved with `saveRDS()`
- **Reference**: see `model/resources/test_data/raw_counts.rds` for an example

**(Optional)** If you want to visualize power curves by TPM instead of UMI counts, provide a TPM file at `resources/tpm_per_gene.tsv`. See `resources/tpm_per_gene.tsv` for the expected format. This file is only used for plotting; it maps gene names to TPM values from bulk RNA-seq.

## Configuration

Edit `config/config.yml` before running:

```yaml
samples:
  your_sample_name

simulate_guide_assignments:
  num_cells_per_pert: [50, 75, 100, 150, 250, 500, 750, 1000, 1400, 1800, 2500, 4000, 7500, 10000]

sceptre_power_analysis:
  effect_size: 0.15
  reps: 20

compute_power_from_simulations:
  pval_adj_thresh: 0.1
  positive_proportion: 0.05

visualize_power_results:
  tpm_per_gene: NULL
  gene_format: "ensembl"
```

### Parameter Reference

| Parameter | Description | Default |
|---|---|---|
| `samples` | Sample name; must match a directory under `resources/` containing `raw_counts.rds` | `test_data` |
| `num_cells_per_pert` | List of cell counts per perturbation to simulate. Each entry creates one parallel split. | `[50, ..., 10000]` (14 values) |
| `effect_size` | Fractional decrease in gene expression to simulate (e.g., `0.15` = 15% decrease) | `0.15` |
| `reps` | Number of simulation replicates per condition. More reps reduce noise but increase runtime. | `20` |
| `pval_adj_thresh` | Benjamini-Hochberg adjusted p-value threshold for significance | `0.1` |
| `positive_proportion` | Expected fraction of true positives (affects BH correction). Typically low for CRISPR screens. | `0.05` |
| `tpm_per_gene` | Path to TPM file for TPM-based visualization. Set to `NULL` to use UMI counts. | `NULL` |
| `gene_format` | Gene name format: `"ensembl"` or `"symbol"` | `"ensembl"` |

## Cluster Configuration

The pipeline uses a Snakemake profile for cluster job submission, located at `snakemake_profiles/uge_profile/config.yaml`:

```yaml
cluster: "qsub -j y -cwd -V -P <team_name> -l m_mem_free={resources.mem_free} -l h_rt={resources.time} -pe openmp {threads} -N {rule}"
cluster-cancel: "qdel {jobid}"
jobs: 20
retries: 1
use-conda: true
conda-frontend: conda
latency-wait: 30
notemp: true
default-resources:
  - mem_free="32G"
  - time="160:00:00"
  - threads=1
```

**To adapt for SLURM**, replace the `cluster` line and default resources:

```yaml
jobs: 100
slurm: True
retries: 1
use-conda: True
notemp: True
default-resources:
  - slurm_account=your_account
  - slurm_partition=your_partition,owners,normal
  - runtime="6h"
  - slurm_extra="--nice"
```

A UGE job status script (`cluster_status_uge.sh`) is provided for monitoring job completion. It polls `qstat` and falls back to `qacct` for finished jobs.

## Running the Pipeline

### Single Simulation (the `model/` directory)

The `model/` directory contains the canonical pipeline. To run it:

```bash
cd model/
conda activate sceptre_power_sim

# Dry run — verify configuration without executing
snakemake --use-conda all -np

# Full run — submit to cluster
snakemake --profile snakemake_profiles/uge_profile --restart-times 2 all
```

Or submit the entire pipeline as a single UGE job:

```bash
qsub run_snakemake.sh
```

### Effect Size Sweep (8 simulations)

The `simulation/effect_size_*` directories (0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40) each contain a full pipeline copy with:
- **Varied**: `effect_size` (0.05–0.40)
- **Fixed**: `num_cells_per_pert` = 1,000 cells (uniform across all splits), `reps` = 200

Submit all 8 simulations simultaneously from the project root:

```bash
bash submit_effect_size_simulations.sh
```

### Treatment Cell Count Sweep (8 simulations)

The `simulation/num_trt_*` directories (250, 500, 750, 1000, 1250, 1500, 1750, 2000) vary the number of treatment cells at a fixed effect size of 0.15.

Submit all 8 simulations simultaneously:

```bash
bash submit_num_trt_simulations.sh
```

### Monitoring Jobs

```bash
qstat -u $USER         # List your running/pending jobs
qstat -f               # Detailed job information
```

## Pipeline Workflow (DAG)

The Snakemake pipeline executes the following rules in order. Rules 1–4 are sequential setup steps; rule 5 runs in parallel across splits.

```
raw_counts.rds
      │
      ▼
┌─────────────────────────────┐
│ 1. simulate_guide_assignments│  Simulate guide/perturbation assignments
│                              │  at each cell count level
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│ 2. fit_dispersions           │  Fit negative binomial dispersion
│                              │  estimates and size factors
└──────────────┬──────────────┘
               ▼
     ┌─────────┴─────────┐
     ▼                   ▼
┌────────────┐   ┌───────────────────────┐
│ 3. split   │   │ 4. create_simulated   │  Build reusable sceptre
│  target-   │   │    sceptre_object     │  object template
│  response  │   │                       │
│  pairs     │   └───────────┬───────────┘
└─────┬──────┘               │
      └──────────┬───────────┘
                 ▼
┌─────────────────────────────┐
│ 5. sceptre_power_analysis    │  Run power simulation per split
│    (parallelized × N splits) │  (N reps of DE testing per split)
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│ 6. combine_sceptre_power    │  Merge split outputs into one TSV
│    _analysis                 │
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│ 7. compute_power_from       │  Compute power (rejection rate)
│    _simulations              │  from BH-adjusted p-values
└──────────────┬──────────────┘
               ▼
┌─────────────────────────────┐
│ 8. visualize_power_results   │  Render HTML report with
│                              │  power curves
└─────────────────────────────┘
```

### Rule Details

| Rule | Script | Environment | Memory | Description |
|---|---|---|---|---|
| `simulate_guide_assignments` | `simulate_guide_assignments.R` | sceptre_power_simulations | 64G | Assigns cells to perturbation groups at each cell count level |
| `fit_dispersions` | `fit_negbinom_distr.R` | analyze_crispr_screen | 32G | Estimates per-gene dispersion and size factors from real data |
| `split_target_response_pairs` | `split_target_response_pairs.R` | sceptre_power_simulations | 16G | Splits gene–perturbation pairs into parallel batches |
| `create_simulated_sceptre_object` | `create_simulated_sceptre_object.R` | sceptre_power_simulations | 32G | Builds a template sceptre object for simulation |
| `sceptre_power_analysis` | `sceptre_power_analysis.R` | sceptre_power_simulations | 8G | Simulates expression, runs DE test, repeats for N reps |
| `combine_sceptre_power_analysis` | `combine_sceptre_power_analysis.R` | sceptre_power_simulations | 32G | Concatenates per-split TSV files |
| `compute_power_from_simulations` | `compute_power_from_simulations.R` | sceptre_power_simulations | 24G | Computes power per gene–perturbation pair |
| `visualize_power_results` | `visualize_power_results.Rmd` | analyze_crispr_screen | — | Renders interactive HTML report |

Helper R functions used across rules are in `workflow/scripts/R_functions/`:
- `differential_expression_fun.R` — DE testing utilities
- `power_simulations_fun.R` — power simulation core logic
- `simulate_perturbations.R` — perturbation effect simulation

## Output Files

### Per-Simulation Outputs (`results/<sample>/`)

| File | Description |
|---|---|
| `simulated_sce.rds` | SingleCellExperiment with simulated guide assignments |
| `simulated_sce_disp.rds` | Above + fitted dispersion estimates and size factors |
| `power_analysis_split/power_analysis_output_*.tsv` | Per-split raw power analysis results |
| `power_analysis_output.tsv` | Combined raw results across all splits |
| `power_analysis_results.tsv` | Final power table with columns: `grna_target`, `response_id`, `average_expression_all_cells`, `mean_pert_cells`, `power`, `effect_size` |
| `power_analysis_plots.html` | Interactive HTML visualization of power curves |
| `logs/` | Per-rule log files for debugging |

### Intermediate Resources (`resources/<sample>/`)

| File | Description |
|---|---|
| `raw_counts.rds` | Input sparse count matrix |
| `discovery_pairs.txt` | All gene–perturbation pairs to test |
| `pair_splits/discovery_pairs_split_*.txt` | Batched pair files for parallel execution |
| `grna_target_data_frame.txt` | Guide RNA–target mapping |
| `simulated_sceptre_object.rds` | Reusable sceptre object template |

## Post-Simulation Analysis

After all simulations finish, aggregate and validate results from the `analysis/` directory:

```bash
cd analysis/

# Combine results across all effect_size and num_trt simulations
Rscript combine_all_simulations.R

# Extract gene baseline expression metadata
Rscript extract_baseline_expression.R

# Extract simulation runtime data
Rscript extract_simulation_timing.R

# Validate results
Rscript validate_all_simulations.R
```

### Aggregated Outputs (`analysis/results_summary/`)

| File | Description |
|---|---|
| `all_simulation_results.rds` | All individual observations across simulations (117,824 rows) |
| `averaged_simulation_results.rds` | Averaged power across genes (16 rows: 8 num_trt + 8 effect_size) |
| `averaged_num_trt_results.rds` | Averaged power by treatment cell count |
| `averaged_effect_size_results.rds` | Averaged power by effect size |
| `baseline_expression.rds` | Per-gene baseline expression and dispersion |
| `simulation_timing_data.rds` | Runtime data for each simulation |

## Key Results

| Simulation axis | Range | Power range | Fixed parameters |
|---|---|---|---|
| Treatment cell count | 250–2,000 cells | 8.6%–45.7% | effect size = 0.15 |
| Effect size | 0.05–0.40 | 3.3%–69.6% | 1,000 cells per perturbation |

Average runtime per effect size simulation: ~9 hours.

## Troubleshooting

| Issue | Cause | Solution |
|---|---|---|
| Snakemake lock error | Previous run left a lock file | Run `snakemake --unlock` before resubmitting |
| Jobs fail on large splits | Wall-time limit exceeded | Use `--restart-times 2` (already set in `run_snakemake.sh`) |
| High memory usage (~8 GB per split) | Each split loads the full dataset | 32 GB allocation handles this; no code change needed |
| Results differ between runs | No random seeds set in simulation scripts | Expected behavior; results are structurally valid but not bitwise reproducible |
| Conda environment build fails | Network or solver issues | Try `conda config --set solver libmamba` or use `mamba` |

## Repository Structure

```
Sceptre_Power_Simulations/
├── model/                                  # Canonical pipeline (template)
│   ├── config/config.yml                   # Configuration file
│   ├── run_snakemake.sh                    # UGE submission script
│   ├── snakemake_profiles/uge_profile/     # Cluster profile
│   ├── resources/test_data/               # Input data
│   ├── results/test_data/                 # Output results
│   └── workflow/
│       ├── Snakefile                       # Main workflow definition
│       ├── rules/                          # Rule definitions
│       │   ├── simulate_guide_assignments.smk
│       │   └── run_power_analysis.smk
│       ├── scripts/                        # R analysis scripts
│       │   ├── simulate_guide_assignments.R
│       │   ├── fit_negbinom_distr.R
│       │   ├── split_target_response_pairs.R
│       │   ├── create_simulated_sceptre_object.R
│       │   ├── sceptre_power_analysis.R
│       │   ├── combine_sceptre_power_analysis.R
│       │   ├── compute_power_from_simulations.R
│       │   ├── visualize_power_results.Rmd
│       │   └── R_functions/               # Shared helper functions
│       └── envs/                           # Conda environment definitions
│           ├── sceptre_power_simulations.yml
│           └── analyze_crispr_screen.yml
├── simulation/                             # Parameter sweep simulations
│   ├── effect_size_{0.05..0.40}/          # 8 effect size scenarios
│   └── num_trt_{250..2000}/               # 8 treatment count scenarios
├── analysis/                               # Post-simulation aggregation
│   ├── combine_all_simulations.R
│   ├── extract_baseline_expression.R
│   ├── extract_simulation_timing.R
│   ├── validate_*.R
│   └── results_summary/                   # Aggregated output files
├── submit_effect_size_simulations.sh       # Batch submit all effect size sims
├── submit_num_trt_simulations.sh           # Batch submit all num_trt sims
├── cluster_status_uge.sh                   # UGE job status checker
└── README.md
```

## References

- **Sceptre package**: [Hands-On Single-Cell CRISPR Screen Analysis](https://timothy-barry.github.io/sceptre-book/)
- **Upstream repository**: [jamesgalante/Sceptre_Power_Simulations](https://github.com/jamesgalante/Sceptre_Power_Simulations)
- **Snakemake documentation**: [snakemake.readthedocs.io](https://snakemake.readthedocs.io/en/stable/index.html)
