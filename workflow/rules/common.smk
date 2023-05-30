import os
import fnmatch
import pandas as pd
from snakemake.utils import validate
from snakemake.utils import min_version
import glob
from pathlib import Path
import peppy
from getpass import getpass

min_version("5.18.0")
pepfile: os.path.join("config", "config.yaml")

##### load config and sample sheets #####
configfile: os.path.join("config", "config.yaml")
validate(config, schema=os.path.join("..", "schemas", "config.schema.yaml"))

# add your sirius email and password in your env for security purposes:
if config["rules"]["sirius_csi"] or config["rules"]["sirius"]:
        if os.environ.get("SIRIUS_EMAIL") is None:
                os.environ["SIRIUS_EMAIL"]=input("Please enter your SIRIUS email: ")
        if os.environ.get("SIRIUS_PASSWORD") is None:
                os.environ["SIRIUS_PASSWORD"]= getpass("Please enter your SIRIUS password: ")
else:
        os.environ["SIRIUS_EMAIL"]=""
        os.environ["SIRIUS_PASSWORD"]=""
        
# set up dataset
dataset = peppy.Project(os.path.join("config", "dataset.tsv"), sample_table_index="sample_name")

# set up samples and blanks or control or QC for filtering
blanks = pd.read_csv(os.path.join("config", "blanks.tsv"), sep="\t", index_col=None)

blanks= blanks.dropna()
if len(blanks)==0:
        samples = peppy.Project(os.path.join("config", "dataset.tsv"), subsample_table_index="sample_name")
else:
        samples = peppy.Project(os.path.join("config", "samples.tsv"), subsample_table_index="sample_name")

DATASET = dataset.sample_table["sample_name"].to_list()
SUBSAMPLES= samples.sample_table["sample_name"].to_list()

##### Helper functions #####

def find_files(base, pattern):
    '''Return list of files matching pattern in base folder.'''
    return [n for n in fnmatch.filter(os.listdir(base), pattern) if
        os.path.isfile(os.path.join(base, n))]

def find_exec(dir, program):
        for path in Path(dir).rglob(program):
                if os.path.isfile(path):
                        return os.path.join(path)
                        
##### 7. Customize final output based on config["rule"] values #####
def get_final_output():
    """
    Generate final output for rule all given a TRUE value in config["rules"]
    """
    # dictionary of rules and its output files
    rule_dict = {"fileconversion" : expand(os.path.join("data", "mzML", "{dataset}.mzML"), dataset=DATASET),
                "preprocessing" : [expand(os.path.join("results", "Interim", "mzML", "PCpeak_{dataset}.mzML"), dataset=DATASET),
        expand(os.path.join("results", "Interim", "Preprocessed", "FFM_{dataset}.featureXML"), dataset=DATASET),
        expand(os.path.join("results", "Interim", "Preprocessed", "Filtered_{sample}.featureXML"), sample=SUBSAMPLES),
        expand(os.path.join("results", "Interim", "mzML", "PCfeature_{sample}.mzML"), sample=SUBSAMPLES),
        expand([os.path.join("results", "Interim", "Preprocessed", "MapAligned_{sample}.featureXML"), os.path.join("results", "Interim", "Preprocessed", "MapAligned_{sample}.trafoXML")], sample=SUBSAMPLES),
        expand(os.path.join("results", "Interim", "mzML", "Aligned_{sample}.mzML"), sample=SUBSAMPLES),
        expand(os.path.join("results", "Interim", "Preprocessed", "MFD_{sample}.featureXML"), sample=SUBSAMPLES),
        expand(os.path.join("results", "Interim", "Preprocessed", "Preprocessed_unfiltered.consensusXML")),
        expand(os.path.join("results", "Interim", "Preprocessed", "Preprocessed.consensusXML")),
        expand(os.path.join("results", "Preprocessed", "FeatureMatrix.tsv"))],
                "requantification" : [expand([os.path.join("results", "Interim", "Requantified", "Complete.consensusXML"), os.path.join("results", "Interim", "Requantified", "Missing.consensusXML")]),
        expand(os.path.join("results", "Interim", "Requantified", "Complete_{sample}.featureXML"), sample=SUBSAMPLES),
        expand(os.path.join("results", "Interim", "Requantified", "MetaboliteNaN.tsv")),
        expand(os.path.join("results", "Interim", "Requantified", "FFMID_{sample}.featureXML"), sample=SUBSAMPLES),
        expand(os.path.join("results", "Interim", "Requantified", "Merged_{sample}.featureXML"), sample=SUBSAMPLES),
        expand(os.path.join("results", "Interim", "Requantified", "MFD_{sample}.featureXML"), sample=SUBSAMPLES),
        expand(os.path.join("results", "Interim", "Requantified", "IDMapper_{sample}.featureXML"), sample=SUBSAMPLES),
        expand(os.path.join("results", "Interim", "Requantified", "Requantified_unfiltered.consensusXML")),
        expand(os.path.join("results", "Interim", "Requantified", "Requantified.consensusXML")),
        expand(os.path.join("results", "Requantified", "FeatureMatrix.tsv"))],
                "GNPSexport" : [expand(os.path.join("results", "Interim", "GNPSexport", "filtered.consensusXML")),
        expand(os.path.join("results", "GNPSexport", "MSMS.mgf")),
        expand(os.path.join("results", "GNPSexport", "FeatureQuantificationTable.txt")),
        expand(os.path.join("results", "GNPSexport", "SuppPairs.csv")),
        expand(os.path.join("results", "GNPSexport", "metadata.tsv"))],
                "sirius_csi" : [expand([os.path.join("results", "Interim", "SiriusCSI", "formulas_{sample}.mzTab"), os.path.join("results", "Interim", "SiriusCSI", "structures_{sample}.mzTab")], sample=SUBSAMPLES),
        expand([os.path.join("results", "SiriusCSI", "formulas_{sample}.tsv"), os.path.join("results", "SiriusCSI", "structures_{sample}.tsv")], sample=SUBSAMPLES),
        expand(os.path.join("results", "annotations", "FeatureTable_siriuscsi.tsv"))],
                "sirius" : [expand(os.path.join("results", "Interim", "Sirius", "formulas_{sample}.mzTab"), sample=SUBSAMPLES),
        expand(os.path.join("results", "Sirius", "formulas_{sample}.tsv"), sample=SUBSAMPLES),
        expand(os.path.join("results", "annotations", "FeatureTable_sirius.tsv"))],
                "spectralmatcher" : [expand(os.path.join("results", "Interim", "annotations", "MSMS.mzML")),
        expand(os.path.join("results", "Interim", "annotations", "MSMSMatcher.mzTab")),
        expand(os.path.join("results", "annotations", "FeatureTable_MSMS.tsv"))],
                "analogsearch" : [expand(os.path.join("results", "Interim", "annotations", "ms2query", "lib.txt")),
        expand(os.path.join("results", "GNPSexport", "results")),
        expand(os.path.join("results", "GNPSexport", "results", "MSMS.csv")),        
        expand(os.path.join("results", "annotations", "ms2query_FeatureTable.tsv"))],
                "fbmn_integration": [expand(os.path.join("results", "GNPSexport", "fbmn_network_sirius.graphml")),
        expand(os.path.join("results", "annotations", "FeatureTable_MSMS_GNPS.tsv"))
        ]
                }
    
    # get keys from config
    opt_rules = config["rules"].keys()
    # if values are TRUE add output files to rule all
    final_output = [rule_dict[r] for r in opt_rules if config["rules"][r]]
    return final_output