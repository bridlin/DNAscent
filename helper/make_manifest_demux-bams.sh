#!/usr/bin/env bash
set -euo pipefail

# Inputs
demux_dir="$output_dir/demux/"
#echo "demux_dir = $demux_dir"

# For alignment array
ls "$demux_dir"/*.bam > "$output_dir/demux_list.txt"


