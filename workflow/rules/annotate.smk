import glob
from os.path import join 

# 1) Create a sirius library from all the tables with formula predictions by only taking into acount the rank #1 predictions for simplicity. Mind that there are cases where SIRIUS predicts the correct formula ranked as >1. 

if config["rules"]["sirius_csi"]==True:
    if config["rules"]["requantification"]==True:
        rule sirius_annotations:
            input:
                matrix= join("results", "Requantified", "FeatureMatrix.tsv"),
                sirius= expand(join("results", "SiriusCSI", "formulas_{samples}.tsv"), samples=SAMPLES),
                csi= expand(join("results", "SiriusCSI", "structures_{samples}.tsv"), samples=SAMPLES)
            output:
                annotated= join("results", "annotations", "annotated_FeatureTable.tsv")
            log: join("workflow", "report", "logs", "annotate", "sirius_annotations.log")
            threads: 4
            conda:
                join("..", "envs", "openms.yaml")
            shell:
                """
                python workflow/scripts/SIRIUS_CSI_annotations.py {input.matrix} {output.annotated} 2>> {log}
                """
    else:
        rule sirius_annotations:
            input:
                matrix= join("results", "Preprocessed", "FeatureMatrix.tsv"),
                sirius= expand(join("results", "SiriusCSI", "formulas_{samples}.tsv"), samples=SAMPLES),
                csi= expand(join("results", "SiriusCSI", "structures_{samples}.tsv"), samples=SAMPLES)
            output:
                annotated= join("results", "annotations", "annotated_FeatureTable.tsv")
            log: join("workflow", "report", "logs", "annotate", "sirius_annotations.log")
            threads: 4
            conda:
                join("..", "envs", "openms.yaml")
            shell:
                """
                python workflow/scripts/SIRIUS_CSI_annotations.py {input.matrix} {output.annotated} 2>> {log}
                """ 
else:
    if config["rules"]["requantification"]==True:
        rule sirius_annotations:
            input:
                join("results", "Requantified", "FeatureMatrix.tsv"),
                sirius= expand(join("results", "Sirius", "formulas_{samples}.tsv"), samples=SAMPLES)
            output:
                annotated= join("results", "annotations", "annotated_FeatureTable.tsv")
            log: join("workflow", "report", "logs", "annotate", "sirius_annotations.log")
            threads: 4
            conda:
                join("..", "envs", "openms.yaml")
            shell:
                """
                python workflow/scripts/SIRIUS_annotations.py {input.matrix} {output.annotated} 2>> {log}    
                """
    else:
        rule sirius_annotations:
            input:
                join("results", "Preprocessed", "FeatureMatrix.tsv"),
                sirius= expand(join("results", "Sirius", "formulas_{samples}.tsv"), samples=SAMPLES)
            output:
                annotated= join("results", "annotations", "annotated_FeatureTable.tsv")
            log: join("workflow", "report", "logs", "annotate", "sirius_annotations.log")
            threads: 4
            conda:
                join("..", "envs", "openms.yaml")
            shell:
                """
                python workflow/scripts/SIRIUS_annotations.py {input.matrix} {output.annotated} 2>> {log}    
                """

# 2) After FBMN, download the cytoscape data and move the .TSV file from the directory "DB_result" under the workflow's directory "resources". This file has all the MSMS library matches that GNPS performs during FBMN. 
# Filter out the ones that have a mass error > 10.0 ppm.
# Annotate compounds in FeatureMatrix through the unique SCAN number

GNPS_library = find_files("resources", "*.tsv")
if GNPS_library:
    rule GNPS_annotations:
        input:
            lib= glob.glob(join("resources", "*.tsv")),
            featurematrix= join("results", "annotations", "annotated_FeatureTable.tsv"),
            mgf_path= join("results", "GNPSexport", "MSMS.mgf")
        output:
            gnps= join("results", "annotations", "GNPS_annotated_FeatureTable.tsv")
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
            join("results", "annotations", "annotated_FeatureTable.tsv")
        output:
            join("results", "annotations", "GNPS_annotated_FeatureTable.tsv")
        log: join("workflow", "report", "logs", "annotate", "GNPS_annotations.log")
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """ 
            echo "No GNPS metabolite identification file was found" > {output} 2>> {log}
            """