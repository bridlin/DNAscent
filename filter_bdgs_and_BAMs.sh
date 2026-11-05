#!/usr/bin/env bash
#SBATCH --job-name=filter_bdgs
#SBATCH --array=2-2
#SBATCH --cpus-per-task=4
#SBATCH --mem=34G
#SBATCH --partition=fast
#SBATCH -o filter_bdgs_and_bams_%A_%a.out
#SBATCH -e filter_bdgs_and_bams_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load samtools/1.21


set -euo pipefail

# ---- Config ----
SAMPLES_FILE="DNAscent_NanoPore_run4/bam_list_2.txt"            # one sample ID per line
DETECT_DIR="DNAscent_NanoPore_run4/dnascent/detect/detects"               # where DNAscent detect outputs are
BDG_DIR="${DETECT_DIR}/bdg_q20l1000"
BW_DIR="${DETECT_DIR}/bigwig_q20l1000"
filter_cutoff=0.5

# ---- Resolve current sample ----
# 1) Get the BAM filename for this array task
BAM_PATH=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" $SAMPLES_FILE)

[[ -n "$BAM_PATH" ]] || {
    echo "No sample for task $SLURM_ARRAY_TASK_ID"
    exit 1
}

# Strip the directory
SAMPLE=$(basename "$BAM_PATH" | cut -d '.' -f 1,2,3 )

# Expected python output files:

echo "[Task $SLURM_ARRAY_TASK_ID] Processing sample $SAMPLE"


RAW_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.bdg"
RAW_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.bdg"

FILTERD_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.${filter_cutoff}filtered.bdg"
FILTERD_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.${filter_cutoff}filtered.bdg"

COUNT_EDU="${RAW_BDG_EDU}.count.txt"
COUNT_BRDU="${RAW_BDG_BRDU}.count.txt"

COUNT_readID_EDU="${RAW_BDG_EDU}readID.count.txt"
COUNT_readID_BRDU="${RAW_BDG_BRDU}readID.count.txt"
COUNT_readID_BE="${BDG_DIR}/${SAMPLE}readID_B+E_.count.txt"

BAM_files="${DETECT_DIR}/bams/${SAMPLE}.sorted.bam"
filtered_BAM="${DETECT_DIR}/bams/${SAMPLE}.sorted_filtered${filter_cutoff}_B+E.bam"



# # ---- Step 1: bedGraph filtering for filter_cutoff  ----
# EdU
if [[ ! -s "$FILTERD_BDG_EDU" ]]; then
  echo "filtering: $RAW_BDG_EDU -> $FILTERD_BDG_EDU"
  awk -v var1=$filter_cutoff '{ OFS="\t" } {if ($4 >= var1) print $0 }' "$RAW_BDG_EDU" > "$FILTERD_BDG_EDU"
else
  echo "filter exists, skipping: $FILTERD_BDG_EDU"
fi

# BrdU
if [[ ! -s "$FILTERD_BDG_BRDU" ]]; then
  echo "filtering: $RAW_BDG_BRDU -> $FILTERD_BDG_BRDU"
  awk -v var1=$filter_cutoff '{ OFS="\t" } {if ($4 >= var1) print $0 }' "$RAW_BDG_BRDU" > "$FILTERD_BDG_BRDU"
else
  echo "filter exists, skipping: $FILTERD_BDG_BRDU"
fi


# # ---- Step 2: count tracks   ----
# EdU
if [[ ! -s "$COUNT_EDU" ]]; then
  echo "counting tracks: $FILTERD_BDG_EDU -> $COUNT_EDU"
  cut -f 6  "$FILTERD_BDG_EDU" | sort | uniq -c > "$COUNT_EDU"
else
  echo "count exists, skipping: $COUNT_EDU"
fi

# BrdU
if [[ ! -s "$COUNT_BRDU" ]]; then
  echo "counting tracks: $FILTERD_BDG_BRDU -> $COUNT_BRDU"
  cut -f 6  "$FILTERD_BDG_BRDU" | sort | uniq -c > "$COUNT_BRDU"
else
  echo "count exists, skipping: $COUNT_BRDU"
fi

### get the read-ID for later bam filtering
cut -f 2 "$COUNT_BRDU" | sort | uniq >  "$COUNT_readID_BRDU" 
cut -f 2 "$COUNT_EDU"  | sort | uniq >  "$COUNT_readID_EDU" 

### fuse read ID for BrdU and EdU labered reads
cat  "$COUNT_readID_BRDU" "$COUNT_readID_EDU" | sort  | uniq > "$COUNT_readID_BE" 

# # ---- Step 3: bam filtering   ----
### filter BAM files for reads with at least 1 BrdU or EdU labeled bases over the filter_cutoff

samtools view -b -N \
  "$COUNT_readID_BE"  \
  "$BAM_files" \
  > "$filtered_BAM"  
samtools index \
  -b "$filtered_BAM"  


