import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import glob
import os
import re

dfs = []

for f in glob.glob("density_*.bdg"):
    # adjust extraction of sample name to your filenames
    m = re.search(r'(BrdU[\d.]+|EdU[\d.]+).*?(barcode\d+)', f)
    sample = f"{m.group(1)}_{m.group(2)}"
    print(f)
    print(f"Processing sample: {sample}")   
    df = pd.read_csv(
        f,
        sep=r"\s+",
        header=None,
        names=["chr","start","end","density","count"]
    )

    df["sample"] = sample
    dfs.append(df)

all_df = pd.concat(dfs, ignore_index=True)

fig, ax = plt.subplots(figsize=(12,5))

sample_order = [
    "BrdU0.5_barcode11",
    "EdU0.5_barcode11",
    "BrdU0.5_barcode12",
    "EdU0.5_barcode12",
    "BrdU0.5_barcode13",
    "EdU0.5_barcode13",
    "BrdU0.5_barcode14",
    "EdU0.5_barcode14"
]

# Density
fig, ax = plt.subplots(figsize=(12,5))

sns.violinplot(
    data=all_df,
    x="sample",
    y="density",
    inner="quartile",
    order=sample_order,
    ax=ax
)

ax.set_ylim(-25, 100)
# ax.set_yscale('log')

for label in ax.get_xticklabels():
    label.set_rotation(45)
    label.set_fontsize(10)
    label.set_color("grey")

plt.tight_layout()
plt.savefig("density_violin_test_y100.png", dpi=300)




# Count
fig, ax = plt.subplots(figsize=(12,5))

sns.violinplot(
    data=all_df,
    x="sample",
    y="count",
    order=sample_order,
    inner="quartile",
    ax=ax
)

ax.set_ylim(-25, 100)
# ax.set_yscale('log')

for label in ax.get_xticklabels():
    label.set_rotation(45)
    label.set_fontsize(10)
    label.set_color("grey")


plt.tight_layout()
plt.savefig("count_violin_test_y100.png", dpi=300)