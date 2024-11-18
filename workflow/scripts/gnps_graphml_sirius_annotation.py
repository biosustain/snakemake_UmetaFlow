# Integrating into Graphml
import pandas as pd
import networkx as nx
import sys
from pyteomics import mgf

def integration(input_matrix, input_mgf, input_graphml, output_graphml):

    matrix = pd.read_csv(input_matrix, sep="\t")
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

    G = nx.read_graphml(input_graphml)
    for i, row in matrix.iterrows():
        scans = [s for s in row["SCANS"].split("#") if s]
        if scans:
            for term in ["SIRIUS_molecularFormula",
                        "SIRIUS_explainedIntensity",
                        "CSI:FingerID_molecularFormula",
                        "CSI:FingerID_name",
                        "CSI:FingerID_InChI",
                        "CSI:FingerID_smiles",
                        "CANOPUS_pathway",
                        "CANOPUS_superclass",
                        "CANOPUS_class",
                        "CANOPUS_most specific class",
                        "SpectralMatch",
                        "SpectralMatch_smiles"]:
                for col in [col for col in matrix.columns if col.endswith(term)]:
                    if not pd.isna(row[col]):
                        for scan in scans:
                            if scan in G.nodes:
                                G.nodes[scan][col] = str(row[col])

    nx.write_graphml(G, output_graphml)


if __name__ == "__main__":
    integration(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
