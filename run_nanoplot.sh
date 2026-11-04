#!/usr/bin/env bash
#SBATCH --job-name=nanoplot
#SBATCH --cpus-per-task=4
#SBATCH --mem=34G
#SBATCH --partition=fast
#SBATCH -o nanoplot_%A_%a.out
#SBATCH -e nanoplot_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load nanoplot/1.46.2

source scripts/DNAscent/config.txt



demux_dir="$output_dir/demux/28_october_2026_Nano_4/unknown/20261029_1553_0_FBG84466_7adce89a/bam_pass/"

echo "output_dir = $output_dir"
echo "demux_dir = $demux_dir"		


for i in 11 12 13 14  ; do
bam_file="$demux_dir/barcode${i}/FBG84466_pass_barcode${i}_7adce89a_00000000_0.bam"
echo "Running NanoPlot for barcode ${bam_file}..."
NanoPlot \
	-o nanoplot_run3/barcode${i} \
	--ubam "$bam_file" ; done
