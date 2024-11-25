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
if config["rules"]["SIRIUS"] and not config["SIRIUS"]["export_only"]:
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
                "preprocessing" : [
                        expand(os.path.join("results", "Interim", "mzML", "PCpeak_{dataset}.mzML"), dataset=DATASET),
                        expand(os.path.join("results", "Interim", "Preprocessing", "FFM_{dataset}.featureXML"), dataset=DATASET),
                        expand(os.path.join("results", "Interim", "Preprocessing", "Filtered_{sample}.featureXML"), sample=SUBSAMPLES),
                        expand(os.path.join("results", "Interim", "mzML", "PCfeature_{sample}.mzML"), sample=SUBSAMPLES),
                        expand([os.path.join("results", "Interim", "Preprocessing", "MapAligned_{sample}.featureXML"), os.path.join("results", "Interim", "Preprocessing", "MapAligned_{sample}.trafoXML")], sample=SUBSAMPLES),
                        expand(os.path.join("results", "Interim", "mzML", "Aligned_{sample}.mzML"), sample=SUBSAMPLES),
                        expand([os.path.join("results", "Interim", "Preprocessing", "MFD_{sample}.featureXML"), os.path.join("results", "Interim", "Preprocessing", "MFD_{sample}.consensusXML")], sample=SUBSAMPLES),
                        expand(os.path.join("results", "Interim", "Preprocessing", "consenus_features_unfiltered.consensusXML")),
                        expand(os.path.join("results", "Interim", "Preprocessing", "consenus_features.consensusXML")),
                        expand(os.path.join("results", "Interim", "Preprocessing", "FeatureMatrix.tsv")),
                        expand(os.path.join("results", "Preprocessing", "FeatureTables", "FeatureMatrix_{sample}.tsv"), sample=SUBSAMPLES),
                        expand(os.path.join("results", "Preprocessing", "FeatureMatrix.tsv"))
                        ],
                "requantification" : [
                        expand([os.path.join("results", "Interim", "Requantification", "Complete.consensusXML"), os.path.join("results", "Interim", "Requantification", "Missing.consensusXML")]),
                        expand(os.path.join("results", "Interim", "Requantification", "Complete_{sample}.featureXML"), sample=SUBSAMPLES),
                        expand(os.path.join("results", "Interim", "Requantification", "MetaboliteNaN.tsv")),
                        expand(os.path.join("results", "Interim", "Requantification", "FFMID_{sample}.featureXML"), sample=SUBSAMPLES),
                        expand(os.path.join("results", "Interim", "Requantification", "Merged_{sample}.featureXML"), sample=SUBSAMPLES),
                        expand(os.path.join("results", "Interim", "Requantification", "MFD_{sample}.featureXML"), sample=SUBSAMPLES),
                        expand(os.path.join("results", "Interim", "Requantification", "IDMapper_{sample}.featureXML"), sample=SUBSAMPLES),
                        expand(os.path.join("results", "Interim", "Requantification", "consenus_features_unfiltered.consensusXML")),
                        expand(os.path.join("results", "Interim", "Requantification", "consenus_features.consensusXML")),
                        expand(os.path.join("results", "Interim", "Requantification", "FeatureMatrix.tsv")),
                        expand(os.path.join("results", "Requantification", "FeatureMatrix.tsv")),
                        ],
                "GNPS_export" : [
                        expand(os.path.join("results", "Interim", "GNPS", "filtered.consensusXML")),
                        expand(os.path.join("results", "GNPS", "MSMS.mgf")),
                        expand(os.path.join("results", "GNPS", "FeatureQuantificationTable.txt")),
                        expand(os.path.join("results", "GNPS", "SuppPairs.csv")),
                        expand(os.path.join("results", "GNPS", "metadata.tsv"))
                        ],
                "SIRIUS" : [
                        expand(os.path.join("results", "SIRIUS", "sirius-input", "{sample}.ms"), sample=SUBSAMPLES),
                        expand(os.path.join("results", "Interim", "SIRIUS", "sirius-projects", "{sample}"), sample=SUBSAMPLES),
                        expand(os.path.join("results", "Interim", "SIRIUS", "FeatureMatrix.tsv")),
                        expand(os.path.join("results", "SIRIUS", "FeatureMatrix.tsv"))
                        ],
                "spectralmatcher" : [
                        expand(os.path.join("results", "Interim", "SpectralMatching", "MSMS.mzML")),
                        expand(os.path.join("results", "Interim", "SpectralMatching", "MSMSMatches.mzTab")),
                        expand(os.path.join("results", "Interim", "SpectralMatching", "FeatureMatrix.tsv")),
                        expand(os.path.join("results", "SpectralMatching", "FeatureMatrix.tsv"))
                        ],
                "MS2Query" : [
                        expand(os.path.join("results", "Interim", "MS2Query", "library_files", "success.txt")),
                        expand(os.path.join("results", "Interim", "MS2Query", "MSMS.csv")),
                        expand(os.path.join("results", "Interim", "MS2Query", "FeatureMatrix.tsv")),
                        expand(os.path.join("results", "MS2Query", "FeatureMatrix.tsv"))
                        ],
                "fbmn_integration": [
                        expand(os.path.join("results", "GNPS", "fbmn_network_sirius.graphml")),
                        expand(os.path.join("results", "Interim", "GNPS", "FeatureMatrix.tsv")),
                        expand(os.path.join("results", "GNPS", "FeatureMatrix.tsv"))
                        ]
                }

    # get keys from config
    opt_rules = config["rules"].keys()
    # if values are TRUE add output files to rule all
    final_output = [rule_dict[r] for r in opt_rules if config["rules"][r]]
    return final_output