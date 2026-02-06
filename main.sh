#!/usr/bin/env bash
#SBATCH --job-name=main_${USER}
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --partition=long
#SBATCH -o main_%j.out
#SBATCH -e main_%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=b-barckmann@chu-montpellier.fr

set -euo pipefail

# Load modules here so sub-scripts inherit env via login profile if needed
module load dorado/1.2.0
module load samtools/1.21
module load apptainer/1.3.6

# Source config
source scripts/DNAscent/config.txt

# Export so child sbatch jobs can reuse variables
export analysis_name pod5_dir reference kit_name model device \
       container_sif dnascent_index_dir threads_align threads_detect \
       partition mem_align mem_detect output_root

# Basic checks + directories
bash "scripts/DNAscent/helper/check_tools.sh"

echo "Starting pipeline for $analysis_name"
echo "Output root: $output_root"

# FAIR: ensure required container exists (pull once if missing)
if [[ ! -f "$container_sif" ]]; then
  mkdir -p "$(dirname "$container_sif")"
  echo "Pulling container → $container_sif"
  apptainer pull "$container_sif" docker://gerlichlab/dnascent-docker:version-2.0
fi

# Step 1: Basecalling + inline classification + demux (runs inside this job)
echo "Step 1: Basecall + demux"
bash "scripts/DNAscent/step1_basecall_demux.sh"

# Prepare manifests for arrays
bash "scripts/DNAscent/helper/make_manifests.sh"

# Step 2: submit ALN array
echo "Submitting alignment array..."
ALIGN_JOBID=$(sbatch --parsable "scripts/DNAscent/step2_align_array.sh")
echo "   Alignment array job id: $ALIGN_JOBID"

# Step 3: submit DNAscent array, dependent on alignment success
echo "Submitting DNAscent array (after alignment)..."
DNASCENT_JOBID=$(sbatch --parsable --dependency=afterok:${ALIGN_JOBID} \
  "scripts/DNAscent/step3_dnascent_array.sh")
echo "   DNAscent array job id: $DNASCENT_JOBID"

echo "Submitted! Alignment → $ALIGN_JOBID ; DNAscent → $DNASCENT_JOBID"
