#!/usr/bin/env bash
#SBATCH --job-name=main_${USER}
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --partition=fast
#SBATCH -o awk_%j.out
#SBATCH -e awk_%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr


module load samtools/1.21

filepath_bdg="DNAscent_NanoPore-run3/dnascent/detect/detects/bdg_q20l1000_3/"
filepath_bam="DNAscent_NanoPore-run3/dnascent/detect/bams/"
echo ${filepath_bdg}
echo ${filepath_bam}

for i in  05 06 07 08 09 10 ; do \
for x in E B B+E ; do

samtools \
view -b -N \
${filepath_bdg}readID_${x}_count20_${i}.txt  \
${filepath_bam}FBE77896_pass_barcode${i}_b1ba7c8d_00000000_0.sorted.bam \
> ${filepath_bam}FBE77896_pass_barcode${i}_b1ba7c8d_00000000_0.sorted_filtered0.5_count20_${x}.bam && \
samtools index \
-b ${filepath_bam}FBE77896_pass_barcode${i}_b1ba7c8d_00000000_0.sorted_filtered0.5_count20_${x}.bam && \

samtools \
view -b -N \
${filepath_bdg}readID_${x}_count_${i}.txt  \
${filepath_bam}FBE77896_pass_barcode${i}_b1ba7c8d_00000000_0.sorted.bam \
> ${filepath_bam}FBE77896_pass_barcode${i}_b1ba7c8d_00000000_0.sorted_filtered0.5_count1_${x}.bam && \
samtools index \
-b ${filepath_bam}FBE77896_pass_barcode${i}_b1ba7c8d_00000000_0.sorted_filtered0.5_count1_${x}.bam  ; done ; done
