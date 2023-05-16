# Convert files from Thermo
# Convert profile MS1 data from Thermo raw files to centroid (MS1 and MS2) mzml

import glob
from os.path import join

rule mzml_conversion:
    input:
        join("data", "raw", "{dataset}.raw")
    output:
        join("data", "mzML", "{dataset}.mzML")
    log: join("workflow", "report", "logs", "FileConversion", "mzml_conversion_{dataset}.log")
    conda:
        join("..", "envs", "openms.yaml")
    params:
        exec_path= find_exec(join(".snakemake", "conda"), "ThermoRawFileParser.exe")
    shell:
        """
        FileConverter -ThermoRaw_executable {params.exec_path} -in {input} -out {output} -no_progress -log {log} 2>> {log} 
        """