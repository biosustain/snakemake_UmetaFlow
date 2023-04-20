import glob
from os.path import join 
import peppy

# Annotate with spectral-based analogue search using the machine learning tool ms2query (you can download publicly available ones and/or use in-house libraries):
# Credits to Niek de Jonge for building the tool https://github.com/iomega/ms2query - The preprint is out now and can be found on: https://www.biorxiv.org/content/10.1101/2022.07.22.501125v1

rule library_training:
    input:
        library= join("resources", "GNPS-LIBRARY.mgf")
    output:
        directory(join("resources", "ms2query"))
    log: join("workflow", "report", "logs", "annotate", "ms2query_lib.log")
    conda:
        join("..", "envs", "ms2query.yaml")
    shell:
        """
        python workflow/scripts/library_training.py {input.library} {output} 2>> {log} && touch {output}/lib.txt
        """

rule analogsearch:
    input:
        spectra= join("results", "GNPSexport", "MSMS.mgf"),
        library= directory(join("resources", "ms2query"))
    output:
        directory(join("results", "GNPSexport", "results"))
    log: join("workflow", "report", "logs", "annotate", "ms2query_analog.log")
    conda:
        join("..", "envs", "ms2query.yaml")
    shell:
        """
        ms2query --spectra {input.spectra} --library {input.library} --ionmode positive --additional_metadata feature_id {output} 2>> {log} && touch {output}/ms2query.txt
        """

if config["rules"]["spectralmatcher"]==True:
    rule annotate_FeatureMatrix:
        input:
            matrix= join("results", "annotations", "FeatureTable_MSMS.tsv"),
            ms2query_csv= glob.glob(join("results", "GNPSexport", "results", "*.csv"))
        output:
            join("results", "annotations", "ms2query_FeatureTable.tsv")
        log: join("workflow", "report", "logs", "annotate", "ms2query_annotatematrix.log")
        conda:
            join("..", "envs", "ms2query.yaml")
        shell:
            """
            python workflow/scripts/analog_annotation.py {input.matrix} {input.ms2query_csv} {output} 2>> {log}
            """

elif config["rules"]["sirius_csi"]==True:    
    rule annotate_FeatureMatrix:
        input:
            matrix= join("results", "annotations", "FeatureTable_siriuscsi.tsv"),
            ms2query_csv= glob.glob(join("results", "GNPSexport", "results", "*.csv"))
        output:
            join("results", "annotations", "ms2query_FeatureTable.tsv")
        log: join("workflow", "report", "logs", "annotate", "ms2query_annotatematrix.log")
        conda:
            join("..", "envs", "ms2query.yaml")
        shell:
            """
            python workflow/scripts/analog_annotation.py {input.matrix} {input.ms2query_csv} {output} 2>> {log}
            """

elif config["rules"]["sirius"]==True:    
    rule annotate_FeatureMatrix:
        input:
            matrix= join("results", "annotations", "FeatureTable_sirius.tsv"),
            ms2query_csv= glob.glob(join("results", "GNPSexport", "results", "*.csv"))
        output:
            join("results", "annotations", "ms2query_FeatureTable.tsv")
        log: join("workflow", "report", "logs", "annotate", "ms2query_annotatematrix.log")
        conda:
            join("..", "envs", "ms2query.yaml")
        shell:
            """
            python workflow/scripts/analog_annotation.py {input.matrix} {input.ms2query_csv} {output} 2>> {log}
            """

else:    
    rule annotate_FeatureMatrix:
        input:
            matrix= join("results", "Preprocessed", "FeatureMatrix.tsv"),
            ms2query_csv= glob.glob(join("results", "GNPSexport", "results", "*.csv"))
        output:
            join("results", "annotations", "ms2query_FeatureTable.tsv")
        log: join("workflow", "report", "logs", "annotate", "ms2query_annotatematrix.log")
        conda:
            join("..", "envs", "ms2query.yaml")
        shell:
            """
            python workflow/scripts/analog_annotation.py {input.matrix} {input.ms2query_csv} {output} 2>> {log}
            """