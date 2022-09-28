# Convert files from Thermo
# Convert profile MS1 data from Thermo raw files to centroid (MS1 and MS2) mzml

import glob
from os.path import join

rule mzml_conversion:
    input:
        join("data", "raw", "{samples}.raw")
    output:
        join("data", "mzML", "{samples}.mzML")
    log: join("workflow", "report", "logs", "FileConversion", "mzml_conversion_{samples}.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        FileConverter -in {input} -out {output} >> {log}
        """