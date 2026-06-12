#!/bin/bash
#SBATCH --mail-type=END
#SBATCH --mail-user=b-barckmann@chu-montpellier.fr
#SBATCH --partition=gpu
#SBATCH --gres=gpu:l40s:2
#SBATCH --cpus-per-task=6
#SBATCH --mem=16G
#SBATCH --job-name=index_
#SBATCH --output=slurm_log/%x_%A_%a.out
#SBATCH --error=slurm_log/%x_%A_%a.err




set -euo pipefail

module load apptainer/1.3.6

analysis_name="tc_analysis"
output_dir=DNAscent_$analysis_name
container_sif="containers/dnascent_2.0.sif"
dnascent_index_dir="${output_dir}/dnascent/index_${analysis_name}"
rf_dir="fastq_out/"



mkdir -p "${dnascent_index_dir}"

echo "Index directory: ${dnascent_index_dir}"
echo "raw fastq directory: ${rf_dir}"
echo "Container: ${container_sif}"

# Build DNAscent pod5-based index once (guard file)
if [[ ! -f "${dnascent_index_dir}/.built.ok" ]]; then
    echo "Building DNAscent index..."

    # Optional: check DNAscent availability
    apptainer exec "${container_sif}" /app/DNAscent/bin/DNAscent --version

    # Build index
    apptainer exec \
        -B "${rf_dir}:/rf_dir" \
        -B "${dnascent_index_dir}:/index" \
        "${container_sif}" \
        /app/DNAscent/bin/DNAscent index \
            --files /rf_dir \
            --output /index/read.index

    touch "${dnascent_index_dir}/.built.ok"
    echo "Index successfully built."

else
    echo "Index already exists. Skipping build."
fi


