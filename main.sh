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
       partition mem_align mem_detect output_dir


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


###############################################################################
# STEP 2 — submitting Alignment array (depends on Step 1)
###############################################################################

echo "Submitting alignment array..."
N_ALIGN=$(wc -l < demux_list.txt)
ALIGN_JOBID=$(sbatch \
  --array=1-"$N_ALIGN"%20 \
  --parsable \
  --dependency=afterok:$BASECALL_JOBID \
  "scripts/DNAscent/step2_align_array.sh")

echo "   Alignment array job id: $ALIGN_JOBID"


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
