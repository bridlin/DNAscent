#!/usr/bin/env bash
set -euo pipefail

# Inputs

aligned_dir="$output_dir/aligned"
echo "aligned_dir = $aligned_dir"


# For DNAscent array (aligned outputs)
find "$aligned_dir" -type f -name "*.bam" | sort > "$output_dir/bam_list.txt"


if [ ! -s "$output_dir/bam_list.txt" ]; then
    echo "ERROR: No BAM files found in $aligned_dir"
    exit 1
fi
