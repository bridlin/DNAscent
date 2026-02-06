
#!/usr/bin/env bash
set -euo pipefail

# Inputs
demux_dir="$output_dir/demux"
aligned_dir="$output_dir/aligned"

# For alignment array
ls "$demux_dir"/*.bam > "$output_dir/demux_list.txt"

# For DNAscent array (aligned outputs)
ls "$aligned_dir"/*.sorted.bam > "$output_dir/bam_list.txt"
