#!/usr/bin/env bash
#SBATCH --job-name=filter_bdgs
#SBATCH --array=2-2
#SBATCH --cpus-per-task=4
#SBATCH --mem=34G
#SBATCH --partition=fast
#SBATCH -o filter_bams_%A_%a.out
#SBATCH -e filter_bams_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load samtools/1.21


set -euo pipefail

# ---- Config ----

### adapt the array size to the samples in the analysis!!!
SAMPLES_FILE="DNAscent_NanoPore_run4/bam_list_2.txt"            # one sample ID per line
DETECT_DIR="DNAscent_NanoPore_run4/dnascent/detect/detects"               # where DNAscent detect outputs are
BAM_DIR="DNAscent_NanoPore_run4/dnascent/detect/bams"               # where DNAscent detect outputs are
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
SAMPLE=$(basename "$BAM_PATH" | cut -d '.' -f 1 )

# Expected python output files:

echo "[Task $SLURM_ARRAY_TASK_ID] Processing sample $SAMPLE"




FILTERD_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.strict.sorted.${filter_cutoff}filtered.bdg"
FILTERD_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.strict.sorted.${filter_cutoff}filtered.bdg"

COUNT_EDU="${FILTERD_BDG_EDU}.count.txt"
COUNT_BRDU="${FILTERD_BDG_BRDU}.count.txt"

COUNT_readID_EDU="${FILTERD_BDG_EDU}.readID.count.txt"
COUNT_readID_BRDU="${FILTERD_BDG_BRDU}.readID.count.txt"
COUNT_readID_BE="${BDG_DIR}/${SAMPLE}.readID_B+E_.count.txt"

BAM_files="${BAM_DIR}/${SAMPLE}.sorted.bam"
filtered_BAM="${BAM_DIR}/${SAMPLE}.sorted_filtered${filter_cutoff}_B+E.bam"



# # ---- Step 1: count tracks from filtered bdgs (done in detect to bigwig script)  ----
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

# # ---- Step 2: bam filtering   ----
### filter BAM files for reads with at least 1 BrdU or EdU labeled bases over the filter_cutoff

samtools view -b -N \
  "$COUNT_readID_BE"  \
  "$BAM_files" \
  > "$filtered_BAM"  
samtools index \
  -b "$filtered_BAM"  


