import glob
from os.path import join

envvars:
    "SIRIUS_EMAIL",
    "SIRIUS_PASSWORD"

# 1) SIRIUS generates formula predictions from scores calculated from 1) MS2 fragmentation scores (ppm error + intensity) and 2) MS1 isotopic pattern scores.        

if (config["rules"]["requantification"]==True) and config["adducts"]["ion_mode"]=="positive":
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
            USER_ENV=os.environ["SIRIUS_EMAIL"],
            PSWD_ENV=os.environ["SIRIUS_PASSWORD"],
            instrument= config["sirius"]["instrument"],
            database= config["sirius"]["database"],
            ions= config["sirius"]["pos_ions_considered"],
            threads= config["system"]["threads"]
        shell:
            """
            SiriusAdapter -sirius_executable {params.exec_path} -sirius_user_email USER_ENV -sirius_user_password PSWD_ENV -in {input.var1} -in_featureinfo {input.var2} -out_sirius {output.} -preprocessing:filter_by_num_masstraces 2 -preprocessing:feature_only -sirius:profile {params.instrument} -sirius:db {params.database} -sirius:ions_considered {params.ions} -sirius:elements_enforced CHN[15]OS[4]Cl[2]P[2] -sirius:compound_timeout 100 -debug 3 -threads {threads} -no_progress -log {log} 2>> {log}
            """
elif (config["rules"]["requantification"]==True) and config["adducts"]["ion_mode"]=="negative":
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
            USER_ENV=os.environ["SIRIUS_EMAIL"],
            PSWD_ENV=os.environ["SIRIUS_PASSWORD"],
            instrument= config["sirius"]["instrument"],
            database= config["sirius"]["database"],
            ions= config["sirius"]["neg_ions_considered"],
        threads: config["system"]["threads"]
        shell:
            """
            SiriusAdapter -sirius_executable {params.exec_path} -sirius_user_email USER_ENV -sirius_user_password PSWD_ENV -in {input.var1} -in_featureinfo {input.var2} -out_sirius {output.} -preprocessing:filter_by_num_masstraces 2 -preprocessing:feature_only -sirius:profile {params.instrument} -sirius:db {params.database} -sirius:ions_considered {params.ions} -sirius:elements_enforced CHN[15]OS[4]Cl[2]P[2] -sirius:compound_timeout 100 -debug 3 -threads {threads} -no_progress -log {log} 2>> {log}
            """

elif (config["rules"]["requantification"]==False) and config["adducts"]["ion_mode"]=="positive":            
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
            USER_ENV=os.environ["SIRIUS_EMAIL"],
            PSWD_ENV=os.environ["SIRIUS_PASSWORD"],
            instrument= config["sirius"]["instrument"],
            database= config["sirius"]["database"],
            ions= config["sirius"]["pos_ions_considered"],
        threads: config["system"]["threads"]
        shell:
            """
            SiriusAdapter -sirius_executable {params.exec_path} -sirius_user_email USER_ENV -sirius_user_password PSWD_ENV -in {input.var1} -in_featureinfo {input.var2} -out_sirius {output.} -preprocessing:filter_by_num_masstraces 2 -preprocessing:feature_only -sirius:profile {params.instrument} -sirius:db {params.database} -sirius:ions_considered {params.ions} -sirius:elements_enforced CHN[15]OS[4]Cl[2]P[2] -sirius:compound_timeout 100 -debug 3 -threads {threads} -no_progress -log {log} 2>> {log}
            """

elif (config["rules"]["requantification"]==False) and config["adducts"]["ion_mode"]=="negative":
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
            USER_ENV=os.environ["SIRIUS_EMAIL"],
            PSWD_ENV=os.environ["SIRIUS_PASSWORD"],
            instrument= config["sirius"]["instrument"],
            database= config["sirius"]["database"],
            ions= config["sirius"]["neg_ions_considered"],
        threads: config["system"]["threads"]
        shell:
            """
            SiriusAdapter -sirius_executable {params.exec_path} -sirius_user_email USER_ENV -sirius_user_password PSWD_ENV -in {input.var1} -in_featureinfo {input.var2} -out_sirius {output.} -preprocessing:filter_by_num_masstraces 2 -preprocessing:feature_only -sirius:profile {params.instrument} -sirius:db {params.database} -sirius:ions_considered {params.ions} -sirius:elements_enforced CHN[15]OS[4]Cl[2]P[2] -sirius:compound_timeout 100 -debug 3 -threads {threads} -no_progress -log {log} 2>> {log}
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
        python workflow/scripts/df_SIRIUS.py {input.input_sirius} {output.output_sirius} > /dev/null 2>> {log}
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
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            python workflow/scripts/SIRIUS_annotations.py {input.matrix} '{input.sirius}' {output.annotated} > /dev/null 2>> {log}
            """
else:
    rule sirius_annotations:
        input:
            matrix= join("results", "Preprocessed", "FeatureMatrix.tsv"),
            sirius= expand(join("results", "Sirius", "formulas_{samples}.tsv"), samples=SUBSAMPLES)
        output:
            annotated= join("results", "annotations", "FeatureTable_sirius.tsv")
        log: join("workflow", "report", "logs", "annotate", "sirius_annotations.log")
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            python workflow/scripts/SIRIUS_annotations.py {input.matrix} '{input.sirius}' {output.annotated} > /dev/null 2>> {log}
            """