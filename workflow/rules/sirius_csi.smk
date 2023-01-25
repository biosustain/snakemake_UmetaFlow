import glob
from os.path import join

# 1) SIRIUS generates formula predictions from scores calculated from 1) MS2 fragmentation scores (ppm error + intensity) and 2) MS1 isotopic pattern scores.        
#    The CSI_fingerID function is another algorithm from the Boecher lab, just like SIRIUS adapter and is using the formula predictions from SIRIUS, to search in structural libraries and predict the structure of each formula.
# "CSI:FingerID identifies the structure of a compound by searching in a molecular structure database. “Structure” refers to the identity and connectivity (with bond multiplicities) of the atoms, but no stereochemistry information. Elucidation of stereochemistry is currently beyond the power of automated search engines."

if config["rules"]["requantification"]==True:
    rule sirius_csi:
        input: 
            var1= join("results", "Interim", "mzML", "Aligned_{samples}.mzML"),
            var2= join("results", "Interim", "Requantified", "MFD_{samples}.featureXML") 
        output:
            out1= join("results", "Interim", "SiriusCSI", "formulas_{samples}.mzTab"),
            out2= join("results", "Interim", "SiriusCSI", "structures_{samples}.mzTab")
        conda:
            join("..", "envs", "openms.yaml")
        log: join("workflow", "report", "logs", "sirius_csi", "SiriusAdapter_{samples}.log")
        params:
            exec_path = find_exec("resources", "sirius"),
            email= "",
            password= "" 
        threads: 4
        shell:
            """
            SiriusAdapter -sirius_executable {params.exec_path} -sirius_user_email {params.email} -sirius_user_password {params.password} -in {input.var1} -in_featureinfo {input.var2} -out_sirius {output.out1} -out_fingerid {output.out2} -preprocessing:filter_by_num_masstraces 2 -preprocessing:feature_only -sirius:profile orbitrap -sirius:db none -sirius:ions_considered "[M+H]+, [M-H2O+H]+, [M+Na]+, [M+NH4]+" -sirius:elements_enforced CHN[15]OS[4]Cl[2]P[2] -sirius:compound_timeout 100 -debug 3 -threads {threads} -read_sirius_stdout -log {log} 2>> {log}
            """

else:
    rule sirius_csi:
        input: 
            var1= join("results", "Interim", "mzML", "Aligned_{samples}.mzML"),
            var2= join("results", "Interim", "Preprocessed", "MFD_{samples}.featureXML") 
        output:
            out1= join("results", "Interim", "SiriusCSI", "formulas_{samples}.mzTab"),
            out2= join("results", "Interim", "SiriusCSI", "structures_{samples}.mzTab")
        conda:
            join("..", "envs", "openms.yaml")
        log: join("workflow", "report", "logs", "sirius_csi", "SiriusAdapter_{samples}.log")
        params:
            exec_path = find_exec("resources", "sirius"),
            email= "",
            password= "" 
        threads: 4
        shell:
            """
            SiriusAdapter -sirius_executable {params.exec_path} -sirius_user_email {params.email} -sirius_user_password {params.password} -in {input.var1} -in_featureinfo {input.var2} -out_sirius {output.out1} -out_fingerid {output.out2} -preprocessing:filter_by_num_masstraces 2 -preprocessing:feature_only -sirius:profile orbitrap -sirius:db none -sirius:ions_considered "[M+H]+, [M-H2O+H]+, [M+Na]+, [M+NH4]+" -sirius:elements_enforced CHN[15]OS[4]Cl[2]P[2] -sirius:compound_timeout 100 -debug 3 -threads {threads} -read_sirius_stdout -log {log} 2>> {log}
            """

# 2) Convert the mzTab to a tsv file

rule df_sirius_csi:
    input: 
        input_sirius= join("results", "Interim", "SiriusCSI", "formulas_{samples}.mzTab"),
        input_csi= join("results", "Interim", "SiriusCSI", "structures_{samples}.mzTab")
    output:
        output_sirius= join("results", "SiriusCSI", "formulas_{samples}.tsv"),
        output_csi= join("results", "SiriusCSI", "structures_{samples}.tsv")
    log: join("workflow", "report", "logs", "sirius_csi", "SiriusDF_{samples}.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:    
        """
        python workflow/scripts/df_SIRIUS_CSI.py {input.input_sirius} {input.input_csi} {output.output_sirius} {output.output_csi} 2>> {log}
        """

# 3) Create a sirius library from all the tables with formula predictions by only taking into acount the rank #1 predictions for simplicity. Mind that there are cases where SIRIUS predicts the correct formula ranked as >1. 

if config["rules"]["requantification"]==True:
    rule siriuscsi_annotations:
        input:
            matrix= join("results", "Requantified", "FeatureMatrix.tsv"),
            sirius= expand(join("results", "SiriusCSI", "formulas_{samples}.tsv"), samples=SAMPLES),
            csi= expand(join("results", "SiriusCSI", "structures_{samples}.tsv"), samples=SAMPLES)
        output:
            annotated= join("results", "annotations", "FeatureTable_siriuscsi.tsv")
        log: join("workflow", "report", "logs", "annotate", "sirius_annotations.log")
        threads: 4
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            python workflow/scripts/SIRIUS_CSI_annotations.py {input.matrix} {output.annotated} 2>> {log}
            """
else:
    rule siriuscsi_annotations:
        input:
            matrix= join("results", "Preprocessed", "FeatureMatrix.tsv"),
            sirius= expand(join("results", "SiriusCSI", "formulas_{samples}.tsv"), samples=SAMPLES),
            csi= expand(join("results", "SiriusCSI", "structures_{samples}.tsv"), samples=SAMPLES)
        output:
            annotated= join("results", "annotations", "FeatureTable_siriuscsi.tsv")
        log: join("workflow", "report", "logs", "annotate", "sirius_annotations.log")
        threads: 4
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            python workflow/scripts/SIRIUS_CSI_annotations.py {input.matrix} {output.annotated} 2>> {log}
            """