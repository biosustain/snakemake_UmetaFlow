# This rule is for integrating the FBMN results with the SIRIUS annotations and feature table.
# 1) After the FBMN job is done, download the graphml file under the directory workflow/GNPS and run the following rule:
#    Credits to Ming Wang for sharing the Jupyter notebook for the integration
import glob
from os.path import join


rule annotate_graphml_with_sirius:
    input:
        matrix=join("results", "Interim", "SIRIUS", "FeatureMatrix.tsv"),
        mgf=join("results", "GNPS", "MSMS.mgf"),
    output:
        output_graphml=join("results", "GNPS", "fbmn_network_sirius.graphml"),
    log:
        join("workflow", "report", "logs", "GNPS", "fbmn_sirius.log"),
    threads: config["system"]["threads"]
    conda:
        join("..", "envs", "pyopenms.yaml")
    params:
        graphml=(
            join("resources", find_files("resources", "*.graphml")[0])
            if find_files("resources", "*.graphml")
            else "none"
        ),
    shell:
        """
        if [[ {params.graphml} != "none" ]]
        then
            python workflow/scripts/gnps_graphml_sirius_annotation.py {input.matrix} {input.mgf} {params.graphml} {output.output_graphml} > /dev/null 2>> {log}
        else
            echo "No GNPS FBMN graphml file was found" > {output} > /dev/null 2>> {log}
        fi
        """


# 2) Optionally, download the cytoscape data and move the .TSV file from the directory "DB_result" under the workflow's directory "resources". This file has all the MSMS library matches that GNPS performs during FBMN.
# Filter out the ones that have a mass error > 10.0 ppm.
# Annotate compounds in FeatureMatrix through the unique SCAN number (Annotate with metabolite annotations level 2 (MSI level 2))

gnps_result = find_files("resources", "*.tsv")
if gnps_result:
    rule GNPS_annotations:
        input:
            lib = join("resources", gnps_result[0]),
            mgf_path = join("results", "GNPS", "MSMS.mgf"),
        output:
            join("results", "Interim", "GNPS", "FeatureMatrix.tsv"),
        log:
            join("workflow", "report", "logs", "GNPS", "GNPS_annotations.log"),
        threads: config["system"]["threads"]
        params:
            requant = "true" if config["rules"]["requantification"] else "false"
        conda:
            join("..", "envs", "pyopenms.yaml")
        shell:
            """
            python workflow/scripts/gnps_annotation.py {input.lib} {params.requant} {input.mgf_path} {output} > /dev/null 2>> {log}
            """

    rule GNPS_annotation_cleanup:
        input:
            join("results", "Interim", "GNPS", "FeatureMatrix.tsv")
        output:
            join("results", "GNPS", "FeatureMatrix.tsv")
        log: join("workflow", "report", "logs", "SpectralMatching", "cleanup_feature_matrix.log")
        conda:
            join("..", "envs", "pyopenms.yaml")
        shell:
            """
            python workflow/scripts/cleanup_feature_matrix.py {input} {output} > /dev/null 2>> {log}
            """