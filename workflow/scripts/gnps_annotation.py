import numpy as np
import pandas as pd
import sys
from pyteomics import mgf, auxiliary


def GNPS_annotations(lib, input_matrix, input_mgf, output_matrix):
    matrix = pd.read_csv(input_matrix, sep="\t")
    print(matrix)
    matrix["id"]= matrix["id"].astype(str)

    mgf_file = mgf.MGF(source=input_mgf, use_header=True, convert_arrays=2, read_charges=True, read_ions=False, dtype=None, encoding=None)
    parameters=[]
    for spectrum in mgf_file:
        parameters.append(spectrum['params'])
    mgf_df = pd.DataFrame(parameters)
    mgf_df["feature_id"] = mgf_df["feature_id"].str.replace(r"e_", "")

    matrix["SCANS"] = ""
    for i, id in zip(matrix.index, matrix["id"]):
        hits = []
        for scan, feature_id in zip(mgf_df["scans"], mgf_df["feature_id"]): 
            if feature_id==id:
                hit = f"{scan}"
                if hit not in hits:
                    hits.append(hit)
        matrix.loc[i, "SCANS"] = " ## ".join(hits)

    # import GNPS MSMS library matches
    df = pd.read_csv(lib, sep="\t")
    df.drop(df.index[df["IonMode"] == "negative"], inplace=True)
    df.drop(df.index[df["MZErrorPPM"] > 10.0], inplace=True)
    GNPS = df.drop_duplicates(subset="Compound_Name", keep='first')

    gnps = []
    for i, row in matrix.iterrows():
            scans = [s for s in row["SCANS"].split("#") if s]
            hits = []
            if scans:
                for scan in scans:
                    hits.append("##".join(GNPS[GNPS["#Scan#"] == int(scan)]["Compound_Name"].tolist()))
            gnps.append("##".join(hits))
    matrix["GNPS"] = gnps

    matrix.to_csv(output_matrix, sep="\t", index=False)

if __name__ == "__main__":
    GNPS_annotations(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
