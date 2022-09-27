# This rule is for integrating the FBMN results with the SIRIUS annotations and feature table.
# 1) After the FBMN job is done, download the graphml file under the directory workflow/GNPSexport and run the following rule:
#    Credits to Ming Wang for sharing the Jupyter notebook for the integration
import glob
from os.path import join

if config["rules"]["requantification"]==True:
    rule graphml:
        input:
            input_matrix= join("results", "Requantified", "FeatureMatrix.tsv"),
            input_mgf= join("results", "GNPSexport", "MSMS.mgf"),
            input_graphml= glob.glob(join("results", "GNPSexport", "*.graphml"))
        output:    
            output_graphml= join("results", "GNPSexport", "fbmn_network_sirius.graphml")
        log: join("workflow", "report", "logs", "GNPSexport", "fbmn_sirius.log")
        threads: 4
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            python workflow/scripts/FBMN_SIRIUS.py {input.input_matrix} {input.input_mgf} {input.input_graphml} {output.output_graphml} 2>> {log}
            """
else:
    rule graphml:
        input:
            input_matrix= join("results", "Preprocessed", "FeatureMatrix.tsv"),
            input_mgf= join("results", "GNPSexport", "MSMS.mgf"),
            input_graphml= glob.glob(join("results", "GNPSexport", "*.graphml"))
        output:    
            output_graphml= join("results", "GNPSexport", "fbmn_network_sirius.graphml")
        log: join("workflow", "report", "logs", "GNPSexport", "fbmn_sirius.log")
        threads: 4
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            python workflow/scripts/FBMN_SIRIUS.py {input.input_matrix} {input.input_mgf} {input.input_graphml} {output.output_graphml} 2>> {log}
            """

# 2) Optionally, download the cytoscape data and move the .TSV file from the directory "DB_result" under the workflow's directory "resources". This file has all the MSMS library matches that GNPS performs during FBMN. 
# Filter out the ones that have a mass error > 10.0 ppm.
# Annotate compounds in FeatureMatrix through the unique SCAN number (Annotate with metabolite annotations level 2 (MSI level 2))

GNPS_library = find_files("resources", "*.tsv")
if GNPS_library:
    rule GNPS_annotations:
        input:
            lib= glob.glob(join("resources", "*.tsv")),
            featurematrix= join("results", "annotations", "FeatureTable_MSMS.tsv"),
            mgf_path= join("results", "GNPSexport", "MSMS.mgf")
        output:
            gnps= join("results", "annotations", "FeatureTable_MSMS_GNPS.tsv")
        log: join("workflow", "report", "logs", "annotate", "GNPS_annotations.log")
        threads: 4
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            python workflow/scripts/GNPS.py {input.lib} {input.featurematrix} {input.mgf_path} {output.gnps} 2>> {log}
            """
else:
    print("no file found")
    rule GNPS_annotations:
        input:
            join("results", "annotations", "FeatureTable_MSMS.tsv")
        output:
            join("results", "annotations", "FeatureTable_MSMS_GNPS.tsv")
        log: join("workflow", "report", "logs", "annotate", "GNPS_annotations.log")
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """ 
            echo "No GNPS metabolite annotation file was found" > {output} 2>> {log}
            """