import pandas as pd
import numpy as np 
import sys

def build_library(matrix, lib):
    FeatureMatrix= matrix
    with open(FeatureMatrix, 'r') as file:
        for i,line in enumerate(file):
            if '#CONSENSUS' in line:
                header = line.split('\t')
                break

    positions = [i for i,col in enumerate(header)]

    def thin():
        with open(FeatureMatrix, 'r') as file:
            for i,line in enumerate(file):
                if '#CONSENSUS' in line:
                    header = line
                if '#' in line:
                    continue
                if 'MAP' in line:
                    continue
                if 'RUN' in line:
                    continue
                row = line.split('\t')
                row = [row[i] for i in positions]
                yield row


    DF_features = pd.DataFrame(thin(), columns=header)
    DF_features = DF_features[["rt_cf","mz_cf", "charge_cf"]]
    DF_features= DF_features.rename(columns={ "charge_cf":"Charge", "mz_cf": "Mass", "rt_cf": "RetentionTime"})
    DF_features["Charge"]= DF_features["Charge"].astype(str)
    DF_features["Mass"]= DF_features["Mass"].astype(float)

#For positive ionisation: comment this for negative ESI
    for ind in DF_features.index:
        if DF_features["Charge"][ind] == "0":
            DF_features.loc[ind, "Mass"]= DF_features.loc[ind,"Mass"]- 1.007825
        if DF_features["Charge"][ind] == "1":
            DF_features.loc[ind, "Mass"]= DF_features.loc[ind,"Mass"]- 1.007825
        if DF_features["Charge"][ind] == "2":
            DF_features.loc[ind, "Mass"]= (DF_features.loc[ind,"Mass"]*2)- 2.015650
        if DF_features["Charge"][ind] == "3":
            DF_features.loc[ind, "Mass"]= (DF_features.loc[ind,"Mass"]*3)- 3.023475
    DF_features["Charge"]= DF_features["Charge"].astype(str)
    for ind in DF_features.index:
        if DF_features["Charge"][ind] == "0":
            DF_features.loc[ind, "Charge"]= "+1"
        if DF_features["Charge"][ind] == "1":
            DF_features.loc[ind, "Charge"]= "+" + DF_features.loc[ind,"Charge"]
        if DF_features["Charge"][ind] == "2":
            DF_features.loc[ind, "Charge"]= "+" + DF_features.loc[ind,"Charge"]
        if DF_features["Charge"][ind] == "3":
            DF_features.loc[ind, "Charge"]= "+" + DF_features.loc[ind,"Charge"]

# For negative ionisation: uncomment this for negative ESI
    # for ind in DF_features.index:
    #     if DF_features["Charge"][ind] == "0":
    #         DF_features.loc[ind, "Mass"]= DF_features.loc[ind,"Mass"]+ 1.007825
    #     if DF_features["Charge"][ind] == "1":
    #         DF_features.loc[ind, "Mass"]= DF_features.loc[ind,"Mass"]+ 1.007825
    #     if DF_features["Charge"][ind] == "2":
    #         DF_features.loc[ind, "Mass"]= (DF_features.loc[ind,"Mass"]*2)+ 2.015650
    #     if DF_features["Charge"][ind] == "3":
    #         DF_features.loc[ind, "Mass"]= (DF_features.loc[ind,"Mass"]*3)+ 3.023475
    # DF_features["Charge"]= DF_features["Charge"].astype(str)
    # for ind in DF_features.index:
    #     if DF_features["Charge"][ind] == "0":
    #         DF_features.loc[ind, "Charge"]= "-1"
    #     if DF_features["Charge"][ind] == "1":
    #         DF_features.loc[ind, "Charge"]= "-" + DF_features.loc[ind,"Charge"]
    #     if DF_features["Charge"][ind] == "2":
    #         DF_features.loc[ind, "Charge"]= "-" + DF_features.loc[ind,"Charge"]
    #     if DF_features["Charge"][ind] == "3":
    #         DF_features.loc[ind, "Charge"]= "-" + DF_features.loc[ind,"Charge"]

    DF_features["CompoundName"] = np.arange(len(DF_features))
    DF_features["CompoundName"] = "feature_" + DF_features["CompoundName"].astype(str)
    DF_features["SumFormula"] = " "
    DF_features["RetentionTimeRange"]= "0"
    DF_features["IsoDistribution"]= "0"
    DF_features= DF_features[["CompoundName","SumFormula", "Mass","Charge","RetentionTime","RetentionTimeRange", "IsoDistribution"]]
    DF_features.to_csv(lib, sep="\t", index= None)
    return DF_features

if __name__ == "__main__":
    build_library(sys.argv[1], sys.argv[2])