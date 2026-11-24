import pandas as pd
import matplotlib.pyplot as plt



reads = pd.read_parquet("../../detect-test/FBG84466_pass_barcode14_7adce89a_00000000_0_reads.parquet")

edu_reads = reads[
    reads["EdU_%"] > 20
]

print(edu_reads)
print(edu_reads)

print("number of reads with EdU_% > 20: ", len(edu_reads))
#print(len(edu_reads))

print(edu_reads.head())

print("20 most EdU enriched reads:")

top_edu = reads.nlargest(20, "EdU_%")

print(top_edu[["read_id", "EdU_%", "BrdU_%"]])


brdu_reads = reads[
    reads["BrdU_%"] > 20
]

print(brdu_reads)
print(brdu_reads)

print("number of reads with BrdU_% > 20: ", len(brdu_reads))
#print(len(brdu_reads))

print(brdu_reads.head())

print("20 most BrdU enriched reads:")

top_brdu = reads.nlargest(20, "BrdU_%")

print(top_brdu[["read_id", "EdU_%", "BrdU_%"]])




# read_id = top_edu.iloc[0]["read_id"]
# print(read_id)


print("DESCRIBTION OF EdU_% COLUMNS")
print(reads["EdU_%"].describe())
print("DESCRIBTION OF BrdU_% COLUMNS")
print(reads["BrdU_%"].describe())



signal = pd.read_parquet(
    "../../detect-test/FBG84466_pass_barcode14_7adce89a_00000000_0_signal.parquet"
)

read_id="b8c7a647-9b47-449e-a7b9-f0956aa4b73a"

read_signal = signal[
    signal["read_id"] == read_id
]


print("read_signal is ")
print(read_signal)

print(read_signal.groupby(
    ["read_id", "chromosome"]
).size())

print(read_signal["chromosome"].value_counts())



read_signal = read_signal[
    read_signal["chromosome"] == "Chr8_3A_Tb427v10"
]




plt.figure(figsize=(12,4))

plt.scatter(
    read_signal["T_index"],
    read_signal["EdU_P"],
    s=3,
    color="red",
    label="EdU"
)

plt.scatter(
    read_signal["T_index"],
    read_signal["BrdU_P"],
    s=3,
    color="blue",
    label="BrdU"
)

plt.legend()

plt.xlabel("T index")
plt.ylabel("Probability")

plt.title(read_id)

plt.show()
