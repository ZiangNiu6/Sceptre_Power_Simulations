#!/bin/bash
#$ -N sceptre_power_1750
#$ -j y
#$ -cwd
#$ -pe openmp 1

# Record start time
start_time=$(date +%s)
echo "=== SIMULATION START ==="
echo "Start time: $(date)"
echo "Cell count: 1750"
echo "========================"

# Create timing log file
timing_file="simulation_timing.log"
echo "=== SIMULATION TIMING LOG ===" > "$timing_file"
echo "Cell count: 1750" >> "$timing_file"
echo "Start time: $(date)" >> "$timing_file"
echo "Start timestamp: $start_time" >> "$timing_file"

# Load conda environment
eval "$(/home/stat/ekatsevi/team/ziangniu/miniconda3/bin/conda shell.bash hook)"
conda activate sceptre_power_sim

# Run Snakemake pipeline
snakemake --profile snakemake_profiles/uge_profile --restart-times 2 all

# Record end time and calculate duration
end_time=$(date +%s)
duration=$((end_time - start_time))
hours=$((duration / 3600))
minutes=$(((duration % 3600) / 60))
seconds=$((duration % 60))

# Save timing results to file
echo "End time: $(date)" >> "$timing_file"
echo "End timestamp: $end_time" >> "$timing_file"
echo "Duration: ${hours}h ${minutes}m ${seconds}s" >> "$timing_file"
echo "Total seconds: ${duration}" >> "$timing_file"
echo "Status: Pipeline completed" >> "$timing_file"
echo "========================" >> "$timing_file"

echo "========================"
echo "=== SIMULATION END ===="
echo "End time: $(date)"
echo "Duration: ${hours}h ${minutes}m ${seconds}s"
echo "Total seconds: ${duration}"
echo "Cell count: 1750"
echo "Status: Pipeline completed"
echo "Timing saved to: $timing_file"
echo "========================"