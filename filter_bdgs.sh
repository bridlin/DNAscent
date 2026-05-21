#!/usr/bin/env bash
#SBATCH --job-name=filter_bdgs
#SBATCH --array=0-6
#SBATCH --cpus-per-task=4
#SBATCH --mem=34G
#SBATCH --partition=fast
#SBATCH -o filter_bdgs_%A_%a.out
#SBATCH -e filter_bdgs_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge


set -euo pipefail

# ---- Config ----
SAMPLES_FILE="DNAscent_NanoPore-run2/bam_list.txt"            # one sample ID per line
DETECT_DIR="DNAscent_NanoPore-run2/dnascent/detect/detects"               # where DNAscent detect outputs are
BDG_DIR="${DETECT_DIR}/bdg_q15l500"
BW_DIR="${DETECT_DIR}/bigwig_q15l500"


# ---- Resolve current sample ----
# 1) Get the BAM filename for this array task
BAM_PATH=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" $SAMPLES_FILE)

# Strip the directory
SAMPLE=$(basename "$BAM_PATH" | cut -d '.' -f 1,2,3 )

# Expected python output files:



echo "[Task $SLURM_ARRAY_TASK_ID] Processing sample $SAMPLE"





RAW_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.bdg"
RAW_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.bdg"

FILTERD_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.filtered.bdg"
FILTERD_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.filtered.bdg"


COUNT_EDU="${RAW_BDG_EDU}.count.txt"
COUNT_BRDU="${RAW_BDG_BRDU}.count.txt"





# # ---- Step 1: bedGraph filtering for p 0.3  ----
# EdU
if [[ ! -s "$FILTERD_BDG_EDU" ]]; then
  echo "filtering: $RAW_BDG_EDU -> $FILTERD_BDG_EDU"
  awk  '{ OFS="\t" } {if ($4 >= 0.3) print $0 }' "$RAW_BDG_EDU" > "$FILTERD_BDG_EDU"
else
  echo "filter exists, skipping: $FILTERD_BDG_EDU"
fi


# BrdU
if [[ ! -s "$FILTERD_BDG_BRDU" ]]; then
  echo "filtering: $RAW_BDG_BRDU -> $FILTERD_BDG_BRDU"
  awk  '{ OFS="\t" } {if ($4 >= 0.3) print $0 }' "$RAW_BDG_BRDU" > "$FILTERD_BDG_BRDU"
else
  echo "filter exists, skipping: $FILTERD_BDG_BRDU"
fi


# # ---- Step 2: count track lenghts  ----
# EdU
if [[ ! -s "$COUNT_EDU" ]]; then
  echo "counting tracks: $FILTERD_BDG_EDU -> $COUNT_EDU"
  cut -f6  "$FILTERD_BDG_EDU" | sort | uniq -c > "$COUNT_EDU"
else
  echo "count exists, skipping: $COUNT_EDU"
fi




    
# BrdU
if [[ ! -s "$COUNT_BRDU" ]]; then
  echo "counting tracks: $FILTERD_BDG_BRDU -> $COUNT_BRDU"
  cut -f6  "$FILTERD_BDG_BRDU" | sort | uniq -c > "$COUNT_BRDU"
else
  echo "count exists, skipping: $COUNT_BRDU"
fi





