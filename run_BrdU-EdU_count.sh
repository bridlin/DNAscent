#!/usr/bin/env bash
#SBATCH --job-name=count_BrdU-EdU
#SBATCH --array=0-9
#SBATCH --cpus-per-task=4
#SBATCH --mem=34G
#SBATCH --partition=fast
#SBATCH -o count_BrdU-EdU_%A_%a.out
#SBATCH -e count_BrdU-EdU_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load python


set -euo pipefail

# ---- Config ----
SAMPLES_FILE="DNAscent_NanoPore-run3/bam_list.txt"            # one sample ID per line
DETECT_DIR="DNAscent_NanoPore-run3/dnascent/detect/detects"               # where DNAscent detect outputs are



# ---- Resolve current sample ----
# 1) Get the BAM filename for this array task
BAM_PATH=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" $SAMPLES_FILE)

# Strip the directory

SAMPLE=$(basename "$BAM_PATH" .trimmed.aligned.sorted.bam)

# ---- Paths ----
DETECT_INPUT="${DETECT_DIR}/${SAMPLE}.detect"   # adapt extension to your DNAscent output


echo "counting BrdU and EdUin detect  files"
echo "Submitting ...Task ID: ${SLURM_ARRAY_TASK_ID}"


# ---- Step 1: DNAscent detect -> bedGraph (run Python if either strict file missing)
echo "counting BrdU and EdU labeling in detect files"
  # Call your converter. Adjust arguments if your script needs more.
python scripts/DNAscent/count_BrdU-EdU.py "$DETECT_INPUT" 0.5