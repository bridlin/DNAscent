#!/usr/bin/env bash
#SBATCH --job-name=detect_to_bigwig
#SBATCH --array=0-5
#SBATCH --cpus-per-task=4
#SBATCH --mem=34G
#SBATCH --partition=fast
#SBATCH -o detect_to_bigwig_%A_%a.out
#SBATCH -e detect_to_bigwig_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load python
module load ucsc-bedgraphtobigwig/377
module load bedtools/2.31.1

set -euo pipefail

# ---- Config ----
SAMPLES_FILE="DNAscent_NanoPore-run3/bam_list.txt"            # one sample ID per line
DETECT_DIR="DNAscent_NanoPore-run3/dnascent/detect/detects"               # where DNAscent detect outputs are
BDG_DIR="${DETECT_DIR}/bdg_q20l1000_3"
BW_DIR="${DETECT_DIR}/bigwig_q20l1000_3"
CHROM_SIZES="genome/TriTrypDB-55_TbruceiLister427_2018_Genome/TriTrypDB-55_TbruceiLister427_2018.chrom.sizes"      # precomputed chrom sizes for your reference

mkdir -p logs "$BDG_DIR" "$BW_DIR" tmp

# ---- Resolve current sample ----
# 1) Get the BAM filename for this array task
BAM_PATH=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" $SAMPLES_FILE)

# Strip the directory

SAMPLE=$(basename "$BAM_PATH" .trimmed.aligned.sorted.bam)



# ---- Paths ----
DETECT_INPUT="${DETECT_DIR}/${SAMPLE}.detect"   # adapt extension to your DNAscent output



# Expected python output files:
BRDU="${DETECT_DIR}/${SAMPLE}.BrdU.bdg"
EDU="${DETECT_DIR}/${SAMPLE}.EdU.bdg"
BRDU_STRICT="${DETECT_DIR}/${SAMPLE}.BrdU.strict.bdg"
EDU_STRICT="${DETECT_DIR}/${SAMPLE}.EdU.strict.bdg"

echo "[Task $SLURM_ARRAY_TASK_ID] Processing sample $SAMPLE"

BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.bdg"
BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.bdg"
BDG_BRDU_STRICT="${BDG_DIR}/${SAMPLE}.BrdU.strict.bdg"
BDG_EDU_STRICT="${BDG_DIR}/${SAMPLE}.EdU.strict.bdg"

SORTED_STRICT_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.strict.sorted.bdg"
SORTED_STRICT_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.strict.sorted.bdg"

SORTED_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.sorted.bdg"
SORTED_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.sorted.bdg"

BDG_FILTERED_EDU="${BDG_DIR}/${SAMPLE}.EdU.sorted.filtered.bdg"
BDG_FILTERED_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.sorted.filtered.bdg"

BDG_STRICT_FILTERED_EDU="${BDG_DIR}/${SAMPLE}.EdU.strict.sorted.filtered.bdg"
BDG_STRICT_FILTERED_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.strict.sorted.filtered.bdg"

BDG_MERGED_EDU="${BDG_DIR}/${SAMPLE}.EdU.strict.sorted.merged.bdg"
BDG_MERGED_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.strict.sorted.merged.bdg"

BW_OUT_EDU="${BW_DIR}/${SAMPLE}.EdU.bw"
BW_OUT_BRDU="${BW_DIR}/${SAMPLE}.BrdU.bw"

echo "Transforming DNAscent detect to bigwig files"
echo "Submitting detect to bigwig array...Task ID: ${SLURM_ARRAY_TASK_ID}"




# ---- Step 1: DNAscent detect -> bedGraph (run Python if either strict file missing)
if [[ ! -s "$BRDU_STRICT" || ! -s "$EDU_STRICT" ]]; then
  echo "[Step 1] Generating bedGraph from DNAscent detect -> BrdU/EdU strict"
  # Call your converter. Adjust arguments if your script needs more.
  python scripts/DNAscent/detect_to_bdg.py "$DETECT_INPUT"

  # Move outputs into BDG_DIR if they were written to DETECT_DIR
  for src in "$BRDU" "$EDU" "$BRDU_STRICT" "$EDU_STRICT"; do
    [[ -e "$src" ]] || continue  # skip if not created in DETECT_DIR
    dst="$BDG_DIR/$(basename "$src")"
    if [[ -s "$dst" ]]; then
      echo "[Step 1] $dst already present; removing duplicate at source."
      rm -f -- "$src"
    else
      echo "[Step 1] Moving $(basename "$src") -> $BDG_DIR/"
      mv -f -- "$src" "$dst"
    fi
  done
else
  echo "[Step 1] Raw strict bedGraphs already present, skipping generation."
fi




# ---- Step 2: Ensure bedGraph is sorted and valid ----
# Sort by chrom and start; force LC_ALL=C for speed and consistent collation.
# EdU

if [[ ! -s "$SORTED_STRICT_BDG_EDU" ]]; then
  echo "Sorting bedGraph..."
  LC_ALL=C sort -k1,1 -k2,2n "$BDG_EDU_STRICT" > "$SORTED_STRICT_BDG_EDU"
fi
# BrdU
if [[ ! -s "$SORTED_STRICT_BDG_BRDU" ]]; then
  echo "Sorting bedGraph..."
  LC_ALL=C sort -k1,1 -k2,2n "$BRDU_STRICT" > "$SORTED_STRICT_BDG_BRDU"
fi


if [[ ! -s "$SORTED_BDG_EDU" ]]; then
  echo "Sorting bedGraph..."
  LC_ALL=C sort -k1,1 -k2,2n "$BDG_EDU" > "$SORTED_BDG_EDU"
fi
# BrdU
if [[ ! -s "$SORTED_BDG_BRDU" ]]; then
  echo "Sorting bedGraph..."
  LC_ALL=C sort -k1,1 -k2,2n "$BRDU" > "$SORTED_BDG_BRDU"
fi



# # ---- Step 3: bedGraph filtering  ----
# EdU
awk  '{ OFS="\t" } {if ($4 >= 0.5) print $0 }' "$SORTED_STRICT_BDG_EDU" > "$BDG_STRICT_FILTERED_EDU"

# BrdU
awk  '{ OFS="\t" } {if ($4 >= 0.5) print $0 }' "$SORTED_STRICT_BDG_BRDU" > "$BDG_STRICT_FILTERED_BRDU"


# EdU
awk  '{ OFS="\t" } {if ($4 >= 0.5) print $0 }' "$SORTED_BDG_EDU" > "$BDG_FILTERED_EDU"

# BrdU
awk  '{ OFS="\t" } {if ($4 >= 0.5) print $0 }' "$SORTED_BDG_BRDU" > "$BDG_FILTERED_BRDU"



# # ---- Step 4: bedGraph merge  ----
# EdU



if [[ ! -s "$BDG_MERGED_EDU" ]]; then
  echo "merging: $BDG_STRICT_FILTERED_EDU -> $BDG_MERGED_EDU"
  bedtools merge -d -1 -i "$BDG_STRICT_FILTERED_EDU" -c 4 -o mean > "$BDG_MERGED_EDU"
else
  echo "merge exists, skipping: $BDG_MERGED_EDU"
fi

# BrdU
if [[ ! -s "$BDG_MERGED_BRDU" ]]; then
  echo "merging: $BDG_STRICT_FILTERED_BRDU -> $BDG_MERGED_BRDU"
  bedtools merge -d -1 -i "$BDG_STRICT_FILTERED_BRDU" -c 4 -o mean > "$BDG_MERGED_BRDU"
else
  echo "merge exists, skipping: $BDG_MERGED_BRDU"
fi



# ---- Step 4: bedGraph -> bigWig ----
# EdU
if [[ ! -s "$BW_OUT_EDU" ]]; then
  echo "Converting to bigWig: $BDG_MERGED_EDU -> $BW_OUT_EDU"
  bedGraphToBigWig "$BDG_MERGED_EDU" "$CHROM_SIZES" "$BW_OUT_EDU"
else
  echo "BigWig exists, skipping: $BW_OUT_EDU"
fi

echo "[$(date)] DONE EDU sample=$SAMPLE"

# BrdU
if [[ ! -s "$BW_OUT_BRDU" ]]; then
  echo "Converting to bigWig: $BDG_MERGED_BRDU -> $BW_OUT_BRDU"
  bedGraphToBigWig "$BDG_MERGED_BRDU" "$CHROM_SIZES" "$BW_OUT_BRDU"
else
  echo "BigWig exists, skipping: $BW_OUT_BRDU"
fi

echo "[$(date)] DONE BRDU sample=$SAMPLE"
``


``






















