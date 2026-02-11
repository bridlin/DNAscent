#!/usr/bin/env bash
set -euo pipefail

# Inputs

aligned_dir="$output_dir/aligned"



# For DNAscent array (aligned outputs)
ls "$aligned_dir"/*.sorted.bam > "$output_dir/bam_list.txt"
