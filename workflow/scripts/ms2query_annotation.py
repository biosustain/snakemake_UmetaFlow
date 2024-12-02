import pandas as pd
from pathlib import Path
import sys


def ms2query_annotations(requant, annotated, ms2query_csv):
    df = pd.read_csv(Path("results", "Interim", ("Requantification" if requant == "true" else "Preprocessing"), "FeatureMatrix.tsv") , sep="\t", index_col=0)

    df_ms2query = pd.read_csv(ms2query_csv)
    df_ms2query["feature_id"] = df_ms2query["feature_id"].apply(lambda x: int(x[2:]))
    df_ms2query = df_ms2query.set_index("feature_id")

    ms2query_columns = ["inchikey", "analog_compound_name", "smiles", "cf_kingdom", "cf_superclass", "cf_class", "cf_subclass", "cf_direct_parent", "npc_class_results", "npc_superclass_results", "npc_pathway_results"]

    for i in df.index:
        if i in df_ms2query.index:
            for col in ms2query_columns:
                df.loc[i, f"MS2Query_{col}"] = df_ms2query.loc[i, col]
    df.to_csv(annotated, sep="\t")

if __name__ == "__main__":
    ms2query_annotations(sys.argv[1], sys.argv[2], sys.argv[3])
