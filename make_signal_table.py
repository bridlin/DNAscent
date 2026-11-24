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
        chromosome = None
        rev_strand = False
        T_index = 0
        
        for line in f:
            line = line.strip()

            # Skip headers
            if line.startswith("#") or not line:
                continue
        
            # New read, and read variables from the read header line
            if line.startswith(">"):
                parts = line.split()
                read_id = parts[0][1:]
                chromosome = parts[1]
                rev_strand = parts[4] == "rev"

                T_index = 0
                continue
            
            # Every line = one T position, and read variables from the T lines
            parts = line.split()
            if len(parts) != 4:
                print(f"WARNING: malformed line: {line}")
                continue

            T_index += 1
            T_reference = int(parts[0])     # column 1  = T position
            edu_P = float(parts[1])         # column 2  = EdU 
            brdu_P = float(parts[2])        # column 3  = BrdU

            # Append the results to the list
            results.append({
                            "sample": sample_name,
                            "read_id": read_id,
                            "chromosome": chromosome,
                            "T_reference": T_reference,                            
                            "rev_strand": rev_strand,
                            "T_index": T_index,
                            "EdU_P": edu_P,
                            "BrdU_P": brdu_P
                        })

    df_signal = pd.DataFrame(results)

    # Convert columns to appropriate data types to reduce size of the later paquet file
    df_signal["read_id"] = df_signal["read_id"].astype("category")
    df_signal["sample"] = df_signal["sample"].astype("category")
    df_signal["chromosome"] = df_signal["chromosome"].astype("category")

    df_signal["T_reference"] = df_signal["T_reference"].astype("int32")
    df_signal["T_index"] = df_signal["T_index"].astype("int32")

    df_signal["EdU_P"] = df_signal["EdU_P"].astype("float32")
    df_signal["BrdU_P"] = df_signal["BrdU_P"].astype("float32")
    
    print(df_signal.info(memory_usage="deep"))    
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

        # transforming the detect file to signal per row table format with columns: sample, read_id, chromosome, T_reference, rev_strand, T_index, EdU_P, BrdU_P
        df_signal = pd.DataFrame(parse_detect(detect_path, sample))
        print(df_signal) 
        outfile = f"{detect_path}/{sample}_signal.parquet"

        df_signal.to_parquet(
            outfile,
            compression="snappy",
            index=False
        )

        print(
            f"Saved {len(df_signal):,} rows to {outfile}"
        )

            
        










if __name__ == "__main__":
    main()
        















