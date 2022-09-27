import os
import fnmatch
import pandas as pd
from snakemake.utils import validate
from snakemake.utils import min_version
import glob

min_version("5.18.0")

##### load config and sample sheets #####

configfile: os.path.join("config", "config.yaml")
validate(config, schema=os.path.join("..", "schemas", "config.schema.yaml"))

# set up sample
samples = pd.read_csv(config["samples"], sep="\t").set_index("sample_name", drop=False)
samples.index.names = ["samples"]


##### Wildcard constraints #####
wildcard_constraints:
    sample="|".join(samples.index),

##### Helper functions #####

def find_files(base, pattern):
    '''Return list of files matching pattern in base folder.'''
    return [n for n in fnmatch.filter(os.listdir(base), pattern) if
        os.path.isfile(os.path.join(base, n))]

def find_exec(dir, program):
        for path in Path(dir).rglob(program):
                if os.path.isfile(path):
                        return path 
                        
SAMPLES = samples.sample_name.to_list()

##### 7. Customize final output based on config["rule"] values #####
def get_final_output():
    """
    Generate final output for rule all given a TRUE value in config["rules"]
    """
    # dictionary of rules and its output files
    rule_dict = {"fileconversion" : expand(os.path.join("data", "mzML", "{samples}.mzML"), samples=SAMPLES),
                "preprocessing" : [expand(os.path.join("results", "Interim", "mzML", "PCpeak_{samples}.mzML"), samples=SAMPLES),
        expand(os.path.join("results", "Interim", "Preprocessed", "FFM_{samples}.featureXML"), samples=SAMPLES),
        expand(os.path.join("results", "Interim", "mzML", "PCfeature_{samples}.mzML"), samples=SAMPLES),
        expand([os.path.join("results", "Interim", "Preprocessed", "MapAligned_{samples}.featureXML"), os.path.join("results", "Interim", "Preprocessed", "MapAligned_{samples}.trafoXML")], samples=SAMPLES),
        expand(os.path.join("results", "Interim", "mzML", "Aligned_{samples}.mzML"), samples=SAMPLES),
        expand(os.path.join("results", "Interim", "Preprocessed", "MFD_{samples}.featureXML"), samples=SAMPLES),
        expand(os.path.join("results", "Interim", "Preprocessed", "Preprocessed.consensusXML")),
        expand(os.path.join("results", "Preprocessed", "FeatureMatrix.tsv"))],
                "requantification" : [expand([os.path.join("results", "Interim", "Requantified", "Complete.consensusXML"), os.path.join("results", "Interim", "Requantified", "Missing.consensusXML")]),
        expand(os.path.join("results", "Interim", "Requantified", "Complete_{samples}.featureXML"), samples=SAMPLES),
        expand(os.path.join("results", "Interim", "Requantified", "MetaboliteNaN.tsv")),
        expand(os.path.join("results", "Interim", "Requantified", "FFMID_{samples}.featureXML"), samples=SAMPLES),
        expand(os.path.join("results", "Interim", "Requantified", "Merged_{samples}.featureXML"), samples=SAMPLES),
        expand(os.path.join("results", "Interim", "Requantified", "MFD_{samples}.featureXML"), samples=SAMPLES),
        expand(os.path.join("results", "Interim", "Requantified", "IDMapper_{samples}.featureXML"), samples=SAMPLES),
        expand(os.path.join("results", "Interim", "Requantified", "Requantified.consensusXML")),
        expand(os.path.join("results", "Requantified", "FeatureMatrix.tsv"))],
                "GNPSexport" : [expand(os.path.join("results", "Interim", "GNPSexport", "filtered.consensusXML")),
        expand(os.path.join("results", "GNPSexport", "MSMS.mgf")),
        expand(os.path.join("results", "GNPSexport", "FeatureQuantificationTable.txt")),
        expand(os.path.join("results", "GNPSexport", "SuppPairs.csv")),
        expand(os.path.join("results", "GNPSexport", "metadata.tsv"))],
                "sirius_csi" : [expand([os.path.join("results", "Interim", "SiriusCSI", "formulas_{samples}.mzTab"), os.path.join("results", "Interim", "SiriusCSI", "structures_{samples}.mzTab")], samples=SAMPLES),
        expand([os.path.join("results", "SiriusCSI", "formulas_{samples}.tsv"), os.path.join("results", "SiriusCSI", "structures_{samples}.tsv")], samples=SAMPLES),
        expand(os.path.join("results", "annotations", "FeatureTable_siriuscsi.tsv"))],
                "sirius" : [expand(os.path.join("results", "Interim", "Sirius", "formulas_{samples}.mzTab"), samples=SAMPLES),
        expand(os.path.join("results", "Sirius", "formulas_{samples}.tsv"), samples=SAMPLES),
        expand(os.path.join("results", "annotations", "FeatureTable_sirius.tsv"))],
                "spectralmatcher" : [expand(os.path.join("results", "Interim", "annotations", "MSMS.mzML")),
        expand(os.path.join("results", "Interim", "annotations", "MSMSMatcher.mzTab")),
        expand(os.path.join("results", "annotations", "FeatureTable_MSMS.tsv"))],
                "fbmn_integration": [expand(os.path.join("results", "GNPSexport", "fbmn_network_sirius.graphml")),
        expand(os.path.join("results", "annotations", "FeatureTable_MSMS_GNPS.tsv"))
        ]
                }
    
    # get keys from config
    opt_rules = config["rules"].keys()

    # if values are TRUE add output files to rule all
    final_output = [rule_dict[r] for r in opt_rules if config["rules"][r]]

    return final_output