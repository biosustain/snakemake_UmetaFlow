import pandas as pd
from pathlib import Path
from pyopenms import *
import sys
import re


def cleanup(input_tsv, output_tsv):
    df = pd.read_csv(input_tsv, sep="\t", index_col=0)

    # Fill numerical columns with 0
    df[df.select_dtypes(include="number").columns] = df.select_dtypes(
        include="number"
    ).fillna(0)

    # Fill non-numerical columns with ""
    df[df.select_dtypes(exclude="number").columns] = df.select_dtypes(
        exclude="number"
    ).fillna("")

    # Rename feature ID columns and move them to the end of the dataframe
    df = df.rename(columns={c: c.replace("_IDs", "_feature_IDs") for c in df.columns if c.endswith("_IDs")})
    renamed_columns = [c for c in df.columns if c.endswith("_feature_IDs")]
    df = df[[c for c in df.columns if c not in renamed_columns] + renamed_columns]

    # Remove "SCANS", "id" and "quality" columns
    df = df.drop(columns=[c for c in ["SCANS", "id", "quality"] if c in df.columns])

    # Move "charge" column to index 3
    charge = df.pop("charge")
    df.insert(3, "charge", charge)

    # Generate a new "metabolite" index, with format f"{mz}@{RT}@{adduct}"
    df.insert(
        0,
        "metabolite",
        df.apply(
            lambda x: f"{round(x['mz'], 5)}@{round(x['RT'], 2)}"
            + (f"@{x['adduct']}" if pd.notnull(x["adduct"]) else ""),
            axis=1,
        ),
    )
    # Keep consensus feature ID
    df["consensus_feature_IDs"] = df.index
    df = df.set_index("metabolite")

    # Rename RT and mz columns
    df = df.rename(columns={"RT": "RT (s)", "mz": "m/z"})

    # Restore original mzML file name (without PCpeak_, PCfeature_, Aligned_) and without path (data/mzML)
    df = df.rename(
        columns={
            c: re.sub(r"(PCpeak_|PCfeature_|Aligned_)", "", Path(c).name)
            for c in df.columns
            if c.endswith("mzML")
        }
    )

    # Save to current processing subdirectory and top level results directory
    df.to_csv(output_tsv, sep="\t")

    # Complete summary of all annotation tools

    tool_cols = {
        "SpectralMatching": ["SpectralMatch", "SpectralMatch_smiles"],
        "GNPS": ["GNPS"],
        "SIRIUS": ["SIRIUS", "CSI:FingerID", "CANOPUS"],
        "MS2Query": ["MS2Query"]
        }

    for tool, cols in tool_cols.items():
        path = Path("results", tool, "FeatureMatrix.tsv")
        if path.exists():
            tmp = pd.read_csv(path, sep="\t", index_col=0)
            if tool in ("SIRIUS", "MS2Query"):
                tmp_cols = [c for c in tmp.columns if any(key in c for key in cols)]
            else:
                tmp_cols = cols
            df.drop(columns=tmp_cols, errors="ignore")
            df[tmp_cols] = tmp[tmp_cols]
    
    df.to_csv(Path("results", "FeatureMatrix.tsv"), sep="\t")


if __name__ == "__main__":
    cleanup(sys.argv[1], sys.argv[2])
