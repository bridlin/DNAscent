
#!/usr/bin/env python3
import sys

input_file = sys.argv[1]
prefix = input_file.rsplit(".", 1)[0]

out_brdU = open(prefix + ".BrdU.bedgraph", "w")
out_edU  = open(prefix + ".EdU.bedgraph",  "w")

chromosome = None

with open(input_file, "r") as f:
    for line in f:
        line = line.rstrip()

        # ignore empty & header lines
        if not line or line.startswith("#"):
            continue

        # read-block header
        if line.startswith(">"):
            splitLine = line[1:].split()
            readID     = splitLine[0]
            chromosome = splitLine[1]     # <-- used for bedGraph
            refStart   = int(splitLine[2])
            refEnd     = int(splitLine[3])
            strand     = splitLine[4]
            continue

        # entry lines
        splitLine = line.split()
        posOnRef  = int(splitLine[0])
        probBrdU  = float(splitLine[1])   # column 2  = BrdU
        probEdU   = float(splitLine[2])   # column 3  = EdU
        kmer      = splitLine[3]

        # bedGraph: chrom, start, end, value
        out_brdU.write(f"{chromosome}\t{posOnRef}\t{posOnRef+1}\t{probBrdU:.6f}\t{strand}\t{readID}\n")
        out_edU.write(f"{chromosome}\t{posOnRef}\t{posOnRef+1}\t{probEdU:.6f}\t{strand}\t{readID}\n")

out_brdU.close()
out_edU.close()

print("Created:")
print("  ", prefix + ".BrdU.bedgraph")
print("  ", prefix + ".EdU.bedgraph")

