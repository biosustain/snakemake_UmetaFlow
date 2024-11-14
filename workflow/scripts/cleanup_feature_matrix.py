import pandas as pd
from pathlib import Path
from pyopenms import *
import sys
import re


def cleanup(input_tsv, output_tsv):
    df = pd.read_csv(input_tsv, sep="\t", index_col=0)
    if not df.empty:
        # Fill numerical columns with 0
        df[df.select_dtypes(include="number").columns] = df.select_dtypes(
            include="number"
        ).fillna(0)

        # Fill non-numerical columns with ""
        df[df.select_dtypes(exclude="number").columns] = df.select_dtypes(
            exclude="number"
        ).fillna("")

        # Remove columns which contain feature IDs for individual files
        df = df.drop(columns=[c for c in df.columns if c.endswith("_IDs")])

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

    else:
        raise IOError(f"Feature Matrix is empty: {input_tsv}")


if __name__ == "__main__":
    cleanup(sys.argv[1], sys.argv[2])
