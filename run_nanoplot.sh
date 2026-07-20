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


for files in DNAscent_NanoPore-run3/demux/*.bam ; do
	NanoPlot \
		-o nanoplot_run3 \
		--ubam ${files} ; done

