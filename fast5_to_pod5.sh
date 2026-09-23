#!/usr/bin/env bash
#SBATCH --job-name=fast5_to_pod5
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --partition=fast
#SBATCH -o fast5_to_pod5_%A_%a.out
#SBATCH -e fast5_to_pod5_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load  pod5/0.3.27

export PYTHONNOUSERSITE=1

which pod5
which python

# ---- Config ----
FAST5_FILE="data_test/2022_02_01_MJ_ONT_A2058_untreated/" 
POD5_DIR="pod5_test"


pod5 convert fast5 ${FAST5_FILE} -o ${POD5_DIR}/reads.pod5