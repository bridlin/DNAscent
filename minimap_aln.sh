#!/usr/bin/env bash
#SBATCH --job-name=main_${USER}
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --partition=fast
#SBATCH -o main_%j.out
#SBATCH -e main_%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=bridlin.barckmann@umontpellier.fr

module load minimap2/2.28
module load samtools/1.21

set -euo pipefail

sample_dir="fastq_out/"

genome="genome/TriTrypDB-68_TcruziCLBrenerEsmeraldo-like/TriTrypDB-68_TcruziCLBrenerEsmeraldo-like_Genome.fasta"

 
for sample in ${sample_dir}/*.fastq.gz ; do
    sname=$(basename "${sample}" .fastq.gz); \
    echo "Processing ${sname}..." 
    minimap2 \
        -t $SLURM_CPUS_PER_TASK \
        -ax map-ont \
        ${genome} \
        ${sample} \
        | samtools sort -@ ${SLURM_CPUS_PER_TASK} -o ${sname}_sorted.bam - && \
    samtools \
        index \
        ${sname}_sorted.bam 
;done




