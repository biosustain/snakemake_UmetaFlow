import glob
from os.path import join

# Annotate with spectral-based analogue search using the machine learning tool ms2query (you can download publicly available ones and/or use in-house libraries):
# Credits to Niek de Jonge for building the tool https://github.com/iomega/ms2query - The publication is out now and can be found on: https://www.nature.com/articles/s41467-023-37446-4

# 1) Download models

rule library_download:
    output:
        join("results", "Interim", "MS2Query", "library_files", "success.txt"),
    log: join("workflow", "report", "logs", "MS2Query", "library_download.log")
    conda:
        join("..", "envs", "ms2query.yaml")
    params:
        ion_mode= config["adducts"]["ion_mode"]   
    threads: config["system"]["threads"]
    shell:
        """
        python workflow/scripts/ms2query_library_download.py {params.ion_mode} {output} > /dev/null 2>> {log} 
        """

# 2) Run analog search on GNPSExport MGF file

rule analog_search:
    input:
        spectra = join("results", "GNPS", "MSMS.mgf"),
        download_success_flag = join("results", "Interim", "MS2Query", "library_files", "success.txt")
    output:
        join("results", "Interim", "MS2Query", "MSMS.csv")
    log: join("workflow", "report", "logs", "MS2Query", "ms2query_analog.log")
    conda:
        join("..", "envs", "ms2query.yaml")
    params:
        ion_mode= config["adducts"]["ion_mode"]
    threads: config["system"]["threads"]
    shell:
        """
        python workflow/scripts/ms2query_analog_search.py {input.spectra} {output} {input.download_success_flag} 2>> {log}
        """

# 3) Annotate feature matrix based on consensus feature ID

rule annotate_FeatureMatrix:
    input:
        ms2query_csv = join("results", "Interim", "MS2Query", "MSMS.csv")
    output:
        join("results", "Interim", "MS2Query", "FeatureMatrix.tsv")
    log: join("workflow", "report", "logs", "MS2Query", "ms2query_annotatematrix.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    params:
        requant = "true" if config["rules"]["requantification"] else "false"
    shell:
        """
        python workflow/scripts/ms2query_annotation.py {params.requant} {output} {input.ms2query_csv} > /dev/null 2>> {log}
        """

# 4) Export final cleaned up FeatureMatrix

rule MS2Query_cleanup:
    input:
        join("results", "Interim", "MS2Query", "FeatureMatrix.tsv"),
    output:
        join("results", "MS2Query", "FeatureMatrix.tsv"),
    log:
        join("workflow", "report", "logs", "MS2Query", "cleanup_feature_matrix.log"),
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:
        """
        python workflow/scripts/cleanup_feature_matrix.py {input} {output} > /dev/null 2>> {log}
        """