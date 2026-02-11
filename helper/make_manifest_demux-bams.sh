
#!/usr/bin/env bash
set -euo pipefail

# Inputs
demux_dir="$output_dir/demux/"


# For alignment array
ls "$demux_dir"/*.bam > "$output_dir/demux_list.txt"


