import pandas as pd
import glob
import os
import sys

def sirius_csi_annotations(matrix, annotated):
    input_formulas= glob.glob(os.path.join("results", "SiriusCSI", "formulas_*.tsv"))
    DF_SIRIUS = pd.DataFrame()
    list_of_df=[]
    for tsv in input_formulas:
        df= pd.read_csv(tsv, sep="\t", index_col="Unnamed: 0")
        s= df["opt_global_rank"]
        pd.to_numeric(s)
        df= df.loc[df["opt_global_rank"]==1]
        df= df.rename(columns={"opt_global_featureId":"featureId"})
        df= df.drop(columns=df.filter(regex=fr"Score").columns)
        df= df.drop(columns= df.filter(regex=fr"opt").columns)
        df=df.reset_index()
        list_of_df.append(df)
    DF_SIRIUS= pd.concat(list_of_df,ignore_index=True)
    DF_SIRIUS= DF_SIRIUS.drop(columns="index")
    DF_SIRIUS= DF_SIRIUS.rename(columns= {"chemical_formula": "formulas", "exp_mass_to_charge": "m/z", "retention_time": "RT(s)"})
    DF_SIRIUS["featureId"]= DF_SIRIUS["featureId"].str.replace(r"id_", "")
    for i, rows in DF_SIRIUS.iterrows():
        DF_SIRIUS["featureId"][i]= DF_SIRIUS["featureId"][i].split(",")

    input_structures= glob.glob(os.path.join("results", "SiriusCSI", "structures_*.tsv"))
    DF_CSI = pd.DataFrame()
    list_of_df=[]
    for tsv in input_structures:
        df= pd.read_csv(tsv, sep="\t", index_col="Unnamed: 0")
        s= df["opt_global_rank"]
        pd.to_numeric(s)
        df= df.loc[df["opt_global_rank"]==1]
        df= df.rename(columns={"opt_global_featureId":"featureId"})
        df= df.rename(columns={"opt_global_dblinks":"db"})
        df= df.drop(columns=df.filter(regex=fr"Score").columns)
        df= df.drop(columns= df.filter(regex=fr"opt").columns)
        df=df.reset_index()
        list_of_df.append(df)
    DF_CSI= pd.concat(list_of_df,ignore_index=True)
    DF_CSI= DF_CSI.drop(columns="index")
    DF_CSI= DF_CSI.rename(columns= {"chemical_formula": "formulas", "exp_mass_to_charge": "m/z", "retention_time": "RT(s)", "description":"name"})
    DF_CSI["featureId"]= DF_CSI["featureId"].str.replace(r"id_", "")
    for i, rows in DF_CSI.iterrows():
        DF_CSI["featureId"][i]= DF_CSI["featureId"][i].split(",")

    DF_features= pd.read_csv(matrix, sep="\t")
    DF_features= DF_features.drop(columns=["quality"])
    DF_features= DF_features.fillna(0)
    DF_features["feature_ids"]= [ids[1:-1].split(",") for ids in DF_features["feature_ids"]]

    DF_features.insert(0, "SIRIUS_predictions", "")

    for i, id in zip(DF_features.index, DF_features["feature_ids"]):
        hits = []
        for name, Pred_id in zip(DF_SIRIUS["formulas"], DF_SIRIUS["featureId"]): 
            for x,y in zip(id,Pred_id):
                if x==y:
                    hit = f"{name}"
                    if hit not in hits:
                        hits.append(hit)
        DF_features["SIRIUS_predictions"][i] = ", ".join(hits)

    DF_features.insert(0, "CSI_predictions_name", "")
    DF_features.insert(0, "CSI_predictions_formula", "")
    DF_features.insert(0, "CSI_predictions_smiles", "")
    DF_features.insert(0, "CSI_db_links", "")

    for i, id, sirius in zip(DF_features.index, DF_features["feature_ids"], DF_features["SIRIUS_predictions"]):
        hits1 = []
        hits2= []
        hits3=[]
        hits4=[]
        for name, formula, smiles, Pred_id, db in zip(DF_CSI["name"], DF_CSI["formulas"], DF_CSI["smiles"], DF_CSI["featureId"], DF_CSI["db"]): 
            for x,y in zip(id,Pred_id):
                if (x==y)& (formula in sirius):
                    hit1 = f"{name}"
                    hit2 = f"{formula}"
                    hit3= f"{smiles}"
                    hit4= f"{db}"
                    if hit1 not in hits1:
                        hits1.append(hit1)
                        hits2.append(hit2)
                        hits3.append(hit3)
                        hits4.append(hit4)
        DF_features["CSI_predictions_name"][i] = " ## ".join(hits1)
        DF_features["CSI_predictions_formula"][i] = " ## ".join(hits2)
        DF_features["CSI_predictions_smiles"][i] = " ## ".join(hits3)
        DF_features["CSI_db_links"][i] = " ## ".join(hits4)

    DF_features.to_csv(annotated, sep="\t", index= None)
    return DF_features

if __name__ == "__main__":
    sirius_csi_annotations(sys.argv[1], sys.argv[2])