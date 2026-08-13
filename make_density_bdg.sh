#!/usr/bin/env bash
#SBATCH --job-name=main_${USER}
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --partition=fast
#SBATCH -o density_%j.out
#SBATCH -e density_%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load bedtools
           

           
for i in 05 06 07 08 09 10 ; do for x in EdU BrdU ; do  \
awk 'BEGIN{OFS="\t"} {$4=($4>0.5)?1:0; print}' DNAscent_NanoPore-run3/dnascent/detect/detects/bdg_q20l1000_3/FBE77896_pass_barcode${i}_b1ba7c8d_00000000_0.${x}.sorted.bdg \
> DNAscent_NanoPore-run3/dnascent/detect/detects/bdg_q20l1000_3/FBE77896_pass_barcode${i}_b1ba7c8d_00000000_0.${x}.sorted.binary.bdg    &&  \
           
bedtools map \
-a genome/TriTrypDB-55_TbruceiLister427_2018_Genome/NucComp_Tbruceii_2018_400-25bp_sorted.bed \
-b DNAscent_NanoPore-run3/dnascent/detect/detects/bdg_q20l1000_3/FBE77896_pass_barcode${i}_b1ba7c8d_00000000_0.${x}.sorted.binary.bdg \
-c 4 \
-o sum \
> density_0.5_${x}_${i}.bed && \
awk 'BEGIN{OFS="\t"} {pct=($9>0)?100*$13/$9:0; printf "%s\t%s\t%s\t%.2f\t%s\t%s\n",$1,$2,$3,pct,$9,$13}' density_0.5_${x}_${i}.bed > density_0.5_${x}_${i}.bed.bdg   ; done ; done
           
           