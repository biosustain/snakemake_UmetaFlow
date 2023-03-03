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
    df.to_csv(os.path.join("config", "samples.tsv"), sep="\t")
else:
    df["sample_name"]=df["sample_name"].replace(".raw", value="", regex=True)
    df["comment"] = " "
    df["MAPnumber"] = " "
    df.to_csv(os.path.join("config", "dataset.tsv"), sep="\t")
    df.to_csv(os.path.join("config", "samples.tsv"), sep="\t")

print(df["sample_name"])
fList =input("Please enter a list of comma separated filenames for your blanks, QCs or control samples from the filelist: ").split(",")
blank_DF = pd.DataFrame({"sample_name":fList})
for i, blank in zip(blank_DF.index, blank_DF["sample_name"]):
    for i, filename in zip(df.index, df["sample_name"]):
        if blank==filename:
            blank_DF["sample_name"][i] = df["sample_name"][i]
    blank_DF["comment"]= " "
    blank_DF["MAPnumber"] = " "
    blank_DF.to_csv(os.path.join("config", "blanks.tsv"), sep="\t", index=None)

sample_DF = df
if blank_DF.empty:
    sample_DF.to_csv(os.path.join("config", "samples.tsv"), sep="\t")
else:
    for blank in fList:
        sample_DF= sample_DF[sample_DF["sample_name"].str.contains(blank)==False ]
    sample_DF.to_csv(os.path.join("config", "samples.tsv"), sep="\t")