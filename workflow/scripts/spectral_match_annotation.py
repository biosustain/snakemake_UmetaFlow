import pandas as pd
import os
import sys
from pyopenms import *
import pyteomics
from pyteomics import mztab
from pyteomics import mgf, auxiliary
from pathlib import Path


def ms2matches(MZTAB, MGF, MZML, MATRIX, MSMS_MATRIX):
    # MzML file with MS2 spectra
    exp = MSExperiment()
    MzMLFile().load(MZML, exp)
    df = exp.get_df()
    df["index"] = [spec.getNativeID() for spec in exp]
    df["SCANS"] = [spec.getMetaValue("Scan_ID") for spec in exp]
    df["index"] = df["index"].str.replace(r"index=", "")

    # MGF File
    file = mgf.MGF(
        source=MGF,
        use_header=True,
        convert_arrays=2,
        read_charges=True,
        read_ions=False,
        dtype=None,
        encoding=None,
    )
    parameters = []
    for spectrum in file:
        parameters.append(spectrum["params"])
    mgf_file = pd.DataFrame(parameters)
    mgf_file["feature_id"] = mgf_file["feature_id"].str.replace(r"e_", "")

    # Input Feature Matrix
    DF_features = pd.read_csv(MATRIX, sep="\t")
    DF_features.head()

    # Spectral Matches from MzTab File
    spectralmatch =  pyteomics.mztab.MzTab(MZTAB, encoding="UTF8", table_format="df")
    spectralmatch.metadata
    spectralmatch_DF = spectralmatch.small_molecule_table
    spectralmatch_DF = spectralmatch_DF.drop(columns= ["identifier", "inchi_key", "modifications", "calc_mass_to_charge", "opt_adduct_ion", "taxid", "species", "database", "spectra_ref", "search_engine", "opt_sec_id","smallmolecule_abundance_std_error_study_variable[1]", "smallmolecule_abundance_stdev_study_variable[1]", "smallmolecule_abundance_study_variable[1]", "chemical_formula"])
    spectralmatch_DF =spectralmatch_DF[spectralmatch_DF["opt_ppm_error"] <= 10] 
    spectralmatch_DF =spectralmatch_DF[spectralmatch_DF["opt_ppm_error"] >= -10]
    spectralmatch_DF =spectralmatch_DF[spectralmatch_DF["opt_match_score"] >= 60]
    spectralmatch_DF["opt_spec_native_id"]= spectralmatch_DF["opt_spec_native_id"].str.replace(r"index=", "")
    spectralmatch_DF  

    # Add Scan numbers to spectral match DF
    spectralmatch_DF["SCANS"] = ""
    for i, idx in zip(spectralmatch_DF.index, spectralmatch_DF["opt_spec_native_id"]):
        hits = []
        for (
            index,
            scan_number,
        ) in zip(df["index"], df["SCANS"]):
            if idx == index:
                hit = f"{scan_number}"
                if hit not in hits:
                    hits.append(hit)
        spectralmatch_DF.loc[i, "SCANS"] = " ## ".join(hits)

    # Add Scan numbers to feature DF
    scans = []
    for consensus_id in DF_features["id"].astype(str):
        hits = []
        for scan, mgf_id in zip(mgf_file["scans"], mgf_file["feature_id"]):
            if consensus_id == mgf_id:
                hit = f"{scan}"
                if hit not in hits:
                    hits.append(hit)
        scans.append(" ## ".join(hits))

    DF_features["SCANS"] = scans

    DF_features["SpectralMatch"] = ""
    DF_features["SpectralMatch_smiles"] = ""

    for i, scan in zip(DF_features.index, DF_features["SCANS"]):
        hits1 = []
        hits2 = []
        for (
            name,
            smiles,
            scan_number,
        ) in zip(
            spectralmatch_DF["description"],
            spectralmatch_DF["smiles"],
            spectralmatch_DF["SCANS"],
        ):
            if scan == scan_number:
                hit1 = f"{name}"
                hit2 = f"{smiles}"
                if hit1 not in hits1:
                    hits1.append(hit1)
                    hits2.append(hit2)
        DF_features.loc[i, "SpectralMatch"] = " ## ".join(hits1)
        DF_features.loc[i, "SpectralMatch_smiles"] = " ## ".join(hits2)
    
    DF_features.to_csv(MSMS_MATRIX, sep="\t", index=False)
    return MSMS_MATRIX


if __name__ == "__main__":
    ms2matches(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
