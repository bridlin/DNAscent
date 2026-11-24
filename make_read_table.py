import pysam
import pandas as pd
import os
import sys



#### FUNCTIONS ####

### select the sample names from the detect files in the results path
def get_sample_names(results_path):
    sample_names = []
    for root, dirs, files in os.walk(results_path):
        for file in files:
            if os.path.splitext(file)[1] == ".detect":
                 sample_names.append(os.path.splitext(file)[0])
    return sample_names

def parse_bam(bam_path, sample_name):
    reads = []
    bam_file = os.path.join(bam_path , sample_name + ".sorted.bam")
    
    # Check if the file exists
    if os.path.isfile(bam_file):
        print(f"Reading file: {bam_file}")
    
    bam = pysam.AlignmentFile(bam_file, "rb")

    for alignment in bam.fetch(until_eof=True):
        
        if alignment.is_secondary:
            continue

        if alignment.is_supplementary:
            continue
        
        left_softclip = 0
        right_softclip = 0
        if alignment.cigartuples:

            if alignment.cigartuples[0][0] == 4:
                left_softclip = alignment.cigartuples[0][1]

            if alignment.cigartuples[-1][0] == 4:
                right_softclip = alignment.cigartuples[-1][1] 


        reads.append({ 
            "read_id": alignment.query_name,
            "chromosome": bam.get_reference_name(alignment.reference_id),
            "reference_start": alignment.reference_start,
            "reference_end": alignment.reference_end,
            "reverse_strand": alignment.is_reverse,
            "read_length": alignment.query_length,
            "reference_span": alignment.reference_length,
            "query_aligned_length": alignment.query_alignment_length,
            "alignment_fraction": alignment.query_alignment_length / alignment.query_length if alignment.query_length > 0 else 0,
            "mapping_quality": alignment.mapping_quality,
            "left_softclip": left_softclip,
            "right_softclip": right_softclip,
            "total_softclip": left_softclip + right_softclip,
            "flag": alignment.flag,
            "secondary": alignment.is_secondary,
            "supplementary": alignment.is_supplementary,
            "primary": not alignment.is_secondary and not alignment.is_supplementary,
        })

    return reads




def parse_detect(file_path, sample_name, threshold, unique_bam_ids=None):
    results = []
    file=sample_name + ".detect"
    target_file = os.path.join(file_path, file)
    
    # Check if the file exists
    if os.path.isfile(target_file):
        print(f"Reading file: {target_file}")

    with open(target_file) as f:
        read_id = None
        chromosome = None
        detect_start = 0
        detect_end = 0
        edu_count = 0
        brdu_count = 0
        total_T = 0

        for line in f:
            line = line.strip()

            # New read
            if line.startswith(">"):
                if read_id is not None and total_T > 0:
                    results.append({
                        "read_id": read_id,
                        "chromosome": chromosome,
                        "detect_start": detect_start,
                        "detect_end": detect_end,
                        "total_T": total_T,
                        "EdU_sites": edu_count,
                        "BrdU_sites": brdu_count,
                        "EdU_%": 100 * edu_count / total_T,
                        "BrdU_%": 100 * brdu_count / total_T,
                        "BrdU_prop_max": brdu_max,
                        "EdU_prop_max": edu_max
                        
                    })

                read_id = line.split()[0][1:]
                chromosome = line.split()[1] if len(line.split()) > 1 else None
                detect_start = int(line.split()[2]) if len(line.split()) > 2 else 0
                detect_end = int(line.split()[3]) if len(line.split()) > 3 else 0
                edu_count = 0
                brdu_count = 0
                total_T = 0
                brdu_max = 0
                edu_max = 0
                continue

            # Skip headers
            if line.startswith("#") or not line:
                continue

            parts = line.split()
            if len(parts) < 3:
                continue
            
            # Every line = one T position
            total_T += 1
            
            edu_prob = float(parts[1])    # column 2  = EdU 
            brdu_prob = float(parts[2])   # column 3  = BrdU

            if edu_prob >= threshold:
                edu_count += 1
            if brdu_prob >= threshold:
                brdu_count += 1

            if brdu_prob > brdu_max:
                brdu_max = brdu_prob
            if edu_prob > edu_max:
                edu_max = edu_prob    

        # Last read
        if read_id is not None and total_T > 0:
            results.append({
                "read_id": read_id,
                "chromosome": chromosome,
                "detect_start": detect_start,
                "detect_end": detect_end,
                "total_T": total_T,
                "EdU_sites": edu_count,
                "BrdU_sites": brdu_count,
                "EdU_%": 100 * edu_count / total_T,
                "BrdU_%": 100 * brdu_count / total_T,
                "BrdU_prop_max": brdu_max,
                "EdU_prop_max": edu_max 
            })
    
    df_detect = pd.DataFrame(results)
    
    # Filter the results to only include reads that are present in the BAM file
    if unique_bam_ids is not None:
        df_detect = df_detect[
            df_detect["read_id"].isin(unique_bam_ids)
            ]

    return df_detect


def merge_detect_bam(detect_df, bam_df, sample_name):
    merged_df = pd.merge(detect_df, bam_df, how='inner', left_on=['read_id', 'chromosome', 'detect_start', 'detect_end'], right_on=['read_id', 'chromosome', 'reference_start', 'reference_end'], left_index=False, right_index=False, sort=True, suffixes=('_x', '_y'), indicator=False)
    merged_df["sample"] = sample_name
    return merged_df

def compare_readIDs(df_detects, df_bam):
    bam_ids = set(df_bam["read_id"])
    detect_ids = set(df_detects["read_id"])

    only_bam = bam_ids - detect_ids
    only_detect = detect_ids - bam_ids
    if len(only_bam) > 0:
        print("WARNING: Some read IDs are in the BAM file but not in the detect file.")
    if len(only_detect) > 0:
        print("WARNING: Some read IDs are in the detect file but not in the BAM file.")
    else:
        print("All read IDs match between the BAM and detect files.")


def check_duplicate_ids(df):
    duplicate_ids = df[df.duplicated(subset='read_id', keep=False)]
    if not duplicate_ids.empty:
        sum=len(duplicate_ids)
        print("WARNING:" + str(sum) + " duplicate read IDs found:")
        print(duplicate_ids["read_id"])
    else:
        print("No duplicate read IDs found.")



def deduplicate_df(df):
    duplicate_alignments = df[df.duplicated( subset=[
            "read_id",
            "chromosome",
            "detect_start",
            "detect_end"
        ], 
        keep=False)]
    if not duplicate_alignments.empty:
        
        print(
            f"WARNING: {len(duplicate_alignments)} duplicate read alignments found:"
        )
        print(duplicate_alignments[
            [
                "read_id",
                "chromosome",
                "detect_start",
                "detect_end"
            ]
        ])
        
        print("Removing duplicate alignments...")
        before = len(df)
        df = df.drop_duplicates(
            subset=[
                "read_id",
                "chromosome",
                "detect_start",
                "detect_end"
            ]
        )
        print(f"Removed {before - len(df)} duplicate rows")
    else:
        print("No duplicate read alignments found.")

    return df





def get_unique_ids(df_bam):
    return set(df_bam["read_id"])

#### Main ####
def main():
    if len(sys.argv) == 1: 
        print('file path to input files (detect and bam) is missing as command line argument!!!')
    else:
        detect_path = sys.argv[1]
        print(f"detect path: {detect_path}")
  
    
   # getting the detect file and bam file as df and merge them to read_df on the readID column
    for sample in get_sample_names(detect_path):
        print(f"sample name: {sample}")
        
        # getting the bam file as df
        df_bam = pd.DataFrame(parse_bam(detect_path, sample))
        check_duplicate_ids(df_bam)
        print(df_bam) 
        
        # getting the detect file as df
        unique_bam_ids = get_unique_ids(df_bam)
        print(f"unique bam ids: {len(unique_bam_ids)}")
        df_detects = parse_detect(detect_path, sample, threshold=0.5,unique_bam_ids = unique_bam_ids)
        check_duplicate_ids(df_detects)
        print(df_detects) 
        
        
        # merging the two dfs and checking for duplicate and removing duplicated alignments
        df_reads=[]
        if not df_detects.empty and not df_bam.empty:
            print(compare_readIDs(df_detects, df_bam))
            df_reads = merge_detect_bam(df_detects, df_bam, sample)
            check_duplicate_ids(df_reads)
            df_reads = deduplicate_df(df_reads)
            print(df_reads)
            
            print(
                f"detect={len(df_detects)} "
                f"bam={len(df_bam)} "
                f"merged={len(df_reads)}"
            )



            outfile = f"{detect_path}{sample}_reads.parquet"
            
            df_reads.to_parquet(
                outfile,
                compression="snappy",
                index=False
            )
            
            print(
                f"Saved {len(df_reads):,} rows to {outfile}"
            )
        else: print(str(sample)  + 'detects or bam file is empty.')
        


if __name__ == "__main__":
    main()