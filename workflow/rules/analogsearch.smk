import glob
from os.path import join 
import peppy

# Annotate with spectral-based analogue search using the machine learning tool ms2query (you can download publicly available ones and/or use in-house libraries):
# Credits to Niek de Jonge for building the tool https://github.com/iomega/ms2query - The preprint is out now and can be found on: https://www.biorxiv.org/content/10.1101/2022.07.22.501125v1

MGF_library = find_files("resources", "*.mgf")
if MGF_library:
    rule library_training:
        input:
            library= glob.glob(join("resources", "*.mgf")),
            model= glob.glob(join("resources", "ms2query", "*model*")),
            classes= glob.glob(join("resources", "ms2query", "*.txt"))
        output:
            txt= join("results", "Interim", "annotations", "ms2query", "lib.txt"),
            dir= directory(join("results", "Interim", "annotations", "ms2query"))
        log: join("workflow", "report", "logs", "annotate", "ms2query_lib.log")
        conda:
            join("..", "envs", "ms2query.yaml")
        params:
            ion_mode= config["adducts"]["ion_mode"]   
        threads: config["system"]["threads"]
        shell:
            """
            touch {output.txt} && 
            cp {input.model} {output.dir} && 
            cp {input.classes} {output.dir} && 
            python workflow/scripts/library_training.py {input.library} {output.dir} {params.ion_mode} > /dev/null 2>> {log} 
            """

    rule analogsearch:
        input:
            spectra= join("results", "GNPSexport", "MSMS.mgf"),
            library= directory(join("results", "Interim", "annotations", "ms2query"))
        output:
            dir= directory(join("results", "GNPSexport", "results")),
            ms2query_csv= join("results", "GNPSexport", "results", "MSMS.csv")
        log: join("workflow", "report", "logs", "annotate", "ms2query_analog.log")
        conda:
            join("..", "envs", "ms2query.yaml")
        params:
            ion_mode= config["adducts"]["ion_mode"]
        threads: config["system"]["threads"]
        shell:
            """
            ms2query --spectra {input.spectra} --library {input.library} --ionmode {params.ion_mode} --additional_metadata feature_id {output.dir} 2>> {log}
            """

    if config["rules"]["spectralmatcher"]:
        rule annotate_FeatureMatrix:
            input:
                matrix= join("results", "annotations", "FeatureTable_MSMS.tsv"),
                ms2query_csv= join("results", "GNPSexport", "results", "MSMS.csv")
            output:
                join("results", "annotations", "ms2query_FeatureTable.tsv")
            log: join("workflow", "report", "logs", "annotate", "ms2query_annotatematrix.log")
            conda:
                join("..", "envs", "ms2query.yaml")
            shell:
                """
                python workflow/scripts/analog_annotation.py {input.matrix} {input.ms2query_csv} {output} > /dev/null 2>> {log}
                """

    elif config["rules"]["sirius_csi"]:    
        rule annotate_FeatureMatrix:
            input:
                matrix= join("results", "annotations", "FeatureTable_siriuscsi.tsv"),
                ms2query_csv= join("results", "GNPSexport", "results", "MSMS.csv")
            output:
                join("results", "annotations", "ms2query_FeatureTable.tsv")
            log: join("workflow", "report", "logs", "annotate", "ms2query_annotatematrix.log")
            conda:
                join("..", "envs", "ms2query.yaml")
            shell:
                """
                python workflow/scripts/analog_annotation.py {input.matrix} {input.ms2query_csv} {output} > /dev/null 2>> {log}
                """

    elif config["rules"]["sirius"]:    
        rule annotate_FeatureMatrix:
            input:
                matrix= join("results", "annotations", "FeatureTable_sirius.tsv"),
                ms2query_csv= join("results", "GNPSexport", "results", "MSMS.csv")
            output:
                join("results", "annotations", "ms2query_FeatureTable.tsv")
            log: join("workflow", "report", "logs", "annotate", "ms2query_annotatematrix.log")
            conda:
                join("..", "envs", "ms2query.yaml")
            shell:
                """
                python workflow/scripts/analog_annotation.py {input.matrix} {input.ms2query_csv} {output} > /dev/null 2>> {log}
                """

    else:    
        rule annotate_FeatureMatrix:
            input:
                matrix= join("results", "Preprocessed", "FeatureMatrix.tsv"),
                ms2query_csv= join("results", "GNPSexport", "results", "MSMS.csv")
            output:
                join("results", "annotations", "ms2query_FeatureTable.tsv")
            log: join("workflow", "report", "logs", "annotate", "ms2query_annotatematrix.log")
            conda:
                join("..", "envs", "ms2query.yaml")
            shell:
                """
                python workflow/scripts/analog_annotation.py {input.matrix} {input.ms2query_csv} {output} > /dev/null 2>> {log}
                """