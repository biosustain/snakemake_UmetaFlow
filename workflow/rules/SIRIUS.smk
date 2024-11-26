import glob
from os.path import join
import shutil


envvars:
    "SIRIUS_EMAIL",
    "SIRIUS_PASSWORD",


# 1) SIRIUS Export

if config["rules"]["requantification"]:
    rule SiriusExport:
        input:
            mzML = join("results", "Interim", "mzML", "Aligned_{sample}.mzML"),
            featureXML = join("results", "Interim", "Requantification", "MFD_{sample}.featureXML"),
        output:
            join("results", "SIRIUS", "sirius-input", "{sample}.ms"),
        log:
            join("workflow", "report", "logs", "SIRIUS", "SiriusExport_{sample}.log"),
        conda:
            join("..", "envs", "openms.yaml")
        threads: config["system"]["threads"]
        shell:
            """
            SiriusExport -in {input.mzML} -in_featureinfo {input.featureXML} -out {output} -filter_by_num_masstraces 2  -feature_only true -threads {threads} -no_progress -log {log} 2>> {log}
            """
else:
    rule SiriusExport:
        input:
            mzML = join("results", "Interim", "mzML", "Aligned_{sample}.mzML"),
            featureXML = join("results", "Interim", "Preprocessing", "MFD_{sample}.featureXML"),
        output:
            join("results", "SIRIUS", "sirius-input", "{sample}.ms"),
        log:
            join("workflow", "report", "logs", "SIRIUS", "SiriusExport_{sample}.log"),
        params:
            requant = "true" if config["rules"]["requantification"] else "false"
        conda:
            join("..", "envs", "openms.yaml")
        threads: config["system"]["threads"]
        shell:
            """
            SiriusExport -in {input.mzML} -in_featureinfo {input.featureXML} -out {output} -filter_by_num_masstraces 2  -feature_only true -threads {threads} -no_progress -log {log} 2>> {log}
            """

if not config["SIRIUS"]["export_only"]:

    # 2) Run SIRIUS with login

    formula = [
        "formula",
        "--profile",
        config["SIRIUS"]["instrument"],
        "--database",
        config["SIRIUS"]["formula_database"],
        "--ions-considered",
        (
            config["SIRIUS"]["pos_ions_considered"]
            if config["adducts"]["ion_mode"] == "positive"
            else config["SIRIUS"]["neg_ions_considered"]
        ),
        "--elements-considered",
        config["SIRIUS"]["elements_considered"],
        "--elements-enforced",
        config["SIRIUS"]["elements_enforced"],
        "--ppm-max",
        str(config["SIRIUS"]["ppm_max"]),
        "--ppm-max-ms2",
        str(config["SIRIUS"]["ppm_max_ms2"]),
        "--candidates",
        "1",
    ]

    fingerprint = []
    if config["SIRIUS"]["predict_structure_and_class"]:
        fingerprint = [
            "fingerprint",
            "structure",
            "--database",
            config["SIRIUS"]["structure_database"],
            "canopus"
        ]


    rule SIRIUS:
        input:
            join("results", "SIRIUS", "sirius-input", "{sample}.ms"),
        output:
            projects=directory(
                join("results", "Interim", "SIRIUS", "sirius-projects", "{sample}")
            ),
            flag=join(
                "results", "Interim", "SIRIUS", "sirius-projects", "{sample}_done.txt"
            ),
        log:
            join("workflow", "report", "logs", "SIRIUS", "SIRIUS_{sample}.log"),
        conda:
            join("..", "envs", "sirius.yaml")
        params:
            user=os.environ["SIRIUS_EMAIL"],
            password=os.environ["SIRIUS_PASSWORD"],
            max_mz=config["SIRIUS"]["max_mz"],
            formula=" ".join(formula),
            fingerprint=" ".join(fingerprint),
        shell:
            """
            sirius login --user={params.user} --password={params.password} 2>> {log}
            sirius --input {input} --project {output.projects} --no-compression --maxmz {params.max_mz} {params.formula} {params.fingerprint} write-summaries 2>> {log}
            date '+%Y-%m-%d %H:%M:%S' > {output.flag}
            """


    # 3) Add spectral matches (names and smiles) to Feature Matrix.


    rule SIRIUS_annotations:
        input:
            flags=expand(
                join(
                    "results", "Interim", "SIRIUS", "sirius-projects", "{sample}_done.txt"
                ),
                sample=SUBSAMPLES,
            )
        output:
            join("results", "Interim", "SIRIUS", "FeatureMatrix.tsv"),
        log:
            join("workflow", "report", "logs", "SIRIUS", "SIRIUS_annotations.log"),
        threads: config["system"]["threads"]
        conda:
            join("..", "envs", "pyopenms.yaml")
        params:
            combine_annotations=(
                "true" if config["SIRIUS"]["combine_annotations"] else "false"
            ),
            requant = "true" if config["rules"]["requantification"] else "false",
            csi_canopus = "true" if config["SIRIUS"]["predict_structure_and_class"] else "false"
        shell:
            """
            python workflow/scripts/sirius_annotation.py {params.requant} {output} {params.combine_annotations} {params.csi_canopus} > /dev/null 2>> {log}
            """


    # 4) Clean-up Feature Matrix.


    rule SIRIUS_cleanup:
        input:
            join("results", "Interim", "SIRIUS", "FeatureMatrix.tsv"),
        output:
            join("results", "SIRIUS", "FeatureMatrix.tsv"),
        log:
            join("workflow", "report", "logs", "SIRIUS", "cleanup_feature_matrix.log"),
        conda:
            join("..", "envs", "pyopenms.yaml")
        shell:
            """
            python workflow/scripts/cleanup_feature_matrix.py {input} {output} > /dev/null 2>> {log}
            """
