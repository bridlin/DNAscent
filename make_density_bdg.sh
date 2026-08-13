#!/usr/bin/env bash
#SBATCH --job-name=main_${USER}
#SBATCH --cpus-per-task=4
#SBATCH --array=0-9
#SBATCH --mem=32G
#SBATCH --partition=fast
#SBATCH -o density_%A_%a.out
#SBATCH -e density_%A_%a.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load bedtools


# ---- Config ----
SAMPLES_FILE="DNAscent_NanoPore-run3/bam_list.txt"            # one sample ID per line
DETECT_DIR="DNAscent_NanoPore-run3/dnascent/detect/detects"               # where DNAscent detect outputs are
BDG_DIR="${DETECT_DIR}/bdg_q20l1000_3"
PROB="0.8"  # Probability threeshold for BrdU/EdU labeling detection (0.5, 0.8, 0.9, etc.)

genome_fasta="genome/TriTrypDB-55_TbruceiLister427_2018_Genome/TriTrypDB-55_TbruceiLister427_2018_Genome.fasta"  # precomputed genome fasta file for your reference
genome_chrom_sizes="genome/TriTrypDB-55_TbruceiLister427_2018_Genome/TriTrypDB-55_TbruceiLister427_2018.chrom.sizes"  # precomputed chrom sizes for your reference
NUC_GENOME_BED="genome/TriTrypDB-55_TbruceiLister427_2018_Genome/NucComp_Tbruceii_2018_400-25bp_sorted.bed"  # precomputed genome bed file with sliding window for your reference
GENOME_BED="genome/TriTrypDB-55_TbruceiLister427_2018_Genome/Tbruceii_2018_400-25bp_sorted.bed"  # precomputed genome bed file with sliding window for your reference

# ---- Resolve current sample ----
# 1) Get the BAM filename for this array task
BAM_PATH=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" $SAMPLES_FILE)

# Strip the directory
SAMPLE=$(basename "$BAM_PATH" .trimmed.aligned.sorted.bam)

SORTED_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.sorted.bdg"
SORTED_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.sorted.bdg"
SORTED_BINARY_BDG_EDU="${BDG_DIR}/${SAMPLE}.EdU.sorted.binary.${PROB}.bdg"
SORTED_BINARY_BDG_BRDU="${BDG_DIR}/${SAMPLE}.BrdU.sorted.binary.${PROB}.bdg"
density_EdU_BED="${BDG_DIR}/density_EdU${PROB}_${SAMPLE}.bed"
density_BrdU_BED="${BDG_DIR}/density_BrdU${PROB}_${SAMPLE}.bed"
density_EdU_BDG="${BDG_DIR}/density_EdU${PROB}_${SAMPLE}.bdg"
density_BrdU_BDG="${BDG_DIR}/density_BrdU${PROB}_${SAMPLE}.bdg"



#---- check for genome bed file ----
if [ ! -f "$NUC_GENOME_BED" ]; then
    echo "Error: Genome bed file not found, generating genome bed file..."
    bedtools makewindows \
	    -g  $genome_chrom_sizes \
	    -w 400 \
	    -s 25 \
	    > $GENOME_BED

    bedtools nuc \
	    -fi $genome_fasta  \
	    -bed $GENOME_BED \
	    >  $NUC_GENOME_BED
fi

# ---- Step 1: convert bedGraph to binary bedGraph (1 if > threshold, 0 otherwise) and compute density per window
awk -v var1=$PROB  'BEGIN{OFS="\t"} {$4=($4>var1)?1:0; print}' ${SORTED_BDG_EDU} \
> ${SORTED_BINARY_BDG_EDU}    

awk -v var1=$PROB  'BEGIN{OFS="\t"} {$4=($4>var1)?1:0; print}' ${SORTED_BDG_BRDU} \
> ${SORTED_BINARY_BDG_BRDU}  




# ---- Step 2: compute density per window
bedtools map \
-a $NUC_GENOME_BED \
-b ${SORTED_BINARY_BDG_EDU} \
-c 4 \
-o sum \
> ${BDG_DIR}/density_EdU${PROB}_${SAMPLE}.bed 
awk  'BEGIN{OFS="\t"} {pct=($9>0)?100*$13/$9:0; printf "%s\t%s\t%s\t%.2f\t%s\t%s\n",$1,$2,$3,pct,$9,$13}' ${density_EdU_BED} > ${density_EdU_BDG}
rm ${density_EdU_BED}

 bedtools map \
-a $NUC_GENOME_BED \
-b ${SORTED_BINARY_BDG_BRDU} \
-c 4 \
-o sum \
> ${BDG_DIR}/density_BrdU${PROB}_${SAMPLE}.bed 
awk  'BEGIN{OFS="\t"} {pct=($9>0)?100*$13/$9:0; printf "%s\t%s\t%s\t%.2f\t%s\t%s\n",$1,$2,$3,pct,$9,$13}' ${density_BrdU_BED} > ${density_BrdU_BDG}
rm ${density_BrdU_BED}             