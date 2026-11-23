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


def parse_detect(file_path, sample_name):
    results = []
    file=sample_name + ".detect"
    target_file = os.path.join(file_path, file)
    
    # Check if the file exists
    if os.path.isfile(target_file):
        print(f"Reading file: {target_file}")

    with open(target_file) as f:
        read_id = None
        rev_strand = False
        T_index = 0
        T_position = 0
        edu_P = 0
        brdu_P = 0

        
        
        for line in f:
            line = line.strip()

            # Skip headers
            if line.startswith("#") or not line:
                continue
        
            parts = line.split()
            if len(parts) < 3:
                continue


            # New read
            if line.startswith(">"):
                read_id = line.split()[0][1:]
                chromosome = line.split()[1]
                rev_strand = line.split()[4] == "rev"
                edu_P = 0
                brdu_P = 0
                T_index = 0
                T_reference = 0
                continue
            
            # Every line = one T position
            T_index += 1
            edu_P = float(parts[1])    # column 2  = EdU 
            brdu_P = float(parts[2])   # column 3  = BrdU
            T_reference = int(parts[0])  # column 1  = T position
            results.append({
                            "read_id": read_id,
                            "chromosome": chromosome,
                            "T_reference": T_reference,                            
                            "rev_strand": rev_strand,
                            "T_index": T_index,
                            "EdU_P": edu_P,
                            "BrdU_P": brdu_P
                        })

        df_signal = pd.DataFrame(results)
        
    return df_signal






#### Main ####

def main():
    if len(sys.argv) == 1: 
        print('file path to input detect file is missing as command line argument!!!')
    else:
        detect_path = sys.argv[1]
        print(f"detect path: {detect_path}")


    for sample in get_sample_names(detect_path):
        print(f"sample name: {sample}")

        # getting the bam file as df
        df_signal = pd.DataFrame(parse_detect(detect_path, sample))

        outfile = f"{detect_path}/{sample}_signal.parquet"

        df_signal.to_parquet(
            outfile,
            compression="snappy",
            index=False
        )

        print(
            f"Saved {len(df_signal):,} rows to {outfile}"
        )

            
        print(df_signal) 










if __name__ == "__main__":
    main()
        















