import pandas as pd
import glob
import os
import sys

def ms2query_annotations(matrix, ms2query_csv, annotated):
    Matrix= pd.read_csv(matrix, sep="\t")
    Matrix["id"]= Matrix["id"].astype(str)
    Analog_matrix= pd.read_csv(ms2query_csv)
   
    Analog_matrix= Analog_matrix.rename(columns= {"chemical_formula": "formulas", "exp_mass_to_charge": "m/z", "retention_time": "RT(s)"})
    Analog_matrix["feature_id"]= Analog_matrix["feature_id"].str.replace(r"e_", "")

    Matrix.insert(0, "ms2query_score", "")
    Matrix.insert(0, "ms2query_compound_name", "")
    Matrix.insert(0, "ms2query_compound_smiles", "")
    Matrix.insert(0, "ms2query_compound_mz", "")  
    Matrix.insert(0, "ms2query_npc_superclass", "")  
    Matrix.insert(0, "ms2query_cf_superclass", "")  
    Matrix.insert(0, "ms2query_cf_class", "")    
    for i, id in zip(Matrix.index, Matrix["id"]):
        hits1= []
        hits2= []
        hits3= []
        hits4= []
        hits5= []
        hits6= []
        hits7= []
        for score, name, smiles, analog_id, mz, npc_superclass, cf_superclass, cf_class in zip(Analog_matrix["ms2query_model_prediction"], Analog_matrix["analog_compound_name"], Analog_matrix["smiles"], Analog_matrix["feature_id"], Analog_matrix["precursor_mz_query_spectrum"], Analog_matrix["npc_superclass_results"], Analog_matrix["cf_superclass"], Analog_matrix["cf_class"]): 
            if analog_id==id:
                    hit1 = f"{score}"
                    hit2 = f"{name}"
                    hit3= f"{smiles}"
                    hit4= f"{mz}"
                    hit5= f"{npc_superclass}"
                    hit6= f"{cf_superclass}"
                    hit7= f"{cf_class}"
                    if hit2 not in hits2:
                        hits1.append(hit1)
                        hits2.append(hit2)
                        hits3.append(hit3)
                        hits4.append(hit4)
                        hits5.append(hit5)
                        hits6.append(hit6)
                        hits7.append(hit7)
        Matrix["ms2query_score"][i] = " ## ".join(hits1)
        Matrix["ms2query_compound_name"][i] = " ## ".join(hits2)
        Matrix["ms2query_compound_smiles"][i] = " ## ".join(hits3)
        Matrix["ms2query_compound_mz"][i] = " ## ".join(hits4)
        Matrix["ms2query_npc_superclass"][i] = " ## ".join(hits5)
        Matrix["ms2query_cf_superclass"][i] = " ## ".join(hits6)
        Matrix["ms2query_cf_class"][i] = " ## ".join(hits7)

    Matrix.to_csv(annotated, sep="\t", index= None)
    return annotated

if __name__ == "__main__":
    ms2query_annotations(sys.argv[1], sys.argv[2], sys.argv[3])