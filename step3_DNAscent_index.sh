#!/bin/bash
#SBATCH -o basecall.%N.%j.out
#SBATCH -e basecall.%N.%j.err
#SBATCH --mail-type END
#SBATCH --mail-user b-barckmann@chu-montpellier.fr
#SBATCH --partition=gpu
#SBATCH --gres=gpu:l40s:2
#SBATCH --cpus-per-task=6
#SBATCH --mem=16G

module load apptainer/1.3.6

set -euo pipefail

dnascent_index_dir=$output_dir/dnascent/index_$analysis_name

# Build DNAscent pod5-based index once (safe to call every task; use a guard file)
mkdir -p "$dnascent_index_dir"
if [[ ! -f "$dnascent_index_dir/.built.ok" ]]; then
    apptainer exec \
        -B "$pod5_dir":/pod5 \
        -B "$dnascent_index_dir":/index \
        "$container_sif" \
    
    
    apptainer exec "$container_sif" DNAscent --version
    apptainer exec "$container_sif" DNAscent index --help | head -n 50

    apptainer exec \
        -B "$pod5_dir":/pod5 \
        -B "$dnascent_index_dir":/index \
        "$container_sif" \
        DNAscent index  \
            --files /pod5  \
            --output pod.index
    touch "$dnascent_index_dir/.built.ok"
      
fi