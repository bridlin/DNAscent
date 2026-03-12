#!/usr/bin/env bash
#SBATCH --job-name=main_${USER}
#SBATCH --array=1-17
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=fast
#SBATCH -o main_%A_%a.out
#SBATCH -e main_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load python
module load ucsc-bedgraphtobigwig/377
module load bedtools/2.31.1

set -euo pipefail

# ---- Config ----
SAMPLES_FILE="DNAscent_NanoPore-run1/bam_list.txt"            # one sample ID per line
DETECT_DIR="DNAscent_NanoPore-run1/dnascent/detect"               # where DNAscent detect outputs are
BDG_DIR="${DETECT_DIR}/bdg_2"
BW_DIR="${DETECT_DIR}/bigwig_2"
CHROM_SIZES="genome/TriTrypDB-55_TbruceiLister427_2018_Genome/TriTrypDB-55_TbruceiLister427_2018.chrom.sizes"      # precomputed chrom sizes for your reference



# ---- Resolve current sample ----
# 1) Get the BAM filename for this array task
BAM_PATH=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" $SAMPLES_FILE)

# Strip the directory
SAMPLE=$(basename "$BAM_PATH" | cut -d '.' -f 1,2,3 )

# Strip the extension
#SAMPLE=$(cut -d '.' -f 1,2,3 ${BAM_FILE})

# ---- Paths ----
DETECT_INPUT="${DETECT_DIR}/${SAMPLE}.detect"   # adapt extension to your DNAscent output



# Expected python output files:
BRDU="${DETECT_DIR}/${SAMPLE}.BrdU.bdg"
EDU="${DETECT_DIR}/${SAMPLE}.EdU.bdg"
BRDU_STRICT="${DETECT_DIR}/${SAMPLE}.BrdU.strict.bdg"
EDU_STRICT="${DETECT_DIR}/${SAMPLE}.EdU.strict.bdg"

echo "[Task $SLURM_ARRAY_TASK_ID] Processing sample $SAMPLE"

RAW_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.strict.bdg"
RAW_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.strict.bdg"

SORTED_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.sorted.bdg"
SORTED_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.sorted.bdg"

CLIPPED_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.clipped.bdg"
CLIPPED_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.clipped.bdg"

BDG_FOR_BW_EDU="${BDG_DIR}/${SAMPLE}.EdU.merged.bdg"
BDG_FOR_BW_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.merged.bdg"

BW_OUT_EDU="${BW_DIR}/${SAMPLE}.EdU.bw"
BW_OUT_BRDU="${BW_DIR}/${SAMPLE}.BrdU.bw"


mkdir -p logs "$BDG_DIR" "$BW_DIR" tmp

echo "Transforming DNAscent detect to bigwig files"
echo "Submitting detect to bigwig array...Task ID: ${SLURM_ARRAY_TASK_ID}"

# ---- Step 1: DNAscent detect -> bedGraph (call your Python) ----
if [[ ! -s "$RAW_BDG_BRDU" ]]; then
  echo "Generating bedGraph from DNAscent detect: $DETECT_INPUT -> $BRDU , $EDU, $BRDU_STRICT and $EDU_STRICT"
  python  scripts/DNAscent/detect_to_bdg.py "$DETECT_INPUT" \   
else
  echo "RAW_BDG exists, skipping generation: $RAW_BDG_BRDU"
fi


# Move all 4 files into BDG_DIR
mv "$BRDU" "$BDG_DIR/"
mv "$EDU" "$BDG_DIR/"
mv "$BRDU_STRICT" "$BDG_DIR/"
mv "$EDU_STRICT" "$BDG_DIR/"



# ---- Step 2: Ensure bedGraph is sorted and valid ----
# Sort by chrom and start; force LC_ALL=C for speed and consistent collation.
# EdU

if [[ ! -s "$SORTED_BDG_EDU" ]]; then
  echo "Sorting bedGraph..."
  LC_ALL=C sort -k1,1 -k2,2n "$RAW_BDG_EDU" > "$SORTED_BDG_EDU"
fi
# BrdU
if [[ ! -s "$SORTED_BDG_BRDU" ]]; then
  echo "Sorting bedGraph..."
  LC_ALL=C sort -k1,1 -k2,2n "$RAW_BDG_BRDU" > "$SORTED_BDG_BRDU"
fi



# Optional but recommended: Clip intervals to chrom sizes to avoid out-of-range errors.
# Requires 'bedClip' (UCSC). If not available, skip; but ensure your python script doesn't produce out-of-bound intervals.
# EdU

if command -v bedClip >/dev/null 2>&1; then
  if [[ ! -s "$CLIPPED_BDG_EDU" ]]; then
    echo "Clipping bedGraph to chromosome sizes..."
    bedClip "$SORTED_BDG_EDU" "$CHROM_SIZES" "$CLIPPED_BDG_EDU"
  fi
  BDG_FOR_merge_EDU="$CLIPPED_BDG_EDU"
else
  echo "bedClip not found; proceeding without clipping."
  BDG_FOR_merge_EDU="$SORTED_BDG_EDU"
fi
# BrdU
if command -v bedClip >/dev/null 2>&1; then
  if [[ ! -s "$CLIPPED_BDG_BRDU" ]]; then
    echo "Clipping bedGraph to chromosome sizes..."
    bedClip "$SORTED_BDG_BRDU" "$CHROM_SIZES" "$CLIPPED_BDG_BRDU"
  fi
  BDG_FOR_merge_BRDU="$CLIPPED_BDG_BRDU"
else
  echo "bedClip not found; proceeding without clipping."
  BDG_FOR_merge_BRDU="$SORTED_BDG_BRDU"
fi




# # ---- Step 3: bedGraph merge  ----
# EdU
if [[ ! -s "$BDG_FOR_BW_EDU" ]]; then
  echo "merging: $BDG_FOR_merge_EDU -> $BDG_FOR_BW_EDU"
  bedtools merge -d -1 -i "$BDG_FOR_merge_EDU" -c 4 -o mean >  "$BDG_FOR_BW_EDU"
else
  echo "merge exists, skipping: $BDG_FOR_BW_EDU"
fi




# BrdU
if [[ ! -s "$BDG_FOR_BW_BRDU" ]]; then
  echo "merging: $BDG_FOR_merge_BRDU -> $BDG_FOR_BW_BRDU"
  bedtools merge -d -1 -i "$BDG_FOR_merge_BRDU" -c 4 -o mean >  "$BDG_FOR_BW_BRDU"
else
  echo "merge exists, skipping: $BDG_FOR_BW_BRDU"
fi






# ---- Step 4: bedGraph -> bigWig ----
# EdU
if [[ ! -s "$BW_OUT_EDU" ]]; then
  echo "Converting to bigWig: $BDG_FOR_BW_EDU -> $BW_OUT_EDU"
  bedGraphToBigWig "$BDG_FOR_BW_EDU" "$CHROM_SIZES" "$BW_OUT_EDU"
else
  echo "BigWig exists, skipping: $BW_OUT_EDU"
fi

echo "[$(date)] DONE EDU sample=$SAMPLE"




# BrdU
if [[ ! -s "$BW_OUT_BRDU" ]]; then
  echo "Converting to bigWig: $BDG_FOR_BW_BRDU -> $BW_OUT_BRDU"
  bedGraphToBigWig "$BDG_FOR_BW_BRDU" "$CHROM_SIZES" "$BW_OUT_BRDU"
else
  echo "BigWig exists, skipping: $BW_OUT_BRDU"
fi

echo "[$(date)] DONE BRDU sample=$SAMPLE"
``






















