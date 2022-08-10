# Integrating into Graphml
import pandas as pd
import networkx as nx
import glob
import os
import sys
from pyteomics import mgf, auxiliary

def integration(input_matrix, input_mgf, input_graphml, output_graphml):
    # input matrix
    Matrix= pd.read_csv(input_matrix, sep="\t")
    Matrix["id"]= Matrix["id"].astype(str)
    Matrix["feature_ids"]= Matrix["feature_ids"].values.tolist()
    #input mgf file
    file= mgf.MGF(source=input_mgf, use_header=True, convert_arrays=2, read_charges=True, read_ions=False, dtype=None, encoding=None)
    parameters=[]
    for spectrum in file:
        parameters.append(spectrum['params'])
    mgf_file= pd.DataFrame(parameters)
    mgf_file["feature_id"]= mgf_file["feature_id"].str.replace(r"e_", "")
    #add scan number from mgf file by matching feature_IDs
    Matrix.insert(0, "SCANS", "")
    for i, id in zip(Matrix.index, Matrix["id"]):
        hits = []
        for scans, feature_id in zip(mgf_file["scans"], mgf_file["feature_id"]): 
            if feature_id==id:
                hit = f"{scans}"
                if hit not in hits:
                    hits.append(hit)
        Matrix["SCANS"][i] = " ## ".join(hits)
    #introduce the SIRIUS predictions
    input_formulas= glob.glob(os.path.join("results", "SiriusCSI", "formulas_*.tsv"))
    DF_SIRIUS = pd.DataFrame()
    list_of_df=[]
    for tsv in input_formulas:
        df= pd.read_csv(tsv, sep="\t", index_col="Unnamed: 0")
        s= df["opt_global_rank"]
        pd.to_numeric(s)
        df= df.loc[df["opt_global_rank"]==1]
        df=df.reset_index()
        list_of_df.append(df)
    DF_SIRIUS= pd.concat(list_of_df,ignore_index=True)
    DF_SIRIUS= DF_SIRIUS.drop(columns="index")
    DF_SIRIUS["opt_global_featureId"]= DF_SIRIUS["opt_global_featureId"].str.replace(r"id_", "")
    #add the scan number to the SIRIUS predictions   
    DF_SIRIUS.insert(0, "SCANS", "")
    for i, Pred_id in zip(DF_SIRIUS.index, DF_SIRIUS["opt_global_featureId"]):
        hits = []
        for scans, feature_id in zip(Matrix["SCANS"], Matrix["feature_ids"]): 
            if Pred_id in feature_id:
                hit = f"{scans}"
                if hit not in hits:
                    hits.append(hit)
        DF_SIRIUS["SCANS"][i] = " ## ".join(hits)
    #introduce the CSI predictions
    input_structures= glob.glob(os.path.join("results", "SiriusCSI", "structures_*.tsv"))
    DF_CSI = pd.DataFrame()
    list_of_df=[]
    for tsv in input_structures:
        df= pd.read_csv(tsv, sep="\t", index_col="Unnamed: 0")
        s= df["opt_global_rank"]
        pd.to_numeric(s)
        df= df.loc[df["opt_global_rank"]==1]
        df=df.reset_index()
        list_of_df.append(df)
    DF_CSI= pd.concat(list_of_df,ignore_index=True)
    DF_CSI= DF_CSI.drop(columns="index")
    DF_CSI["opt_global_featureId"]= DF_CSI["opt_global_featureId"].str.replace(r"id_", "")
    #add the scan number to the CSI predictions   
    DF_CSI.insert(0, "SCANS", "")

    for i, Pred_id in zip(DF_CSI.index, DF_CSI["opt_global_featureId"]):
        hits = []
        for scans, feature_id in zip(Matrix["SCANS"], Matrix["feature_ids"]): 
            if Pred_id in feature_id:
                hit = f"{scans}"
                if hit not in hits:
                    hits.append(hit)
        DF_CSI["SCANS"][i] = " ## ".join(hits)
    #read the graphml file downloaded from GNPS FBMN and add the SIRIUS and CSI information
    G = nx.read_graphml(input_graphml)
    for result in DF_SIRIUS.to_dict(orient="records"):
        scan = str(result["SCANS"])
        if scan in G:
            G.nodes[scan]["sirius:molecularFormula"] = result["chemical_formula"]
            G.nodes[scan]["sirius:adduct"] = result["opt_global_adduct"]
            G.nodes[scan]["sirius:TreeScore"] = result["TreeScore"]
            G.nodes[scan]["sirius:IsotopeScore"] = result["IsotopeScore"]
            G.nodes[scan]["sirius:explainedPeaks"] = result["opt_global_explainedPeaks"]
            G.nodes[scan]["sirius:explainedIntensity"] = result["opt_global_explainedIntensity"]
            G.nodes[scan]["sirius:explainedPeaks"] = result["opt_global_explainedPeaks"]

    for result in DF_CSI.to_dict(orient="records"):
        scan = str(result["SCANS"])
        if scan in G:
            G.nodes[scan]["csifingerid:smiles"] = result["smiles"]
            G.nodes[scan]["csifingerid:Confidence_Score"] = result["best_search_engine_score[1]"]
            G.nodes[scan]["csifingerid:dbflags"] = result["opt_global_dbflags"]
            G.nodes[scan]["csifingerid:description"] = result["description"]

    nx.write_graphml(G, output_graphml)

if __name__ == "__main__":
    integration(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])