import numpy as np
import pandas as pd
import sys
from pyteomics import mgf, auxiliary

def GNPS_annotations(lib, featurematrix, mgf_path, gnps):
    #import GNPS MSMS library matches
    df= pd.read_csv(lib, sep="\t")
    df.drop(df.index[df['IonMode'] == "negative"], inplace=True)
    df.drop(df.index[df['MZErrorPPM'] > 10.0], inplace=True)
    GNPS=df.drop_duplicates(subset="Compound_Name", keep='first')
    GNPS["#Scan#"]= GNPS["#Scan#"].astype(str)
    #Import annonated feature matrix
    Matrix= pd.read_csv(featurematrix, sep="\t")
    Matrix["id"]= Matrix["id"].astype(str)
    Matrix["feature_ids"]= Matrix["feature_ids"].values.tolist()
    #Import MGF file with SCAN numbers
    file= mgf.MGF(source=mgf_path, use_header=True, convert_arrays=2, read_charges=True, read_ions=False, dtype=None, encoding=None)
    parameters=[]
    for spectrum in file:
        parameters.append(spectrum['params'])
    mgf_file= pd.DataFrame(parameters)
    mgf_file["feature_id"]= mgf_file["feature_id"].str.replace(r"e_", "")
    #Add SCAN numbers to the feature matrix
    Matrix.insert(0, "SCANS", "")
    for i, id in zip(Matrix.index, Matrix["id"]):
        hits = []
        for scan, feature_id in zip(mgf_file["scans"], mgf_file["feature_id"]): 
            if feature_id==id:
                hit = f"{scan}"
                if hit not in hits:
                    hits.append(hit)
        Matrix["SCANS"][i] = " ## ".join(hits)                  

    Matrix.insert(0, "GNPS", "")

    for i, scan in zip(Matrix.index, Matrix["SCANS"]):
        hits = []
        for name, scan_number, in zip(GNPS["Compound_Name"], GNPS["#Scan#"]):
            if scan==scan_number:
                hit = f"{name}"
                if hit not in hits:
                    hits.append(hit)
        Matrix["GNPS"][i] = " ## ".join(hits)

    Matrix.to_csv(gnps, sep="\t", index = False)
    return Matrix

if __name__ == "__main__":
    GNPS_annotations(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])