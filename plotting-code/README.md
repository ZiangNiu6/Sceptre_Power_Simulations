# Fixed-pair SCEPTRE power across runs

`plot_sceptre_fixed_pairs_across_runs.R` produces the 200-run boxplot for any
simulation scenario. It takes the 7,364 target–response pair IDs from the
`power_analysis_results.tsv` sitting beside whichever run-level p-value file
you point it at, so the pair panel and the reference mean always match the
scenario being plotted. All 16 scenarios share the same 7,364 pairs and the
same `pval_adj_thresh: 0.1` / `positive_proportion: 0.05`. That table is sorted by power, so the
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

The raw 200-run output is ignored by Git, and **only the `num_trt_*` scenarios
still have it on disk**. The eight `effect_size_*` scenarios were run at 200
reps but their raw p-values were deleted afterwards; the retained averaged
powers cannot be used to reconstruct this figure, so those scenarios must be
re-run before they can be plotted.

Available now (verified complete 7,364 × 200 grids):

```text
simulation/num_trt_{250,500,750,1000,1250,1500,1750,2000}/results/test_data/power_analysis_output.tsv
```

With no argument the script falls back to the `effect_size_0.15` paths below,
which currently do not exist — so pass the raw path explicitly:

```text
simulation/effect_size_0.15/results/test_data/power_analysis_output.tsv
simulation/effect_size_0.15/results/test_data/power_analysis_split/power_analysis_output_{1..14}.tsv
```

It stops if neither source exists or if the data do not form a complete
7,364-pair × 200-run grid. The unrelated 20-run `model/` output is rejected.

Note that `num_trt_1000` is the same configuration as `effect_size_0.15`
(effect size 0.15, 1,000 cells per perturbation), differing only in random
draw, so it is the closest available stand-in for the missing scenario.

## Run

From the repository root, activate an R environment with `data.table` and
`ggplot2` (both are specified in
`simulation/effect_size_0.15/workflow/envs/sceptre_power_simulations.yml`),
then submit the UGE job:

```bash
qsub plotting-code/run_on_hpc3.sh \
  simulation/num_trt_1000/results/test_data/power_analysis_output.tsv
```

For an interactive compute session, or to send outputs elsewhere:

```bash
Rscript --vanilla plotting-code/plot_sceptre_fixed_pairs_across_runs.R \
  /path/to/power_analysis_output.tsv
Rscript --vanilla plotting-code/plot_sceptre_fixed_pairs_across_runs.R \
  /path/to/power_analysis_output.tsv /path/to/output-directory
```

To sweep every scenario that has raw p-values:

```bash
for d in simulation/num_trt_*/; do
  qsub plotting-code/run_on_hpc3.sh "$d/results/test_data/power_analysis_output.tsv"
done
```

By default, outputs go to `plotting-code/figure-data/` and
`plotting-code/figures/`. Every filename is prefixed with the scenario name
(e.g. `num_trt_1000-power-across-runs-fixed-pairs.png`), so scenarios written
to the same directory do not overwrite each other. The script writes the fixed
pair order, 200 power values per panel size, a summary CSV, and PNG/PDF
figures. The generated
files are separate from the original SCEPTRE output and should be reviewed
before committing them.
