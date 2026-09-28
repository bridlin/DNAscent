#!/usr/bin/env bash
set -euo pipefail

# Inputs
demux_dir="$output_dir/demux/"
echo "demux_dir = $demux_dir"

# For alignment array

find "$(realpath "$demux_dir")" -type f -name "*.bam" | sort > "$output_dir/demux_list.txt"

if [ ! -s "$output_dir/demux_list.txt" ]; then
    echo "ERROR: No BAM files found in $demux_dir"
    exit 1
fi
