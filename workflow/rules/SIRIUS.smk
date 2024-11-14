import glob
from os.path import join

envvars:
    "SIRIUS_EMAIL",
    "SIRIUS_PASSWORD"

# 1) SIRIUS Export

rule SiriusExport:
    input: 
        mzML = join("results", "Interim", "mzML", "Aligned_{sample}.mzML"),
        featureXML = join("results", "Interim", ("Requantified" if config["rules"]["requantification"] else "Preprocessing"), "MFD_{sample}.featureXML") 
    output:
        join("results", "Interim", "SIRIUS", "sirius-input", "{sample}.ms")
    log: join("workflow", "report", "logs", "SIRIUS", "SiriusExport_{sample}.log")
    conda:
        join("..", "envs", "openms.yaml")
    threads: config["system"]["threads"]
    shell:
        """
        SiriusExport -in {input.mzML} -in_featureinfo {input.featureXML} -out {output} -filter_by_num_masstraces 2  -feature_only true -threads {threads} -no_progress -log {log} 2>> {log}
        """

# 2) Run SIRIUS Login

rule SIRIUS_login:
    output: join("results", "Interim", "SIRIUS", "SIRIUS_login.log")
    conda:
        join("..", "envs", "sirius.yaml")
    params:
        USER_ENV=os.environ["SIRIUS_EMAIL"],
        PSWD_ENV=os.environ["SIRIUS_PASSWORD"],
    shell:
        """
        if sirius login --show | grep -q "Not logged in."; then
            echo "Logging into SIRIUS." >> {output}
            sirius login --user={params.USER_ENV} --password={params.PSWD_ENV} 2>> {output}
        else
            echo "Already logged into SIRIUS." >> {output}
        fi
        """

# 3) Run SIRIUS 

formula = [
    "formula",
    "--profile", config["SIRIUS"]["instrument"],
    "--database", config["SIRIUS"]["formula_database"],
    "--ions-considered", config["SIRIUS"]["pos_ions_considered"] if config["adducts"]["ion_mode"] == "positive" else config["SIRIUS"]["neg_ions_considered"],
    "--elements-considered", config["SIRIUS"]["elements_considered"],
    "--elements-enforced", config["SIRIUS"]["elements_enforced"],
    "--ppm-max", str(config["SIRIUS"]["ppm_max"]),
    "--ppm-max-ms2", str(config["SIRIUS"]["ppm_max_ms2"]),
    "--candidates", "1",
]

fingerprint = []
if config["SIRIUS"]["predict_structure"]:
    fingerprint = ["fingerprint", "structure", "--database", config["SIRIUS"]["structure_database"]]

rule SIRIUS:
    input:
        join("results", "Interim", "SIRIUS", "sirius-input", "{sample}.ms")
    output:
        directory(join("results", "Interim", "SIRIUS", "sirius-projects", "{sample}"))
    log: join("workflow", "report", "logs", "SIRIUS", "SIRIUS_{sample}.log")
    conda:
        join("..", "envs", "sirius.yaml")
    params:
        max_mz = config["SIRIUS"]["max_mz"],
        formula = " ".join(formula),
        fingerprint = " ".join(fingerprint),
        canopus = "canopus" if config["SIRIUS"]["predict_compound_class"] else ""
    shell:
        """
        sirius --input {input} --project {output} --no-compression --maxmz {params.max_mz} {params.formula} {params.fingerprint} {params.canopus} write-summaries 2>> {log}
        """

# 4) Add spectral matches (names and smiles) to Feature Matrix.

rule SIRIUS_annotations:
    input:
        matrix = join("results", "Interim",
                    ("Requantified" if config["rules"]["requantification"] else "Preprocessing"),
                    "FeatureMatrix.tsv"),
        sirius_projects = directory(join("results", "Interim", "SIRIUS", "sirius-projects"))
    output:
        join("results", "Interim", "SIRIUS", "FeatureMatrix.tsv")
    log: join("workflow", "report", "logs", "SIRIUS", "SIRIUS_annotations.log")
    threads: config["system"]["threads"]
    conda:
        join("..", "envs", "pyopenms.yaml")
    params:
        combine_annotations = "true" if config["SIRIUS"]["combine_annotations"] else "false"
    shell:
        """
        python workflow/scripts/sirius_annotation.py {input.matrix} {input.sirius_projects} {output} {params.combine_annotations} > /dev/null 2>> {log}
        """

# 5) Clean-up Feature Matrix.

rule SIRIUS_cleanup:
    input:
        join("results", "Interim", "SIRIUS", "FeatureMatrix.tsv")
    output:
        join("results", "SIRIUS", "FeatureMatrix.tsv")
    log: join("workflow", "report", "logs", "SIRIUS", "cleanup_feature_matrix.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:
        """
        python workflow/scripts/cleanup_feature_matrix.py {input} {output} > /dev/null 2>> {log}
        """