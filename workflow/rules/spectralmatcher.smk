import glob
from os.path import join 

# Annotate with metabolite annotations level 2 (MSI level 2) using the OpenMS algorithm MetaboliteSpectralMatcher with an MGF -or MSP- format file library (you can download publicly available ones and/or use in-house libraries):

MGF_library = glob.glob(join("resources", "*.mgf"))
if MGF_library:
    # 1) Convert all MS2 specs which are linked to a feature to mzML file (from GNPSExport MGF file).

    rule converter:
        input:
            join("results", "GNPS", "MSMS.mgf")
        output:
            join("results", "Interim", "SpectralMatching", "MSMS.mzML")
        log: join("workflow", "report", "logs", "SpectralMatching", "converter.log")
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            FileConverter -in {input} -out {output}  -no_progress -log {log} 2>> {log}
            """

    # 2) Run spectral matching with input MGF library and mzML file containing all MS2 specs (reconstructed from GNPSExport MGF file).

    rule spectral_matcher:
        input:
            mzml = join("results", "Interim", "SpectralMatching", "MSMS.mzML"),
            database = MGF_library[0]
        output:
            join("results", "Interim", "SpectralMatching", "MSMSMatches.mzTab")
        log: join("workflow", "report", "logs", "SpectralMatching", "spectral_matcher.log")
        threads: config["system"]["threads"]
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            MetaboliteSpectralMatcher -algorithm:merge_spectra "false" -in {input.mzml} -database {input.database} -out {output} -threads {threads} -no_progress -log {log} 2>> {log}
            """

    # 3) Add spectral matches (names and smiles) to Feature Matrix.

    rule MSMS_annotations:
        input:
            MSMS = join("results", "Interim", "SpectralMatching", "MSMSMatches.mzTab"),
            MGF = join("results", "GNPS", "MSMS.mgf"),
            MZML = join("results", "Interim", "SpectralMatching", "MSMS.mzML"),
            MATRIX= join("results", "Interim",
                        ("Requantified" if config["rules"]["requantification"] else "Preprocessing"),
                        "FeatureMatrix.tsv")
        output:
            MSMS_MATRIX= join("results", "Interim", "SpectralMatching", "FeatureMatrix.tsv")
        log: join("workflow", "report", "logs", "SpectralMatching", "MSMS_annotations.log")
        threads: config["system"]["threads"]
        conda:
            join("..", "envs", "pyopenms.yaml")
        shell:
            """
            python workflow/scripts/spectral_match_annotation.py {input.MSMS} {input.MGF} {input.MZML} {input.MATRIX} {output.MSMS_MATRIX} > /dev/null 2>> {log}
            """

    # 4) Clean-up Feature Matrix.

    rule SpectralMatching_cleanup:
        input:
            join("results", "Interim", "SpectralMatching", "FeatureMatrix.tsv")
        output:
            join("results", "SpectralMatching", "FeatureMatrix.tsv")
        log: join("workflow", "report", "logs", "SpectralMatching", "cleanup_feature_matrix.log")
        conda:
            join("..", "envs", "pyopenms.yaml")
        shell:
            """
            python workflow/scripts/cleanup_feature_matrix.py {input} {output} > /dev/null 2>> {log}
            """