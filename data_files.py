import pandas as pd
import os
import numpy as np 
df = pd.DataFrame()
df["sample_name"] = [file for file in os.listdir(os.path.join("data", "raw")) if file.endswith(".raw")]
if df.empty:
    df["sample_name"] = [file for file in os.listdir(os.path.join("data", "mzML")) if file.endswith(".mzML")]
    df["sample_name"]=df["sample_name"].replace(".mzML", value="", regex=True)
    df["comment"] = " "
    df["MAPnumber"] = " "
    df.to_csv(os.path.join("config", "dataset.tsv"), sep="\t")
else:
    df["sample_name"]=df["sample_name"].replace(".raw", value="", regex=True)
    df["comment"] = " "
    df["MAPnumber"] = " "
    df.to_csv(os.path.join("config", "dataset.tsv"), sep="\t")

print(df["sample_name"])
fList =input("Please enter a list of comma separated filenames for your blanks, QCs or control samples from the filelist: ").split(",")
DF_NC = pd.DataFrame({"sample_name":fList})
for i, blank in zip(DF_NC.index, DF_NC["sample_name"]):
    for j, filename in zip(df.index, df["sample_name"]):
        if blank==filename:
            DF_NC["sample_name"][i] = df["sample_name"][j]
    DF_NC["comment"]= " "
    DF_NC["MAPnumber"] = " "
    DF_NC.to_csv(os.path.join("config", "blanks.tsv"), sep="\t")

sample_DF = df
for blank in fList:
    sample_DF= sample_DF[sample_DF["sample_name"].str.contains(blank)==False ]
sample_DF.to_csv(os.path.join("config", "samples.tsv"), sep="\t")