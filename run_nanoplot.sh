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


# for files in DNAscent_NanoPore-run3/demux/*.bam ; do
# 	NanoPlot \
# 		-o nanoplot_run3 \
# 		--ubam ${files} ; done


# input = "DNAscent_NanoPore-run3/demux/"

# 	NanoPlot \
# 		-o nanoplot_run3 \
# 		--ubam ${input} ; done

for i in 05 06 07 08 09 10 ; do
NanoPlot \
	-o nanoplot_run3/barcode${i} \
	--ubam DNAscent_NanoPore-run3/demux/2026_07_08_nano_BrdU_and_EdU/unknown/20260708_1126_0_FBE77896_b1ba7c8d/bam_pass/barcode${i}/FBE77896_pass_barcode${i}_b1ba7c8d_00000000_0.bam ; done
