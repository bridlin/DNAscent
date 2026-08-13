#!/usr/bin/env bash
#SBATCH --job-name=main_${USER}
#SBATCH --cpus-per-task=4
#SBATCH --array=0-9
#SBATCH --mem=32G
#SBATCH --partition=fast
#SBATCH -o density_%j.out
#SBATCH -e density_%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module purge
module load bedtools


# ---- Config ----
SAMPLES_FILE="DNAscent_NanoPore-run3/bam_list_2.txt"            # one sample ID per line
DETECT_DIR="DNAscent_NanoPore-run3/dnascent/detect/detects"               # where DNAscent detect outputs are
BDG_DIR="${DETECT_DIR}/bdg_q20l1000_3"
genome_fasta="genome/TriTrypDB-55_TbruceiLister427_2018_Genome/TriTrypDB-55_TbruceiLister427_2018_Genome.fasta"  # precomputed genome fasta file for your reference
genome_chrom_sizes="genome/TriTrypDB-55_TbruceiLister427_2018_Genome/TriTrypDB-55_TbruceiLister427_2018.chrom.sizes"  # precomputed chrom sizes for your reference
NUC_GENOME_BED="genome/TriTrypDB-55_TbruceiLister427_2018_Genome/NucComp_Tbruceii_2018_400-25bp_sorted.bed"  # precomputed genome bed file with sliding window for your reference
GENOME_BED="genome/TriTrypDB-55_TbruceiLister427_2018_Genome/Tbruceii_2018_400-25bp_sorted.bed"  # precomputed genome bed file with sliding window for your reference
PROB="0.8"  # Probability threeshold for BrdU/EdU labeling detection (0.5, 0.8, 0.9, etc.)

# ---- Resolve current sample ----
# 1) Get the BAM filename for this array task
BAM_PATH=$(sed -n "$((SLURM_ARRAY_TASK_ID+1))p" $SAMPLES_FILE)

# Strip the directory

SAMPLE=$(basename "$BAM_PATH" .trimmed.aligned.sorted.bam)

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
awk -v var=$PROB 'BEGIN{OFS="\t"} {$4=($4>var)?1:0; print}' ${BDG_DIR}/${SAMPLE}.sorted.bdg \
> ${BDG_DIR}/${SAMPLE}.sorted.binary.bdg    
           
# ---- Step 2: compute density per window
bedtools map \
-a $GENOME_BED \
-b ${BDG_DIR}/${SAMPLE}.sorted.binary.bdg \
-c 4 \
-o sum \
> ${BDG_DIR}/density_${PROB}_${SAMPLE}.bed 
awk 'BEGIN{OFS="\t"} {pct=($9>0)?100*$13/$9:0; printf "%s\t%s\t%s\t%.2f\t%s\t%s\n",$1,$2,$3,pct,$9,$13}' ${BDG_DIR}/density_${PROB}_${SAMPLE}.bed > ${BDG_DIR}/density_${PROB}_${SAMPLE}.bed.bdg   
           