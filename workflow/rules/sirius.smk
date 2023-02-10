import glob
from os.path import join

# 1) SIRIUS generates formula predictions from scores calculated from 1) MS2 fragmentation scores (ppm error + intensity) and 2) MS1 isotopic pattern scores.        

if config["rules"]["requantification"]==True:
    rule sirius:
        input: 
            var1= join("results", "Interim", "mzML", "Aligned_{samples}.mzML"),
            var2= join("results", "Interim", "Requantified", "MFD_{samples}.featureXML") 
        output:
            join("results", "Interim", "Sirius", "formulas_{samples}.mzTab")
        log: join("workflow", "report", "logs", "sirius", "SiriusAdapter_{samples}.log")
        conda:
            join("..", "envs", "openms.yaml")
        params:
            exec_path = find_exec("resources", "sirius"),
            email= "",
            password= "" 
        threads: 4
        shell:
            """
            SiriusAdapter -sirius_executable {params.exec_path} -sirius_user_email {params.email} -sirius_user_password {params.password} -in {input.var1} -in_featureinfo {input.var2} -out_sirius {output} -preprocessing:filter_by_num_masstraces 2 -preprocessing:feature_only -sirius:profile orbitrap -sirius:db none -sirius:ions_considered "[M+H]+, [M-H2O+H]+, [M+Na]+, [M+NH4]+" -sirius:elements_enforced CHN[15]OS[4]Cl[2]P[2] -sirius:compound_timeout 100 -sirius:tree_timeout 100 -debug 3 -threads {threads} -log {log} 2>> {log}
            """
else:
    rule sirius:
        input: 
            var1= join("results", "Interim", "mzML", "Aligned_{samples}.mzML"),
            var2= join("results", "Interim", "Preprocessed", "MFD_{samples}.featureXML")
        output:
            join("results", "Interim", "Sirius", "formulas_{samples}.mzTab")
        log: join("workflow", "report", "logs", "sirius", "SiriusAdapter_{samples}.log")
        conda:
            join("..", "envs", "openms.yaml")
        params:
            exec_path = find_exec("resources", "sirius"),
            email= "",
            password= "" 
        threads: 4
        shell:
            """
            SiriusAdapter -sirius_executable {params.exec_path} -sirius_user_email {params.email} -sirius_user_password {params.password} -in {input.var1} -in_featureinfo {input.var2} -out_sirius {output} -preprocessing:filter_by_num_masstraces 2 -preprocessing:feature_only -sirius:profile orbitrap -sirius:db none -sirius:ions_considered "[M+H]+, [M-H2O+H]+, [M+Na]+, [M+NH4]+" -sirius:elements_enforced CHN[15]OS[4]Cl[2]P[2] -sirius:compound_timeout 100 -sirius:tree_timeout 100 -debug 3 -threads {threads} -log {log} 2>> {log}
            """

# 2) Convert the mzTab to a tsv file

rule df_sirius:
    input: 
        input_sirius= join("results", "Interim", "Sirius", "formulas_{samples}.mzTab")
    output:
        output_sirius= join("results", "Sirius", "formulas_{samples}.tsv")
    log: join("workflow", "report", "logs", "sirius", "SiriusDF_{samples}.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:    
        """
        python workflow/scripts/df_SIRIUS.py {input.input_sirius} {output.output_sirius} 2>> {log}
        """

# 3) Create a sirius library from all the tables with formula predictions by only taking into acount the rank #1 predictions for simplicity. Mind that there are cases where SIRIUS predicts the correct formula ranked as >1. 

if config["rules"]["requantification"]==True:
    rule sirius_annotations:
        input:
            matrix= join("results", "Requantified", "FeatureMatrix.tsv"),
            sirius= expand(join("results", "Sirius", "formulas_{samples}.tsv"), samples=SUBSAMPLES)
        output:
            annotated= join("results", "annotations", "FeatureTable_sirius.tsv")
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
            matrix= join("results", "Preprocessed", "FeatureMatrix.tsv"),
            sirius= expand(join("results", "Sirius", "formulas_{samples}.tsv"), samples=SUBSAMPLES)
        output:
            annotated= join("results", "annotations", "FeatureTable_sirius.tsv")
        log: join("workflow", "report", "logs", "annotate", "sirius_annotations.log")
        threads: 4
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            python workflow/scripts/SIRIUS_annotations.py {input.matrix} {output.annotated} 2>> {log}
            """