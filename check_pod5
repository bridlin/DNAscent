#!/usr/bin/env python


import pod5

pod5_dir = "pod5_run1/"

with open("all_pod5_read_ids.txt", "w") as out:
    with pod5.DatasetReader(pod5_dir, recursive=True) as dataset:
        for r in dataset:
            out.write(str(r.read_id) + "\n")
