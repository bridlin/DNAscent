#!/bin/bash
#
#SBATCH -o basecall.%N.%j.out
#SBATCH -e basecall.%N.%j.err
#SBATCH --mail-type END
#SBATCH --mail-user b-barckmann@chu-montpellier.fr
#SBATCH --partition=gpu
#SBATCH --gres=gpu:l40s:2
#SBATCH --cpus-per-task=6
#SBATCH --mem=16G

module purge
module load singularity
module load cuda-toolkit/12.9.1
module load dorado/1.0.2

nvidia-smi

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing tool: $1"; exit 1; }; }

need singularity
#need cuda
need dorado




echo "output_dir = $output_dir"
echo "analysis name = $analysis_name"
echo "pod5 input = $pod5_dir"
echo "kit-name" = $kit_name

###############################################################################
# STEP 1 — Basecalling and demultiplexing
###############################################################################

# Classify during basecalling, then split without re-classifying
# Ref: Inline classification and --no-classify during demux. [2](https://software-docs.nanoporetech.com/dorado/latest/barcoding/barcoding/)
echo "Basecalling with inline barcoding..."
basecall_bam="$output_dir/basecall/${analysis_name}.bam"
# dorado basecaller "$model" "$pod5_dir" \
#     -x "$device" \
#     --kit-name "$kit_name" \
#     --no-trim \
#     > "$basecall_bam" \
#     2> "$output_dir/logs/basecaller.log"

# echo " Demultiplexing (split per barcode, no re-classification)..."
# dorado demux \
#   --output-dir "$output_dir/demux" \
#   --no-classify \
#   --emit-summary \
#   "$basecall_bam" \
#   2> "$output_dir/logs/demux.log"


# Prepare manifests for alignment
echo "Building manifest files for alignment..."
bash "scripts/DNAscent/helper/make_manifest_demux-bams.sh"
echo "Manifest generation completed."


###############################################################################
# STEP 2 — submitting Alignment array (depends on Step 1)
###############################################################################

echo "Submitting alignment array..."
N_ALIGN=$(wc -l < demux_list.txt)
ALIGN_JOBID=$(sbatch \
  --array=1-"$N_ALIGN"%20 \
  --parsable \
  --dependency=afterok:${SLURM_JOB_ID} \
  "scripts/DNAscent/step2_align_array.sh")

echo "   Alignment array job id: $ALIGN_JOBID"




