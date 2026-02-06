#!/usr/bin/env bash
#SBATCH --job-name=dnascent_array
#SBATCH --array=1-$(wc -l < analyses/DNAscent_${analysis_name}/bam_list.txt)%20
#SBATCH --cpus-per-task=${threads_detect}
#SBATCH --mem=${mem_detect}
#SBATCH --partition=${partition}
#SBATCH -o analyses/DNAscent_${analysis_name}/logs/dnascent_%A_%a.out
#SBATCH -e analyses/DNAscent_${analysis_name}/logs/dnascent_%A_%a.err

set -euo pipefail

source "$(dirname "$0")/config.txt"
bam_list="analyses/DNAscent_${analysis_name}/bam_list.txt"

dnascent_index_dir=$output_dir/dnascent/index

bam=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$bam_list")
sample=$(basename "$bam" .sorted.bam)

# Build DNAscent pod5-based index once (safe to call every task; use a guard file)
mkdir -p "$dnascent_index_dir"
if [[ ! -f "$dnascent_index_dir/.built.ok" ]]; then
  # Only task 1 attempts index; others wait with a simple spin (or skip)
  if [[ "${SLURM_ARRAY_TASK_ID}" == "1" ]]; then
    echo "Building DNAscent POD5 index ..."
    apptainer exec \
      -B "$pod5_dir":/pod5 \
      -B "$dnascent_index_dir":/index \
      "$container_sif" \
      DNAscent index --pod5 /pod5 --out /index
    touch "$dnascent_index_dir/.built.ok"
  else
    echo "Waiting for DNAscent index ..."
    for i in {1..120}; do
      [[ -f "$dnascent_index_dir/.built.ok" ]] && break
      sleep 30
    done
  fi
fi

mkdir -p "$output_dir/dnascent"

echo "DNAscent detect for ${sample} ..."
apptainer exec \
  -B "$output_dir/aligned":/aligned \
  -B "$reference":/ref/reference.fa \
  -B "$dnascent_index_dir":/index \
  -B "$output_dir/dnascent":/out \
  "$container_sif" \
  DNAscent detect \
    --bam /aligned/${sample}.sorted.bam \
    --ref /ref/reference.fa \
    --index /index \
    --out /out/${sample} \
    --threads "$SLURM_CPUS_PER_TASK"

echo "DNAscent done: ${sample}"
