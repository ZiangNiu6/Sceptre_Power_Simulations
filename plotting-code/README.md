# Fixed-pair SCEPTRE power across runs

`plot_sceptre_fixed_pairs_across_runs.R` produces the 200-run boxplot for the
manuscript's `effect_size_0.15` scenario. It reads the tracked
`simulation/effect_size_0.15/results/test_data/power_analysis_results.tsv`
for the 7,364 target–response pair IDs. That table is sorted by power, so the
script draws **one** random ordering of its pair IDs (seed `20260929`) before
taking fixed, nested prefixes of 50, 100, 200, 400, 800, 1,600, 3,200,
6,400, and 7,364 pairs. The selected pairs at a given size are identical
across all 200 runs.

For each run and panel, the script reads the original SCEPTRE p-values,
appends 19 independent Uniform null p-values per selected pair (5% non-null;
seed `20260930`), applies BH, and plots the proportion of selected non-null
pairs with adjusted p-value **strictly below 0.10**. Missing SCEPTRE p-values
remain in the BH family and count as non-rejections. The null draws are
nested across panel sizes within each run. Because these are new null draws,
the full-panel mean should be close to, but need not exactly equal, the
historical mean of about 31.7%.

## Input required on HPC3

The raw 200-run output is ignored by Git. The script uses the combined file
below if it exists, otherwise the 14 split files in the sibling directory:

```text
simulation/effect_size_0.15/results/test_data/power_analysis_output.tsv
simulation/effect_size_0.15/results/test_data/power_analysis_split/power_analysis_output_{1..14}.tsv
```

It stops if neither source exists or if the data do not form a complete
7,364-pair × 200-run grid. The unrelated 20-run `model/` output is rejected.

## Run

From the repository root, activate an R environment with `data.table` and
`ggplot2` (both are specified in
`simulation/effect_size_0.15/workflow/envs/sceptre_power_simulations.yml`),
then submit the UGE job:

```bash
qsub plotting-code/run_on_hpc3.sh
```

For an interactive compute session, or to use a different raw path and
output directory:

```bash
Rscript --vanilla plotting-code/plot_sceptre_fixed_pairs_across_runs.R
Rscript --vanilla plotting-code/plot_sceptre_fixed_pairs_across_runs.R \
  /path/to/power_analysis_output.tsv /path/to/output-directory
```

By default, outputs go to `plotting-code/figure-data/` and
`plotting-code/figures/`. The script writes the fixed pair order, 200 power
values per panel size, a summary CSV, and PNG/PDF figures. The generated
files are separate from the original SCEPTRE output and should be reviewed
before committing them.
