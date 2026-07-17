#!/bin/bash
#SBATCH --mail-type END
#SBATCH --mail-user b-barckmann@chu-montpellier.fr
#SBATCH --partition=gpu
#SBATCH --gres=gpu:l40s:2
#SBATCH --cpus-per-task=6
#SBATCH --mem=16G
#SBATCH --job-name=basecall_
#SBATCH --output=slurm_log/%x_%A_%a.out
#SBATCH --error=slurm_log/%x_%A_%a.err

set -euo pipefail



module purge
module load singularity
module load cuda-toolkit/12.9.1
module load dorado/1.4.0

nvidia-smi

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing tool: $1"; exit 1; }; }

need singularity
#need cuda
need dorado




echo "output_dir = $output_dir"
echo "analysis name = $analysis_name"
echo "pod5 input = $pod5_dir"
echo "kit-name" = $kit_name


echo "===== DEBUG ====="
hostname
pwd

echo "pod5_dir=$pod5_dir"

ls -ld "$pod5_dir"

find "$pod5_dir" -name "*.pod5" | head

find "$pod5_dir" -name "*.pod5" | wc -l

echo "================="

FILE=$(find "$pod5_dir" -name "*.pod5" | head -1)

echo "TEST FILE=$FILE"

pod5 inspect summary "$FILE"


echo "===== test basecalling ====="

FILE=/shared/projects2/mivegec_analysis_sns_seq/pod5_run3/FBE77896_b1ba7c8d_a9590380_10.pod5

dorado basecaller \
    "$model" \
    "$FILE" \
    -x "$device" \
    > single_test.bam \
    2> single_test.log

echo $?
cat single_test.log
ls -lh single_test.bam



echo "================="


###############################################################################
# STEP 1 — Basecalling and demultiplexing
###############################################################################

# Classify during basecalling, then split without re-classifying
# Ref: Inline classification and --no-classify during demux. [2](https://software-docs.nanoporetech.com/dorado/latest/barcoding/barcoding/)
echo "Basecalling with inline barcoding..."
basecall_bam="$output_dir/basecall/${analysis_name}.bam"
dorado basecaller "$model" "$pod5_dir" \
    -x "$device" \
    --kit-name "$kit_name" \
    --no-trim \
    > "$basecall_bam" \
    2> "$output_dir/logs/basecaller.log"
    
echo " Demultiplexing (split per barcode, no re-classification)..."
dorado demux \
  --output-dir "$output_dir/demux" \
  --emit-summary \
  --no-classify \
  "$basecall_bam" \
  2> "$output_dir/logs/demux.log"








