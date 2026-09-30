#!/bin/bash
#$ -N sceptre_fixed_pair_plot
#$ -j y
#$ -cwd
#$ -V
#$ -l m_mem_free=8G,h_rt=04:00:00

set -euo pipefail

# UGE copies the submitted script into its spool directory, so BASH_SOURCE does
# not point at the repository when this runs as a batch job. Try the spool copy
# first (correct for a direct `bash run_on_hpc3.sh`), then the submission
# directory that UGE records in SGE_O_WORKDIR.
script_name=plot_sceptre_fixed_pairs_across_runs.R
for candidate in \
  "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" \
  "${SGE_O_WORKDIR:-}/plotting-code" \
  "${SGE_O_WORKDIR:-}" \
  "$(pwd)/plotting-code" \
  "$(pwd)"; do
  if [[ -n "$candidate" && -f "$candidate/$script_name" ]]; then
    script_dir=$candidate
    break
  fi
done
if [[ -z "${script_dir:-}" ]]; then
  echo "Could not locate $script_name; submit from the repository root." >&2
  exit 1
fi

Rscript --vanilla "${script_dir}/${script_name}" "$@"
