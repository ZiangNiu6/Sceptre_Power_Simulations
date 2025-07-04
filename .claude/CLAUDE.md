# Claude Instructions

## Project Overview: Sceptre Power Simulations Pipeline

### Purpose
This project runs power analysis simulations for single-cell CRISPR screens using the Sceptre R package. The pipeline evaluates statistical power across different cell counts per perturbation (50-10,000 cells) to guide experimental design.

### Key Components
- **Snakemake workflow** with rule-based execution for reproducible analysis
- **R scripts** for data simulation, power analysis, and visualization  
- **UGE cluster integration** for distributed computing on HPC systems
- **Conda environment** with Python 3.9 and Snakemake 7.32.4 for compatibility

### Current Configuration
- **Sample**: test_data (14 parallel splits for power analysis)
- **Effect size**: 0.15 
- **Replications**: 20 per cell count condition
- **Cluster**: bhaswar team resources via UGE profile
- **Memory**: 32GB per job, 2-hour time limit on retries
- **Retry mechanism**: 4 retries with doubled time allocation

### Known Issues and Solutions
1. **Time Limit Problem**: Original 1-hour limit caused splits 13-14 to fail
   - **Solution**: Implemented retry mechanism with 2-hour limit on retries
   
2. **Memory Architecture**: Each split loads full dataset (~8GB) instead of true data splitting
   - **Impact**: High memory usage but manageable with 32GB allocation
   
3. **Non-Reproducible Results**: No random seeds set in simulation scripts
   - **Impact**: Results vary between runs; comparisons with original data validate pipeline functionality only

### File Structure
- `snakemake_profiles/uge_profile/`: Cluster configuration
- `workflow/rules/`: Snakemake rule definitions
- `workflow/scripts/`: R analysis scripts
- `results/test_data/`: Output results and logs
- `results/test_data_original/`: Reference results for validation
- `resources/test_data/`: Intermediate data files

### Git Workflow
- **Repository**: Forked from jamesgalante/Sceptre_Power_Simulations 
- **Remote**: ZiangNiu6/Sceptre_Power_Simulations (user has push access)
- **Branch**: main

## Commit and Push Protocol

Whenever the user says "commit and push", I will:

1. Add ALL files in the repository to git staging area using `git add .`
2. Commit everything with a descriptive message
3. Push to the remote repository to keep remote and local repos synchronized

This ensures the remote repo maintains the same state as the local repo with all changes included.

## Cache Management Protocol

Going forward, I'll ask before running `--delete-all-output` to preserve cached results when possible.

## Job Submission Protocol

**IMPORTANT**: Before resubmitting the job, please unlock first using `snakemake --unlock`.