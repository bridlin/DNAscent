#!/bin/bash
#
#SBATCH -o slurm.%N.%j.out
#SBATCH -e slurm.%N.%j.err
#SBATCH --mail-type END
#SBATCH --mail-user b-barckmann@chu-montpellier.fr
#
#
#SBATCH --partition long
#SBATCH --cpus-per-task 4
#SBATCH --mem  128GB



# module load dorado/1.2.0
# module load samtools/1.21
# module load apptainer/1.3.6
# # module load singularity


# source scripts/DNAscent/config.txt



echo "output_dir = $output_dir"
echo "analysis name = $analysis_name"
echo "pod5 input = $pod5_dir"





# =======================
# ==== BASECALL + DEMUX =
# =======================


# Classify during basecalling, then split without re-classifying
# Ref: Inline classification and --no-classify during demux. [2](https://software-docs.nanoporetech.com/dorado/latest/barcoding/barcoding/)
echo "Basecalling with inline barcoding..."
basecall_bam="$output_dir/basecall/${analysis_name}.bam"
dorado basecaller "$model" "$pod5_dir" \
    -x "$device" \
    --kit-name "$kit_name" \
    > "$basecall_bam" 2> "$output_dir/logs/basecaller.log"

echo " Demultiplexing (split per barcode, no re-classification)..."
dorado demux \
    --output-dir "$output_dir/demux" \
    --no-classify \
    "$basecall_bam" \
    --emit-summary \    
    2> "$output_dir/logs/demux.log"










