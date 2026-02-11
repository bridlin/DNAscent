
#!/usr/bin/env bash
set -euo pipefail

# Inputs
demux_dir="$output_dir/demux/BSF_1_8/20260202_1009_0_FBE49425_f5007bd2/bam_pass/"


# For alignment array
ls "$demux_dir"/*.bam > "$output_dir/demux_list.txt"


