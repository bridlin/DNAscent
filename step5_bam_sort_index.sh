#!/usr/bin/env bash
#SBATCH --job-name=align_array
#SBATCH --partition=fast
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --job-name=sort_
#SBATCH --output=slurm_log/%x_%A_%a.out
#SBATCH --error=slurm_log/%x_%A_%a.err

module purge
module load samtools/1.21

set -euo pipefail



bam_list="$output_dir/bam_list.txt"

IDX=${SLURM_ARRAY_TASK_ID}

# Read the line for this array index
LINE=$(sed -n "${IDX}p" "$output_dir/bam_list.txt" || true)

# If empty → no sample for this array index → exit safely
if [[ -z "${LINE:-}" ]]; then
    echo "Index ${IDX}: no entry found in bam_list.txt → skipping."
    exit 0
fi




demux_list="$output_dir/demux_list.txt"

bam_detect_dir="$output_dir/dnascent/detect"

bam=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$demux_list")
bname=$(basename "$bam" .bam)

detect="$bam_detect_dir/${bname}.trimmed.aligned.bam"
sorted="$bam_detect_dir/${bname}.trimmed.aligned.sorted.bam"




samtools \
  sort \
  -@ "$SLURM_CPUS_PER_TASK" \
  -o "$sorted" \
  "$detect"

samtools \
  index \
  -@ "$SLURM_CPUS_PER_TASK" \
  "$sorted"