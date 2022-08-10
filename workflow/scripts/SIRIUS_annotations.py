import pandas as pd
import glob
import os
import sys

def sirius_annotations(matrix, annotated):
    input_formulas= glob.glob(os.path.join("results", "Sirius", "formulas_*.tsv"))
    DF_SIRIUS = pd.DataFrame()
    list_of_df=[]
    for csv in input_formulas:
        df= pd.read_csv(csv, sep="\t", index_col="Unnamed: 0")
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
    DF_SIRIUS= DF_SIRIUS.rename(columns= {"chemical_formula": "formulas", "exp_mass_to_charge": "mz", "retention_time": "RT"})
    DF_SIRIUS["featureId"]= DF_SIRIUS["featureId"].str.replace(r"id_", "")
    for i, rows in DF_SIRIUS.iterrows():
        DF_SIRIUS["featureId"][i]= DF_SIRIUS["featureId"][i].split(",")

    DF_features= pd.read_csv(matrix, sep="\t")
    DF_features= DF_features.drop(columns=["quality", "id"])
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
        DF_features["SIRIUS_predictions"][i] = " ## ".join(hits)

    DF_features.to_csv(annotated, sep="\t", index= None)
    return DF_features

if __name__ == "__main__":
    sirius_annotations(sys.argv[1], sys.argv[2])