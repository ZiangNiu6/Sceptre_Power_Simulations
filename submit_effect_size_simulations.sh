#!/bin/bash

# Master submission script for 8 effect size Sceptre power simulations
# This script submits all effect size simulations simultaneously

echo "Starting submission of 8 effect size Sceptre power simulations..."
echo "Timestamp: $(date)"

# Array of effect size simulation directories
effect_dirs=(
    "simulation/effect_size_0.05"
    "simulation/effect_size_0.10"
    "simulation/effect_size_0.15"
    "simulation/effect_size_0.20"
    "simulation/effect_size_0.25"
    "simulation/effect_size_0.30"
    "simulation/effect_size_0.35"
    "simulation/effect_size_0.40"
)

# Submit each simulation
for dir in "${effect_dirs[@]}"; do
    if [ -d "$dir" ] && [ -f "$dir/run_snakemake.sh" ]; then
        echo "Submitting simulation: $dir"
        echo "  Changing to directory: $(pwd)/$dir"
        cd "$dir" || { echo "ERROR: Failed to change to $dir"; continue; }
        echo "  Current working directory: $(pwd)"
        
        # Unlock Snakemake workflow before submission
        echo "  Unlocking Snakemake workflow..."
        eval "$(/home/stat/ekatsevi/team/ziangniu/miniconda3/bin/conda shell.bash hook)"
        conda activate sceptre_power_sim
        snakemake --unlock
        
        # Submit the job
        echo "  Submitting job..."
        job_id=$(qsub run_snakemake.sh)
        echo "  Job ID: $job_id"
        cd ../.. || { echo "ERROR: Failed to return to main directory"; exit 1; }
    else
        echo "ERROR: Directory $dir or run_snakemake.sh not found!"
    fi
done

echo "All effect size simulations submitted!"
echo "Use 'qstat -u $USER' to monitor job status"
echo "Use 'qstat -f' for detailed job information"