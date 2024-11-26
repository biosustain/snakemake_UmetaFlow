import pandas as pd
from pathlib import Path
import sys


def sirius_annotations(requant, annotated, combine_annotations, csi_canopus):
    df = pd.read_csv(Path("results", "Interim", ("Requantification" if requant == "true" else "Preprocessing"), "FeatureMatrix.tsv") , sep="\t")

    sirius_projects_dirs = [p for p in Path(Path(annotated).parent.parent, "SIRIUS", "sirius-projects").iterdir() if p.is_dir()]

    # Define data to annotate
    tools = ["SIRIUS", "CSI:FingerID", "CANOPUS"]
    annotation_files = [
                "formula_identifications.tsv",
                "compound_identifications.tsv",
                "canopus_compound_summary.tsv",
            ]
    column_names = [
                ["molecularFormula", "explainedIntensity"],
                ["molecularFormula", "name", "InChI", "smiles"],
                [
                    "NPC#pathway",
                    "NPC#superclass",
                    "NPC#class",
                    "ClassyFire#most specific class",
                ],
            ]
    # Annotate for each input file (aka each sirius project directory)
    for p in sirius_projects_dirs:
        for tool, annotation_file, cols in zip(tools, annotation_files, column_names):
            if tool in ("CSI:FingerID", "CANOPUS") and csi_canopus == "false":
                continue
            file = Path(p, annotation_file)
            if file.exists():
                df_tmp = pd.read_csv(file, sep="\t")
                df_tmp["id"] = df_tmp["id"].apply(
                    lambda x: x.split("_0_")[1].split("-")[0]
                )
                for col in cols:
                    df[
                        f"{p.name}_{tool}_{col.replace('NPC#', '').replace('ClassyFire#', '')}"
                    ] = df[f"{p.name}.mzML_IDs"].astype(str).map(
                        df_tmp.set_index("id")[col].to_dict()
                    )
    
    if combine_annotations == "true":
        # Create summary columns, where the file origin is omitted ("##" separated lists)
        for tool, columns in zip(tools, column_names):
            if tool in ("CSI:FingerID", "CANOPUS") and csi_canopus == "false":
                continue
            for col in columns:
                if "#" in col:
                    col = col.split("#")[1]
                single_file_cols = [c for c in df.columns if c.endswith(f"{tool}_{col}") and len(col) != len(c)]
                df[f"{tool}_{col}"] = df[single_file_cols].apply(lambda row: " ## ".join(set(row.dropna().astype(str).tolist())), axis=1)
        # Remove individual SIRIUS, CSI and CANOPUS file columns
        df = df.drop(
            columns=[
                c
                for c in df.columns
                if ("_SIRIUS" in c or "_CSI" in c or "_CANOPUS" in c)
            ]
        )

    df.to_csv(annotated, sep="\t", index=False)


if __name__ == "__main__":
    sirius_annotations(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
