#!/usr/bin/env bash
#SBATCH --job-name=detect_to_bigwig
#SBATCH --array=0-3
#SBATCH --cpus-per-task=4
#SBATCH --mem=34G
#SBATCH --partition=fast
#SBATCH -o detect_to_bigwig_%A_%a.out
#SBATCH -e detect_to_bigwig_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load python/3.12

