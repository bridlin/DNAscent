#!/usr/bin/env bash
#SBATCH --job-name=align_array
#SBATCH --partition=fast
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --job-name=align_
#SBATCH --output=slurm_log/%x_%A_%a.out
#SBATCH --error=slurm_log/%x_%A_%a.err



# Align each demultiplexed BAM to the reference. You can pass extra minimap2 flags via --mm2-opts.
# Ref: dorado aligner and mm2 options. [3](https://software-docs.nanoporetech.com/dorado/latest/basecaller/alignment/)

module purge
module load singularity
module load dorado/1.0.2
module load samtools/1.21

set -euo pipefail

 # for array context
demux_list="$output_dir/demux_list.txt"

bam=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$demux_list")
bname=$(basename "$bam" .bam)

IDX=${SLURM_ARRAY_TASK_ID}

# Read the line for this index
LINE=$(sed -n "${IDX}p" "$output_dir/demux_list.txt" || true)

# If empty → no sample for this index → exit safely
if [[ -z "${LINE:-}" ]]; then
    echo "Index ${IDX}: no entry found in demux_list.txt → skipping."
    exit 0
fi




trimmed="$output_dir/aligned/${bname}.trimmed.bam"
aligned="$output_dir/aligned/${bname}.trimmed.aligned.bam"
sorted="$output_dir/aligned/${bname}.trimmed.aligned.sorted.bam"

mkdir -p "$output_dir/aligned"

echo "trimming and aligning ${bname} ..."
echo $trimmed
echo $aligned
echo $sorted

# 1) TRIM
dorado trim "$bam" \
  --sequencing-kit "$kit_name" \
  > "$trimmed"

# 2) ALIGN
dorado aligner \
  --threads "$SLURM_CPUS_PER_TASK" \
  "$reference"\
  "$trimmed" \
  > "$aligned" \
  2>> "$output_dir/logs/${bname}_align.log"

samtools \
  sort \
  -@ "$SLURM_CPUS_PER_TASK" \
  -o "$sorted" \
  "$aligned"

samtools \
  index \
  -@ "$SLURM_CPUS_PER_TASK" \
  "$sorted"

# rm -f "$aligned"

echo "trimmed and aligned: ${bname}"




