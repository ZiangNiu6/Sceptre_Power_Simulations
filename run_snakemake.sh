#!/bin/bash
#$ -N sceptre_power_test
#$ -j y
#$ -cwd
#$ -l mem_free=32G
#$ -pe openmp 1

# Load conda environment
eval "$(/home/stat/ekatsevi/team/ziangniu/miniconda3/bin/conda shell.bash hook)"
conda activate sceptre_power_sim

# Run Snakemake pipeline
snakemake --profile snakemake_profiles/uge_profile --restart-times 2 all