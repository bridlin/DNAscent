#!/usr/bin/env bash
#SBATCH --job-name=make_parquets
#SBATCH --cpus-per-task=4
#SBATCH --mem=34G
#SBATCH --partition=fast
#SBATCH -o make_parquets_%A_%a.out
#SBATCH -e make_parquets_%A_%a.err

module purge
module load python/3.12

detect_dir="DNAscent_NanoPore_run4/dnascent/detect/detects"               # where DNAscent detect outputs are


python make_read_table.py "$detect_dir"

python make_signal_table.py "$detect_dir"