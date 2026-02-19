#!/usr/bin/env bash
#SBATCH --job-name=dnascent_array
#SBATCH --partition=gpu
#SBATCH --gres=gpu:l40s:2
#SBATCH --cpus-per-task=6
#SBATCH --mem=16G
#SBATCH --job-name=forksense_
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

detect_dir="$output_dir/dnascent/detect"

echo $container_sif
echo $detect_dir




bam=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$bam_list")
sample=$(basename "$bam" .sorted.bam)


# Before apptainer exec, create a per-sample outdir
sample_out="$output_dir/dnascent/forksense/${sample}"
mkdir -p "$sample_out"


echo "DNAscent forkSense for ${sample} ..."
apptainer exec \
    # List what forkSense created for this sample
    echo "[DEBUG] Contents of ${sample_out}:" \
    ls -l "$sample_out" || true \
    --pwd /out \
    -B "$sample_out":/out \
    -B "$detect_dir":/detect \
  "$container_sif" \
  /app/DNAscent/bin/DNAscent forkSense \
    --detect /detect/${sample}.bam \
    --output /out/${sample} \
    --order BrdU,EdU \
    --markAnalogues \
    --markOrigins \
    --markTerminations \
    --markForks \
    --threads "$SLURM_CPUS_PER_TASK" 


echo "DNAscent forkSense done: ${sample}"
