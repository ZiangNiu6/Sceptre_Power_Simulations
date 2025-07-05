#!/bin/bash

# Master submission script for all 8 Sceptre power simulations
# This script submits all simulations simultaneously

echo "Starting submission of all 8 Sceptre power simulations..."
echo "Timestamp: $(date)"

# Array of simulation directories
sim_dirs=(
    "simulation/num_trt_250"
    "simulation/num_trt_500"
    "simulation/num_trt_750"
    "simulation/num_trt_1000"
    "simulation/num_trt_1250"
    "simulation/num_trt_1500"
    "simulation/num_trt_1750"
    "simulation/num_trt_2000"
)

# Submit each simulation
for dir in "${sim_dirs[@]}"; do
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
        cd .. || { echo "ERROR: Failed to return to parent directory"; exit 1; }
    else
        echo "ERROR: Directory $dir or run_snakemake.sh not found!"
    fi
done

echo "All submissions completed!"
echo "Use 'qstat -u $USER' to monitor job status"
echo "Use 'qstat -f' for detailed job information"