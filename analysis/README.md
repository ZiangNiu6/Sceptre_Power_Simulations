# Analysis Scripts

This directory contains R scripts for analyzing the power simulation results from the Sceptre Power Simulations pipeline.

## Scripts Overview

### Main Analysis Scripts
- **`combine_all_simulations.R`** - Comprehensive script that processes both num_trt and effect_size simulations
  - Reads from `../simulation/` directories
  - Extracts intended treatment cell counts from config files
  - Generates: `all_simulation_results.rds`, `averaged_simulation_results.rds`, `averaged_num_trt_results.rds`, `averaged_effect_size_results.rds`

- **`combine_power_results.R`** - Processes only num_trt simulations
  - Generates: `combined_power_results.rds`, `averaged_power_results.rds`

- **`extract_baseline_expression.R`** - Extracts gene baseline expression data
  - Reads from `../model/results/test_data_original/simulated_sce_disp.rds`
  - Generates: `baseline_expression.rds`

- **`extract_simulation_timing.R`** - Extracts simulation timing information
  - Reads `simulation_timing.log` files from effect_size simulations
  - Generates: `simulation_timing_data.rds`

### Validation Scripts
- **`validate_all_simulations.R`** - Validates comprehensive simulation results
- **`validate_timing_data.R`** - Validates timing data
- **`validate_results.R`** - Validates num_trt simulation results

## Usage

Run scripts from the `analysis/` directory:

```bash
cd analysis/
Rscript combine_all_simulations.R     # Main comprehensive analysis
Rscript validate_all_simulations.R    # Validate results
```

## Output Files

All output files are saved to the `results_summary/` directory:
- `all_simulation_results.rds` - 117,824 individual observations
- `averaged_simulation_results.rds` - 16 averaged results (8 num_trt + 8 effect_size)
- `averaged_num_trt_results.rds` - 8 results by treatment cell count
- `averaged_effect_size_results.rds` - 8 results by effect size
- `baseline_expression.rds` - Gene baseline expression data
- `simulation_timing_data.rds` - Timing data for effect_size simulations

## Key Results
- **Num TRT simulations**: 250-2000 cells, power range 8.6%-45.7%
- **Effect size simulations**: 1000 cells, effect sizes 0.05-0.40, power range 3.3%-69.6%
- **Timing**: Average 9.12 hours per effect size simulation