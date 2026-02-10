#!/bin/bash
#
#SBATCH -o slurm.%N.%j.out
#SBATCH -e slurm.%N.%j.err
#SBATCH --mail-type END
#SBATCH --mail-user b-barckmann@chu-montpellier.fr
#SBATCH --partition=bigmem
#SBATCH --cpus-per-task=16
#SBATCH --mem=180G


module load singularity
module load cuda-toolkit/12.9.1
module load dorado/1.2.0

echo "output_dir = $output_dir"
echo "analysis name = $analysis_name"
echo "pod5 input = $pod5_dir"


# =======================
# ==== BASECALL + DEMUX =
# =======================

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing tool: $1"; exit 1; }; }

need singularity
#need cuda
need dorado


# Classify during basecalling, then split without re-classifying
# Ref: Inline classification and --no-classify during demux. [2](https://software-docs.nanoporetech.com/dorado/latest/barcoding/barcoding/)
echo "Basecalling with inline barcoding..."
basecall_bam="$output_dir/basecall/${analysis_name}.bam"
dorado basecaller "$model" "$pod5_dir" \
    -x cpu \
    --batchsize 16 \
    --kit-name "$kit_name" \
    > "$basecall_bam" 2> "$output_dir/logs/basecaller.log"

echo " Demultiplexing (split per barcode, no re-classification)..."
dorado demux \
    --output-dir "$output_dir/demux" \
    --no-classify \
    "$basecall_bam" \
    --emit-summary \
    2> "$output_dir/logs/demux.log"










