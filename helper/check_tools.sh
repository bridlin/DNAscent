
#!/usr/bin/env bash
set -euo pipefail

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing tool: $1"; exit 1; }; }

need dorado
need samtools
need apptainer

[[ -d "$pod5_dir" ]] || { echo "pod5_dir not found: $pod5_dir"; exit 1; }
shopt -s nullglob
pod5_files=("$pod5_dir"/*.pod5)
(( ${#pod5_files[@]} > 0 )) || { echo "No .pod5 files in $pod5_dir"; exit 1; }

[[ -s "$reference" ]] || { echo "reference not found or empty: $reference"; exit 1; }

mkdir -p "$output_dir"/{basecall,demux,aligned,dnascent,logs}





