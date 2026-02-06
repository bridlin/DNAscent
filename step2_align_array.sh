# =======================
# ======= ALIGN =========
# =======================

# Align each demultiplexed BAM to the reference. You can pass extra minimap2 flags via --mm2-opts.
# Ref: dorado aligner and mm2 options. [3](https://software-docs.nanoporetech.com/dorado/latest/basecaller/alignment/)
echo "Aligning per-barcode BAMs..."


for bam in "$output_dir/demux"/*.bam; do
    [ -e "$bam" ] || { echo "No demuxed BAMs found."; break; }
    bname="$(basename "$bam" .bam)"
    aligned_bam="$output_dir/aligned/${bname}.bam"

    dorado aligner "$reference" "$bam" \
      > "$aligned_bam" 2> "$output_dir/logs/${bname}_align.log"

  
    sorted_bam="$output_dir/aligned/${bname}.sorted.bam"
        samtools sort -@ "$threads" -o "$sorted_bam" "$aligned_bam"
        samtools index -@ "$threads" "$sorted_bam"
    rm -f "$aligned_bam"
    
    echo "Aligned: $bname"
; done





#!/usr/bin/env bash
#SBATCH --job-name=align_array
#SBATCH --array=1-$(wc -l < analyses/DNAscent_${analysis_name}/demux_list.txt)%20
#SBATCH --cpus-per-task=${threads_align}
#SBATCH --mem=${mem_align}
#SBATCH --partition=${partition}
#SBATCH -o analyses/DNAscent_${analysis_name}/logs/align_%A_%a.out
#SBATCH -e analyses/DNAscent_${analysis_name}/logs/align_%A_%a.err

# Align each demultiplexed BAM to the reference. You can pass extra minimap2 flags via --mm2-opts.
# Ref: dorado aligner and mm2 options. [3](https://software-docs.nanoporetech.com/dorado/latest/basecaller/alignment/)



set -euo pipefail

source "$(dirname "$0")/config.txt"   # for array context
demux_list="analyses/DNAscent_${analysis_name}/demux_list.txt"

bam=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$demux_list")
bname=$(basename "$bam" .bam)

aligned="$output_dir/aligned/${bname}.bam"
sorted="$output_dir/aligned/${bname}.sorted.bam"
mkdir -p "$output_dir/aligned"

echo "Aligning ${bname} ..."
dorado aligner "$reference" "$bam" > "$aligned" 2>> "$output_dir/logs/${bname}_align.log"

samtools sort -@ "$SLURM_CPUS_PER_TASK" -o "$sorted" "$aligned"
samtools index -@ "$SLURM_CPUS_PER_TASK" "$sorted"
rm -f "$aligned"

echo "Aligned: ${bname}"
