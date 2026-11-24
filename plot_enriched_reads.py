import pandas as pd
import matplotlib.pyplot as plt

# Load tables
reads = pd.read_parquet(
    "../../detect-test/FBG84466_pass_barcode14_7adce89a_00000000_0_reads.parquet"
)

signal = pd.read_parquet(
    "../../detect-test/FBG84466_pass_barcode14_7adce89a_00000000_0_signal.parquet"
)

# Select top 20 EdU-enriched reads
top_edu = reads.nlargest(20, "EdU_%")

# Select top 20 BrdU-enriched reads
top_brdu = reads.nlargest(20, "BrdU_%")

# Create 4 x 5 panel
fig, axes = plt.subplots(
    nrows=4,
    ncols=5,
    figsize=(20, 12),
    sharey=True
)

axes = axes.flatten()

for i, (_, row) in enumerate(top_brdu.iterrows()):

    read_id = row["read_id"]
    chromosome = row["chromosome"]

    read_signal = signal[
        (signal["read_id"] == read_id)
        &
        (signal["chromosome"] == chromosome)
    ]

    ax = axes[i]

    ax.scatter(
        read_signal["T_index"],
        read_signal["EdU_P"],
        s=2,
        color="red",
        alpha=0.6,
        label="EdU"
    )

    ax.scatter(
        read_signal["T_index"],
        read_signal["BrdU_P"],
        s=2,
        color="blue",
        alpha=0.6,
        label="BrdU"
    )

    ax.set_title(
    f"{read_id}\nEdU={row['EdU_%']:.1f}% BrdU={row['BrdU_%']:.1f}%"
)

    ax.set_ylim(0, 1)

plt.tight_layout()

plt.savefig(
    "top20_edu_reads.png",
    dpi=300,
    bbox_inches="tight"
)

plt.show()