import sys

import pandas as pd



file_path = sys.argv[1]
threshold = float(sys.argv[2])

def parse_detect(file_path, threshold):
    results = []

    with open(file_path) as f:
        read_id = None
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
                        "total_T": total_T,
                        "EdU_sites": edu_count,
                        "BrdU_sites": brdu_count,
                        "EdU_%": 100 * edu_count / total_T,
                        "BrdU_%": 100 * brdu_count / total_T
                    })

                read_id = line.split()[0][1:]
                edu_count = 0
                brdu_count = 0
                total_T = 0
                continue

            # Skip headers
            if line.startswith("#") or not line:
                continue

            parts = line.split()
            if len(parts) < 3:
                continue

            edu_prob = float(parts[1])
            brdu_prob = float(parts[2])

            # Every line = one T position
            total_T += 1

            if edu_prob >= threshold:
                edu_count += 1
            if brdu_prob >= threshold:
                brdu_count += 1

        # Last read
        if read_id is not None and total_T > 0:
            results.append({
                "read_id": read_id,
                "total_T": total_T,
                "EdU_sites": edu_count,
                "BrdU_sites": brdu_count,
                "EdU_%": 100 * edu_count / total_T,
                "BrdU_%": 100 * brdu_count / total_T
            })

    return pd.DataFrame(results)


# Run
df = parse_detect(file_path, threshold)
df.to_csv("labelling_per_read.csv", index=False)

print(df.head())