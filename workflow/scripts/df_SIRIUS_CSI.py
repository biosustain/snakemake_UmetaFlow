import pandas
import pyteomics
from pyteomics.openms import featurexml
from pyteomics import mztab
import sys

def df_sirius_csi(input_sirius, input_csi, output_sirius, output_csi):
    sirius=  pyteomics.mztab.MzTab(input_sirius, encoding='UTF8', table_format='df')
    sirius.metadata
    df= sirius.small_molecule_table
    SIRIUS_DF= df.drop(columns= ["identifier", "smiles", "inchi_key", "description", "calc_mass_to_charge", "charge", "taxid", "species","database", "database_version", "spectra_ref", "search_engine", "modifications"])
    SIRIUS_DF=SIRIUS_DF[SIRIUS_DF["opt_global_explainedIntensity"] >= 0.4] #opt_global_explainedIntensity should be higher than 0.8 or 0.9 even for reliable results. We filter out only the ones below 0.4 since there are cases of correct formula assignment in the range above that number
    SIRIUS_DF= SIRIUS_DF.rename(columns= {"best_search_engine_score[1]":	"SiriusScore"}) #This score is the sum of the fragmentation pattern scoring ("TreeScore") and the isotope pattern scoring ("IsotopeScore")
    SIRIUS_DF= SIRIUS_DF.rename(columns= {"best_search_engine_score[2]":	"TreeScore"})
    SIRIUS_DF= SIRIUS_DF.rename(columns= {"best_search_engine_score[3]":	"IsotopeScore"}) #The closer to 10, the higher the quality of the isotope pattern
    SIRIUS_DF=SIRIUS_DF[SIRIUS_DF["IsotopeScore"] >= 0.0] #Isotope scores that are equal to zero are very low quality and filtered out
    SIRIUS_DF.to_csv(output_sirius, sep="\t")

    CSI=  pyteomics.mztab.MzTab(input_csi, encoding='UTF8', table_format='df')
    CSI.metadata
    csifingerID= CSI.small_molecule_table
#    csifingerID= df.drop(columns= ["calc_mass_to_charge", "charge", "taxid", "species","database", "database_version", "spectra_ref", "search_engine", "modifications"])
    csifingerID.to_csv(output_csi, sep="\t")
    return SIRIUS_DF, csifingerID

if __name__ == "__main__":
    df_sirius_csi(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])