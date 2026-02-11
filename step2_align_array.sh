#!/usr/bin/env bash
#SBATCH --job-name=align_array
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH -o analyses/DNAscent_${analysis_name}/logs/align_%A_%a.out
#SBATCH -e analyses/DNAscent_${analysis_name}/logs/align_%A_%a.err



# Align each demultiplexed BAM to the reference. You can pass extra minimap2 flags via --mm2-opts.
# Ref: dorado aligner and mm2 options. [3](https://software-docs.nanoporetech.com/dorado/latest/basecaller/alignment/)

module load singularity
module load dorado/1.2.0
module load samtools/1.21

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

# Prepare manifests for alignment
echo "Building manifest files for DNAscent..."
bash "scripts/DNAscent/helper/make_manifest_demux-bams.sh"
echo "Manifest generation completed."



##############################################################################
# starting STEP 3 — DNAscent array (depends on Step 2)
###############################################################################

echo "Submitting DNAscent array (after alignment)..."
N_BAM=$(wc -l < bam_list.txt)
DNASCENT_JOBID=$(sbatch \
  --array=1-"$N_BAM"%20 \
  --parsable \
  --dependency=afterok:${ALIGN_JOBID} \
  "scripts/DNAscent/step3_dnascent_array.sh")
echo "   DNAscent array job id: $DNASCENT_JOBID"

echo "Submitted!  DNAscent → $DNASCENT_JOBID"

