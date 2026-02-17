#!/usr/bin/env bash
#SBATCH --job-name=dnascent_array
#SBATCH --partition=gpu
#SBATCH --gres=gpu:l40s:2
#SBATCH --cpus-per-task=6
#SBATCH --mem=16G
#SBATCH --job-name=dnascent_${USER}
#SBATCH --output=slurm_log/%x_%A_%a.out
#SBATCH --error=slurm_log/%x_%A_%a.err

module purge
module load cuda-toolkit/12.9.1
module load apptainer/1.3.6

set -euo pipefail

#source "$(dirname "$0")/config.txt"
bam_list="$output_dir/bam_list.txt"



IDX=${SLURM_ARRAY_TASK_ID}

# Read the line for this array index
LINE=$(sed -n "${IDX}p" "$output_dir/bam_list.txt" || true)

# If empty → no sample for this array index → exit safely
if [[ -z "${LINE:-}" ]]; then
    echo "Index ${IDX}: no entry found in bam_list.txt → skipping."
    exit 0
fi


echo $dnascent_index_dir
echo $reference
echo $container_sif

bam=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$bam_list")
sample=$(basename "$bam" .sorted.bam)



mkdir -p "$output_dir/dnascent/detect"

echo "DNAscent detect for ${sample} ..."
# apptainer exec \
#   -B "$output_dir/aligned":/aligned \
#   -B "$reference":/ref/reference.fa \
#   -B "$dnascent_index_dir":/index \
#   -B "$output_dir/dnascent/detect":/out \
#   -B "$pod5_dir":/pod5 \
#   "$container_sif" \
#   /app/DNAscent/bin/DNAscent detect \
#     --bam /aligned/${sample}.sorted.bam \
#     --reference /ref/reference.fa \
#     --index /index/pod.index \
#     --output /out/${sample}.bam \
#     --threads "$SLURM_CPUS_PER_TASK" 


echo "DNAscent done: ${sample}"



