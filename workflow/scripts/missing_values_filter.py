from pyopenms import *
import sys
import os
import pandas as pd
import glob


def filter(consensus_file, consensus_file_filtered, min_frac=0.0):
    # min_frac: minimum fraction of samples to be considered a valid consensus feature
    # e.g. 0.5 -> values from at least 50% of samples required

    consensus_map = ConsensusMap()
    ConsensusXMLFile().load(consensus_file, consensus_map)

    print(
        f"Number of consensus features before filtering with threshold of {min_frac}: {consensus_map.size()}"
    )

    cm_filtered = ConsensusMap(consensus_map)
    cm_filtered.clear(False)

    n_samples = len(consensus_map.getColumnHeaders())

    for cf in consensus_map:
        if cf.size() / n_samples >= min_frac:
            cm_filtered.push_back(cf)

    print(f"Number of consensus features after filtering: {cm_filtered.size()}")

    ConsensusXMLFile().store(consensus_file_filtered, cm_filtered)
    return consensus_file_filtered


if __name__ == "__main__":
    filter(sys.argv[1], sys.argv[2])
