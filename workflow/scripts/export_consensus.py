
from pyopenms import ConsensusMap, ConsensusXMLFile
import pandas as pd
from pathlib import Path
import sys


def cleanup(input_cmap, output_tsv):
    # Load consensusXML file
    consensus_map = ConsensusMap()
    ConsensusXMLFile().load(input_cmap, consensus_map)

    # Export Pandas DataFrame
    df = consensus_map.get_df()

    # Add adduct meta value
    for cf in consensus_map:
        if cf.metaValueExists("best ion"):
            if "adduct" in df.columns:
                df = df.drop(columns="adduct")
            df.insert(5, "adduct", [cf.getMetaValue("best ion") for cf in consensus_map])
            break
    
    # Annotate feature IDs from samples
    fnames = [Path(value.filename).name for value in consensus_map.getColumnHeaders().values()]

    ids = [[] for _ in fnames]

    for cf in consensus_map:
        fids = {f.getMapIndex(): f.getUniqueId() for f in cf.getFeatureList()}
        for i in range(len(fnames)):
            if i in fids.keys():
                ids[i].append(str(fids[i]))
            else:
                ids[i].append(pd.NA)

    for i in range(len(fnames)):
        df[f"{fnames[i]}_IDs"] = ids[i]

    df = df.drop(columns="sequence")

    # Write to tsv file
    df.to_csv(output_tsv, sep="\t")
    return df


if __name__ == "__main__":
    cleanup(sys.argv[1], sys.argv[2])
