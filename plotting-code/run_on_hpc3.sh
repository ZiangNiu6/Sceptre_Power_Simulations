#!/bin/bash
#$ -N sceptre_fixed_pair_plot
#$ -j y
#$ -cwd
#$ -V
#$ -l m_mem_free=8G,h_rt=04:00:00

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
Rscript --vanilla "${script_dir}/plot_sceptre_fixed_pairs_across_runs.R" "$@"
