#!/usr/bin/env bash
#SBATCH --job-name=main_${USER}
#SBATCH --array=0-17
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=fast
#SBATCH -o main_%j.out
#SBATCH -e main_%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load python
module load ucsc-bedgraphtobigwig/377

set -euo pipefail

# ---- Config ----
SAMPLES_FILE="DNAscent_NanoPore-run1/bam_list.txt"            # one sample ID per line
DETECT_DIR="DNAscent_NanoPore-run1/dnascent/detect/"               # where DNAscent detect outputs are
BDG_DIR="bdg"
BW_DIR="bigwig"
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
RAW_BDG="${BDG_DIR}/${SAMPLE}.raw.bdg"
SORTED_BDG="${BDG_DIR}/${SAMPLE}.sorted.bdg"
CLIPPED_BDG="${BDG_DIR}/${SAMPLE}.clipped.bdg"
BW_OUT="${BW_DIR}/${SAMPLE}.bw"

mkdir -p logs "$BDG_DIR" "$BW_DIR" tmp


echo "Transforming DNAscent detect to bigwig files"
echo "Submitting detect to bigwig array...Task ID: ${SLURM_ARRAY_TASK_ID}"



# ---- Step 1: DNAscent detect -> bedGraph (call your Python) ----
if [[ ! -s "$RAW_BDG" ]]; then
  echo "Generating bedGraph from DNAscent detect: $DETECT_INPUT -> $RAW_BDG"
  python  scripts/DNAscent/detect_to_bdg.py "$DETECT_INPUT" \   
else
  echo "RAW_BDG exists, skipping generation: $RAW_BDG"
fi

# ---- Step 2: Ensure bedGraph is sorted and valid ----
# Sort by chrom and start; force LC_ALL=C for speed and consistent collation.
if [[ ! -s "$SORTED_BDG" ]]; then
  echo "Sorting bedGraph..."
  LC_ALL=C sort -k1,1 -k2,2n "$RAW_BDG" > "$SORTED_BDG"
fi

# Optional but recommended: Clip intervals to chrom sizes to avoid out-of-range errors.
# Requires 'bedClip' (UCSC). If not available, skip; but ensure your python script doesn't produce out-of-bound intervals.
if command -v bedClip >/dev/null 2>&1; then
  if [[ ! -s "$CLIPPED_BDG" ]]; then
    echo "Clipping bedGraph to chromosome sizes..."
    bedClip "$SORTED_BDG" "$CHROM_SIZES" "$CLIPPED_BDG"
  fi
  BDG_FOR_BW="$CLIPPED_BDG"
else
  echo "bedClip not found; proceeding without clipping."
  BDG_FOR_BW="$SORTED_BDG"
fi

# ---- Step 3: bedGraph -> bigWig ----
if [[ ! -s "$BW_OUT" ]]; then
  echo "Converting to bigWig: $BDG_FOR_BW -> $BW_OUT"
  bedGraphToBigWig "$BDG_FOR_BW" "$CHROM_SIZES" "$BW_OUT"
else
  echo "BigWig exists, skipping: $BW_OUT"
fi

echo "[$(date)] DONE sample=$SAMPLE"
``






















# Pass the array index to Python

python scrits/DNAscent/detect_to_bdg.py --task-id "${SLURM_ARRAY_TASK_ID}"


echo "Task $SLURM_ARRAY_TASK_ID running on sample: $SAMPLE"
echo "Full BAM path: $BAM_FILE"

# 3) Use SAMPLE everywhere else
python dnascent_detect_to_bdg.py \
    --input "$SAMPLE.detect.tsv" \
    --output "bdg/${SAMPLE}.bdg"

bedGraphToBigWig \
    "bdg/${SAMPLE}.bdg" \
    genome.chrom.sizes \
    "bigwig/${SAMPLE}.bw"
