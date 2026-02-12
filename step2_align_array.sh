#!/usr/bin/env bash
#SBATCH --job-name=align_array
#SBATCH --partition=fast
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH -o align_%A_%a.out
#SBATCH -e align_%A_%a.err



# Align each demultiplexed BAM to the reference. You can pass extra minimap2 flags via --mm2-opts.
# Ref: dorado aligner and mm2 options. [3](https://software-docs.nanoporetech.com/dorado/latest/basecaller/alignment/)

module purge
module load singularity
module load dorado/1.0.2
module load samtools/1.21

set -euo pipefail

 # for array context
demux_list="DNAscent_${analysis_name}/demux_list.txt"

bam=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$demux_list")
bname=$(basename "$bam" .bam)

trimmed="$output_dir/aligned/${bname}.trimmed.bam"
aligned="$output_dir/aligned/${bname}.trimmed.aligned.bam"
sorted="$output_dir/aligned/${bname}.trimmed.aligned.sorted.bam"

mkdir -p "$output_dir/aligned"

echo "trimming and aligning ${bname} ..."
echo $trimmed
echo $aligned
echo $sorted

# # 1) TRIM
# dorado trim "$bam" \
#   --sequencing-kit "$kit_name" \
#   > "$trimmed"

# # 2) ALIGN
# dorado aligner \
#   --threads "$SLURM_CPUS_PER_TASK" \
#   "$reference"\
#   "$trimmed" \
#   > "$aligned" \
#   2>> "$output_dir/logs/${bname}_align.log"

# samtools \
#   sort \
#   -@ "$SLURM_CPUS_PER_TASK" \
#   -o "$sorted" \
#   "$aligned"

# samtools \
#   index \
#   -@ "$SLURM_CPUS_PER_TASK" \
#   "$sorted"

# # rm -f "$aligned"

echo "trimmed and aligned: ${bname}"

# Prepare manifests for alignment
echo "Building manifest files for DNAscent..."
bash "scripts/DNAscent/helper/make_manifest_aligned_reads.sh"
echo "Manifest generation completed."



##############################################################################
# starting STEP 3 — DNAscent array (depends on Step 2)
###############################################################################

echo "Submitting DNAscent array (after alignment)..."
N_BAM=$(wc -l < $output_dir/bam_list.txt)
DNASCENT_JOBID=$(sbatch \
  --array=1-"$N_BAM"%20 \
  --parsable \
  --dependency=afterok:${SLURM_JOB_ID} \
  "scripts/DNAscent/step3_dnascent_array.sh")
echo "   DNAscent array job id: $DNASCENT_JOBID"

echo "Submitted!  DNAscent → $DNASCENT_JOBID"

