import pandas as pd
import numpy as np
from pyopenms import *
import sys


def cleanup(input_cmap, output_tsv):
    feature_map = FeatureMap()
    FeatureXMLFile().load(input_cmap, feature_map)
    df = feature_map.get_df()
    for cf in feature_map:
        if cf.metaValueExists("dc_charge_adducts"):
            df["adduct"] = [cf.getMetaValue("dc_charge_adducts") for cf in feature_map]
            break
    df = df.reset_index()
    df = df.drop(
        columns=[
            "peptide_sequence",
            "peptide_score",
            "ID_filename",
            "ID_native_id",
            "RTstart",
            "RTend",
            "MZstart",
            "MZend",
        ]
    )
    df = df.rename({"RT": "RT(s)", "mz": "m/z"})
    df.to_csv(output_tsv, sep="\t", index=False)
    return df


if __name__ == "__main__":
    cleanup(sys.argv[1], sys.argv[2])
