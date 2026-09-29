#!/bin/bash
#SBATCH --job-name=guppy_basecall
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH -o guppy_%j.out
#SBATCH -e guppy_%j.err

module purge
module load singularity
module load guppy/6.5.7-gpu

nvidia-smi

guppy_basecaller \
    -i data_test/2022_02_01_MJ_ONT_A2058_untreated/ \
    -s guppy_out \
    -c dna_r9.4.1_450bps_hac.cfg \
    --device cuda:0 \
    --num_callers 8 \
    --cpu_threads_per_caller 2