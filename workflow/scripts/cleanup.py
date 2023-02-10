import pandas as pd
import numpy as np
from pyopenms import *
import sys

def cleanup(input_cmap, output_tsv):
    consensus_map = ConsensusMap()
    ConsensusXMLFile().load(input_cmap, consensus_map)
    df = consensus_map.get_df()
    for cf in consensus_map:
        if cf.metaValueExists("best ion"):
            df["adduct"] = [cf.getMetaValue("best ion") for cf in consensus_map]
            break
    df["feature_ids"] = [[handle.getUniqueId() for handle in cf.getFeatureList()] for cf in consensus_map]
    df= df.reset_index()
    df= df.drop(columns= ["sequence"])
    df.to_csv(output_tsv, sep="\t", index = False)
    return df

if __name__ == "__main__":
    cleanup(sys.argv[1], sys.argv[2])