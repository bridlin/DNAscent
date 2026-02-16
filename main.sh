#!/usr/bin/env bash
#SBATCH --job-name=main_${USER}
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --partition=fast
#SBATCH -o main_%j.out
#SBATCH -e main_%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr


set -euo pipefail

# Source config
source scripts/DNAscent/config.txt

# Export so child sbatch jobs can reuse variables
export analysis_name pod5_dir reference kit_name model device \
       container_sif dnascent_index_dir threads_align threads_detect \
       partition mem_align mem_detect output_dir dnascent_index_dir


# check tools
bash "scripts/DNAscent/helper/check_tools.sh"

echo "Starting pipeline for $analysis_name"
echo "Output dir: $output_dir"

# pull DNAscent container if missing
if [[ ! -f "$container_sif" ]]; then
  mkdir -p "$(dirname "$container_sif")"
  echo "Pulling container → $container_sif"
  apptainer pull "$container_sif" docker://gerlichlab/dnascent-docker:version-2.0
fi


###############################################################################
# STEP 1 — Basecalling + Demux
###############################################################################

echo "Step 1: Basecall + demux"
echo "Submitting Step 1: Basecall + demux..."

BASECALL_JOBID=$(sbatch \
  --parsable "scripts/DNAscent/step1_basecall_demux.sh")

echo "   basecalling and demux job id: $BASECALL_JOBID"

################ Prepare manifests for alignment ################
echo "Building manifest files for alignment..."

MAN1=$(sbatch \
  --parsable \
  --dependency=afterok:${BASECALL_JOBID} \
  "scripts/DNAscent/helper/make_manifest_demux-bams.sh")

echo "Manifest generation submitted. job id: $MAN1"


###############################################################################
# STEP 2 — submitting Alignment array (depends on Step 1)
###############################################################################

echo "Submitting alignment array..."

ALIGN_JOBID=$(sbatch \
  --array=1-24%20 \
  --parsable \
  --dependency=afterok:${MAN1} \
  "scripts/DNAscent/step2_align_array.sh")

echo "   Alignment array job id: $ALIGN_JOBID depends on $MAN1"


################ Prepare manifests for DNAscent ################
echo "Building manifest files for DNAscent..."

MAN2=$(sbatch \
  --parsable \
  --dependency=afterok:${ALIGN_JOBID} \
  "scripts/DNAscent/helper/make_manifest_aligned_reads.sh")

echo "Manifest generation submitted. job id: $MAN2"


###############################################################################
# STEP 3 — DNAscent index build (depends on Step 2)
###############################################################################

echo "Step 3: DNAscent index"
echo "Submitting Step 3:DNAscent index..."

DNAscent_index_JOBID=$(sbatch \
  --parsable \
  --dependency=afterok:${MAN2} \
  "scripts/DNAscent/step3_DNAscent_index.sh") \
  
echo "   DNAscent index id: $DNAscent_index_JOBID"


echo "DNAscent index generation submitted. job id: $DNAscent_index_JOBID"


##############################################################################
# starting STEP 4 — DNAscent array (depends on Step 3)
###############################################################################

echo "Submitting DNAscent array (after alignment)..."

DNASCENT_JOBID=$(sbatch \
  --array=1-24%20 \
  --parsable \
  --dependency=afterok:${DNAscent_index_JOBID} \
  --export=ALL \
  "scripts/DNAscent/step4_dnascent_array.sh")
echo "   DNAscent array job id: $DNASCENT_JOBID"

echo "Submitted!  DNAscent → $DNASCENT_JOBID  depends on $DNAscent_index_JOBID"


