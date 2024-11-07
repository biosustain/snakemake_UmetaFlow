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
        join("..", "envs", "file-conversion.yaml")
    shell:
        """
        thermorawfileparser --input {input} --output {output} 2>> {log} 
        """