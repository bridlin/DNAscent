#!/usr/bin/env bash
#SBATCH --partition=gpu
#SBATCH --cpus-per-task=6
#SBATCH --mem=32G
#SBATCH --job-name=forksense_
#SBATCH --output=%x.out
#SBATCH --error=%x.err


module purge
module load cuda-toolkit/12.9.1
module load apptainer/1.3.6

set -euo pipefail


output_dir="DNAscent_DNAscent_NanoPore_jones_guppy"
container_sif="dnascent_tools/containers/mboemo_dnascent_dnascent_3.1.2.sif"  
detect_dir="$output_dir/dnascent/detect"
sample="A2058_untreated"  # sample name passed as first argument


echo $container_sif
echo $detect_dir


# Before apptainer exec, create a per-sample outdir
sample_out="$output_dir/dnascent/forksense/${sample}"
mkdir -p "$sample_out"

echo "DNAscent forkSense for ${sample} ..."

# Optional pre-run debug: list current contents of sample_out
echo "[DEBUG pre] Contents of ${sample_out}:"
ls -l "$sample_out" || true

apptainer exec \
  --pwd /out \
  -B "$sample_out":/out \
  -B "$detect_dir":/detect \
  "$container_sif" \
  /app/DNAscent/bin/DNAscent forkSense \
    --detect /detect/${sample}.detect \
    --output /out/${sample} \
    --order EdU,BrdU \
    --markAnalogues \
    --markOrigins \
    --markTerminations \
    --markForks \
    --threads "$SLURM_CPUS_PER_TASK"

# Optional post-run debug: verify outputs landed in the per-sample dir
echo "[DEBUG post] Contents of ${sample_out}:"
ls -l "$sample_out" || true

echo "DNAscent forkSense done: ${sample} → ${sample_out}"