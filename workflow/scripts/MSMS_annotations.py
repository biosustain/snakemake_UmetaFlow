import pandas as pd
import glob
import os
import sys
from pyopenms import *
import pyteomics
from pyteomics import mztab
from pyteomics import mgf, auxiliary

def merge(MZTAB, MGF, MZML, MATRIX, MSMS_MATRIX):

    spectralmatch=  pyteomics.mztab.MzTab(MZTAB, encoding="UTF8", table_format="df")
    spectralmatch.metadata
    df= spectralmatch.small_molecule_table
    spectralmatch_DF= df.drop(columns= ["identifier", "inchi_key", "modifications", "calc_mass_to_charge", "opt_adduct_ion", "taxid", "species", "database", "spectra_ref", "search_engine", "opt_sec_id","smallmolecule_abundance_std_error_study_variable[1]", "smallmolecule_abundance_stdev_study_variable[1]", "smallmolecule_abundance_study_variable[1]", "chemical_formula"])
    spectralmatch_DF=spectralmatch_DF[spectralmatch_DF["opt_ppm_error"] <= 10] 
    spectralmatch_DF=spectralmatch_DF[spectralmatch_DF["opt_ppm_error"] >= -10]
    spectralmatch_DF=spectralmatch_DF[spectralmatch_DF["opt_match_score"] >= 60]
    spectralmatch_DF["opt_spec_native_id"]= spectralmatch_DF["opt_spec_native_id"].str.replace(r"index=", "")       

    exp = MSExperiment()
    MzMLFile().load(MZML, exp)
    exp.sortSpectra(True)
    df= exp.get_df()
    for spec in exp:
        df["index"]= [spec.getNativeID() for spec in exp]
        df["SCANS"]= [spec.getMetaValue("Scan_ID") for spec in exp]
    df["index"]= df["index"].str.replace(r"index=", "")

    spectralmatch_DF.insert(0, "SCANS", "")

    for i, idx in zip(spectralmatch_DF.index, spectralmatch_DF["opt_spec_native_id"]):
        hits = []
        for index, scan_number, in zip(df["index"], df["SCANS"]):
            if idx==index:
                hit = f"{scan_number}"
                if hit not in hits:
                    hits.append(hit)
        spectralmatch_DF["SCANS"][i] = " ## ".join(hits)

    file= mgf.MGF(source=MGF, use_header=True, convert_arrays=2, read_charges=True, read_ions=False, dtype=None, encoding=None)
    parameters=[]
    for spectrum in file:
        parameters.append(spectrum['params'])
    mgf_file= pd.DataFrame(parameters)
    mgf_file["feature_id"]= mgf_file["feature_id"].str.replace(r"e_", "")
    
    Matrix= pd.read_csv(MATRIX, sep="\t")
    Matrix["id"]= Matrix["id"].astype(str)
    Matrix["feature_ids"]= Matrix["feature_ids"].values.tolist()
    Matrix.insert(0, "SCANS", "")
    for i, id in zip(Matrix.index, Matrix["id"]):
        hits = []
        for scan, feature_id in zip(mgf_file["scans"], mgf_file["feature_id"]): 
            if feature_id==id:
                hit = f"{scan}"
                if hit not in hits:
                    hits.append(hit)
        Matrix["SCANS"][i] = " ## ".join(hits)

    Matrix.insert(0, "description", "")
    Matrix.insert(0, "smiles", "")

    for i, scan in zip(Matrix.index, Matrix["SCANS"]):
        hits1 = []
        hits2=[]
        for name, smiles, scan_number, in zip(spectralmatch_DF["description"],spectralmatch_DF["smiles"], spectralmatch_DF["SCANS"]):
            if scan==scan_number:
                hit1 = f"{name}"
                hit2 = f"{smiles}"
                if hit1 not in hits1:
                    hits1.append(hit1)
                    hits2.append(hit2)
        Matrix["description"][i] = " ## ".join(hits1)
        Matrix["smiles"][i] = " ## ".join(hits2)
    Matrix.to_csv(MSMS_MATRIX, sep="\t", index = False)
    return MSMS_MATRIX

if __name__ == "__main__":
    merge(sys.argv[1], sys.argv[2], sys.argv[3],  sys.argv[4],  sys.argv[5])