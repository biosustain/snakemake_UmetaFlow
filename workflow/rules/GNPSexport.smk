import glob
from os.path import join 

# 1) Filter out the features that do not have an MS2 pattern (no protein ID annotations)

if config["rules"]["requantification"]==True:
    rule FileFilter:
        input:
            join("results", "Interim", "Requantified", "Requantified.consensusXML")
        output:
            join("results", "Interim", "GNPSexport", "filtered.consensusXML")
        log: join("workflow", "report", "logs", "GNPSexport", "FileFilter.log")
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            FileFilter -id:remove_unannotated_features -in {input} -out {output} -log {log} 2>> {log}
            """
else:            
    rule FileFilter:
        input:
            join("results", "Interim", "Preprocessed", "Preprocessed.consensusXML")
        output:
            join("results", "Interim", "GNPSexport", "filtered.consensusXML")
        log: join("workflow", "report", "logs", "GNPSexport", "FileFilter.log")
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            FileFilter -id:remove_unannotated_features -in {input} -out {output} -log {log} 2>> {log}
            """        

# 2) GNPS_export creates an mgf file with only the MS2 information of all files (introduce mzml files with spaces between them)

rule GNPS_export:
    input:
        var1= join("results", "Interim", "GNPSexport", "filtered.consensusXML"),
        var2= expand(join("results", "Interim", "mzML", "Aligned_{samples}.mzML"), samples=SAMPLES)
    output:
        out1= join("results", "GNPSexport", "MSMS.mgf"),
        out2= join("results", "GNPSexport", "FeatureQuantificationTable.txt"), 
        out3= join("results", "GNPSexport", "SuppPairs.csv"),
        out4= join("results", "GNPSexport", "metadata.tsv")
    log: join("workflow", "report", "logs", "GNPSexport", "GNPS_export.log")
    threads: 4
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        GNPSExport -in_cm {input.var1} -in_mzml {input.var2} -out {output.out1} -out_quantification {output.out2} -out_pairs {output.out3} -out_meta_values {output.out4} -threads {threads} -log {log} 2>> {log}
        """