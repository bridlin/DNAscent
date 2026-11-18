detect = "FBG84466_pass_barcode12_7adce89a_00000000_0.detect"

header = []
handles = {}

with open(detect) as fh:

    current = None

    for line in fh:

        if line.startswith("#"):
            header.append(line)
            continue

        if line.startswith(">"):

            chrom = line.split()[1]

            # Skip non-chromosomal contigs
            if not chrom.startswith("Chr"):
                current = None
                continue

            if chrom not in handles:
                out = open(f"{chrom}.detect", "w")
                out.writelines(header)
                handles[chrom] = out

            current = handles[chrom]

        if current is not None:
            current.write(line)

for h in handles.values():
    h.close()