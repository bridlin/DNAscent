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



dnascent_index_dir="${output_dir}/dnascent/index_${analysis_name}"

mkdir -p "${dnascent_index_dir}"

echo "Index directory: ${dnascent_index_dir}"
echo "POD5 directory: ${pod5_dir}"
echo "Container: ${container_sif}"

# Build DNAscent pod5-based index once (guard file)
if [[ ! -f "${dnascent_index_dir}/.built.ok" ]]; then
    echo "Building DNAscent index..."

    # Optional: check DNAscent availability
    apptainer exec "${container_sif}" /app/DNAscent/bin/DNAscent --version

    # Build index
    apptainer exec \
        -B "${pod5_dir}:/pod5" \
        -B "${dnascent_index_dir}:/index" \
        "${container_sif}" \
        /app/DNAscent/bin/DNAscent index \
            --files /pod5 \
            --output /index/pod.index

    touch "${dnascent_index_dir}/.built.ok"
    echo "Index successfully built."

else
    echo "Index already exists. Skipping build."
fi