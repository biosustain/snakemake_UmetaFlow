import glob
from os.path import join 
import peppy
import pandas as pd

# 1) Correct the MS2 precursor on a peak level (To the "highest intensity MS1 peak")

rule precursorcorrection_peak:
    input:
        join("data", "mzML", "{dataset}.mzML")
    output:
        join("results", "Interim", "mzML", "PCpeak_{dataset}.mzML")
    log: join("workflow", "report", "logs", "Preprocessing", "precursorcorrection_peak_{dataset}.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        HighResPrecursorMassCorrector -in {input} -out {output} -highest_intensity_peak:mz_tolerance "100.0" -no_progress -log {log} 2>> {log} 
        """

# 2) Preprocessing: Feature finding algorithm that detects peaks 
    
rule preprocess:
    input:
        join("results", "Interim", "mzML", "PCpeak_{dataset}.mzML")
    output:
        join("results", "Interim", "Preprocessing", "FFM_{dataset}.featureXML")
    log: join("workflow", "report", "logs", "Preprocessing", "preprocess_{dataset}.log")
    conda:
        join("..", "envs", "openms.yaml")
    params:
        noise_thr= config["preprocess"]["noise_thr"],
        mass_error= config["preprocess"]["mass_error"],
        fwhm= config["preprocess"]["fwhm"],
        min_trace= config["preprocess"]["min_trace"],
        rm_single_traces= config["preprocess"]["rm_single_traces"]
    threads: config["system"]["threads"]
    shell:
        """
        FeatureFinderMetabo -in {input} -out {output} -algorithm:common:noise_threshold_int {params.noise_thr} -algorithm:mtd:mass_error_ppm {params.mass_error} -algorithm:common:chrom_fwhm {params.fwhm} -algorithm:mtd:min_trace_length {params.min_trace} -algorithm:ffm:isotope_filtering_model "none" -algorithm:ffm:remove_single_traces {params.rm_single_traces} -algorithm:ffm:report_convex_hulls "true" -no_progress -threads {threads} -log {log} 2>> {log}
        """

# 3) Remove all features in blanks/control/QC samples:
blanks = pd.read_csv(join("config", "blanks.tsv"), sep="\t").dropna()
has_blanks = len(blanks) > 0

rule filter:
    input:
        expand(join("results", "Interim", "Preprocessing", "FFM_{sample}.featureXML"), sample=SUBSAMPLES) if has_blanks else join("results", "Interim", "Preprocessing", "FFM_{sample}.featureXML")
    output:
        expand(join("results", "Interim", "Preprocessing", "Filtered_{sample}.featureXML"), sample=SUBSAMPLES) if has_blanks else join("results", "Interim", "Preprocessing", "Filtered_{sample}.featureXML")
    log:
        join("workflow", "report", "logs", "Preprocessing", "filtered.log") if has_blanks else join("workflow", "report", "logs", "preprocessing", "filtered_{sample}.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    threads:
        config["system"]["threads"]
    shell:
        """
        if [ "{has_blanks}" = "True" ]; then
            python workflow/scripts/blank_filter.py {input} {output} > /dev/null 2>> {log}
        else
            cp {input} {output} 2>> {log}
        fi
        """
# 4) Correct the MS2 precursor in a feature level (for GNPS FBMN).        

rule precursorcorrection_feature:
    input:
        var1= join("results", "Interim", "mzML", "PCpeak_{sample}.mzML"),
        var2= join("results", "Interim", "Preprocessing", "Filtered_{sample}.featureXML")
    output:
        join("results", "Interim", "mzML", "PCfeature_{sample}.mzML")
    log: join("workflow", "report", "logs", "Preprocessing", "precursorcorrection_feature_{sample}.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        HighResPrecursorMassCorrector -in {input.var1} -feature:in {input.var2} -out {output}  -nearest_peak:mz_tolerance "100.0" -no_progress -log {log} 2>> {log} 
        """ 

# 5) (i) MapAlignerPoseClustering is used to perform a linear retention time alignment, to correct for linear shifts in retention time between different runs.

rule MapAligner:
    input:
        expand(join("results", "Interim", "Preprocessing", "Filtered_{sample}.featureXML"), sample=SUBSAMPLES)
    output:
        var1= expand(join("results", "Interim", "Preprocessing", "MapAligned_{sample}.featureXML"), sample=SUBSAMPLES),
        var2= expand(join("results", "Interim", "Preprocessing", "MapAligned_{sample}.trafoXML"), sample=SUBSAMPLES)
    log: 
        general= join("workflow", "report", "logs", "Preprocessing", "MapAlignerGeneral.log"),
        job= join("workflow", "report", "logs", "Preprocessing", "MapAligner.log")
    conda:
        join("..", "envs", "openms.yaml")
    params:
        mz_max= config["align"]["mz_max"]   
    threads: config["system"]["threads"]
    shell:
        """
        echo "Preparing maps for alignment..." > {log.general}
        MapAlignerPoseClustering -algorithm:max_num_peaks_considered -1 -algorithm:superimposer:mz_pair_max_distance 0.05 -algorithm:pairfinder:distance_MZ:max_difference {params.mz_max} -algorithm:pairfinder:distance_MZ:unit ppm -in {input} -out {output.var1} -trafo_out {output.var2} -threads {threads} -no_progress -log {log.job} 2>> {log.job}
        """ 

# 5) (ii) MapRTTransformer is used to perform a linear retention time alignment, to correct for linear shifts in retention time between different runs using the transformation files from the reprocessing rule MapAlignerPoseClustering (faster computationally)

rule mzMLaligner:
    input:
        var1= join("results", "Interim", "mzML", "PCfeature_{sample}.mzML"),
        var2= join("results", "Interim", "Preprocessing", "MapAligned_{sample}.trafoXML")
    output:
        join("results", "Interim", "mzML", "Aligned_{sample}.mzML")
    log: join("workflow", "report", "logs", "Preprocessing", "mzMLaligner_{sample}.log")
    conda:
        join("..", "envs", "openms.yaml")    
    threads: config["system"]["threads"]
    shell:
        """
        MapRTTransformer -in {input.var1} -trafo_in {input.var2} -out {output} -threads {threads} -no_progress -log {log} 2>> {log} 
        """ 

# 6) Decharger: Decharging algorithm for adduct assignment

rule adduct_annotations_FFM:
    input:
        join("results", "Interim", "Preprocessing", "MapAligned_{sample}.featureXML")
    output:
        charged = join("results", "Interim", "Preprocessing", "MFD_{sample}.featureXML"),
        neutral = join("results", "Interim", "Preprocessing", "MFD_{sample}.consensusXML")
    log:
        join("workflow", "report", "logs", "Preprocessing", "adduct_annotations_FFM_{sample}.log")
    conda:
        join("..", "envs", "openms.yaml")
    params:
        adducts = config["adducts"]["adducts_pos"] if config["adducts"]["ion_mode"] == "positive" else config["adducts"]["adducts_neg"],
        ion_mode_flag = "" if config["adducts"]["ion_mode"] == "positive" else "-algorithm:MetaboliteFeatureDeconvolution:negative_mode",
        charge_params = ("-algorithm:MetaboliteFeatureDeconvolution:charge_max 1 "
                         "-algorithm:MetaboliteFeatureDeconvolution:charge_span_max 1 "
                         "-algorithm:MetaboliteFeatureDeconvolution:max_neutrals 1") 
                         if config["adducts"]["ion_mode"] == "positive" else 
                         ("-algorithm:MetaboliteFeatureDeconvolution:charge_max 0 "
                          "-algorithm:MetaboliteFeatureDeconvolution:charge_min -2 "
                          "-algorithm:MetaboliteFeatureDeconvolution:charge_span_max 3 "
                          "-algorithm:MetaboliteFeatureDeconvolution:max_neutrals 1")
    shell:
        """
        MetaboliteAdductDecharger -in {input} -out_fm {output.charged} -out_cm {output.neutral} {params.ion_mode_flag} -algorithm:MetaboliteFeatureDeconvolution:potential_adducts {params.adducts} {params.charge_params} -algorithm:MetaboliteFeatureDeconvolution:retention_max_diff "3.0" -algorithm:MetaboliteFeatureDeconvolution:retention_max_diff_local "3.0" -no_progress -log {log} 2>> {log}
        """

# 7) Introduce the features to a protein identification file (idXML)- the only way to annotate MS2 spectra for GNPS FBMN  

rule IDMapper_FFM:
    input:
        var1= join("resources", "emptyfile.idXML"),
        var2= join("results", "Interim", "Preprocessing", "MFD_{sample}.featureXML"),
        var3= join("results", "Interim", "mzML", "Aligned_{sample}.mzML")
    output:
        join("results", "Interim", "Preprocessing", "IDMapper_{sample}.featureXML")
    log: join("workflow", "report", "logs", "Preprocessing", "IDMapper_FFM_{sample}.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        IDMapper -id {input.var1} -in {input.var2} -spectra:in {input.var3} -out {output} -no_progress -log {log} 2>> {log} 
        """

# 8) The FeatureLinkerUnlabeledKD is used to aggregate the feature information (from single files) into a ConsensusFeature, linking features from different files together, which have a similar m/z and rt (MS1 level).

rule FeatureLinker_FFM:
    input:
        expand(join("results", "Interim", "Preprocessing", "IDMapper_{sample}.featureXML"), sample=SUBSAMPLES)
    output:
        join("results", "Interim", "Preprocessing", "consenus_features_unfiltered.consensusXML")
    log: join("workflow", "report", "logs", "Preprocessing", "FeatureLinker_FFM.log")
    conda:
        join("..", "envs", "openms.yaml")
    params:
        mz_tol= config["featurelink"]["mz_tol"],
        rt_tol= config["featurelink"]["rt_tol"],
    threads: config["system"]["threads"]
    shell:
        """
        FeatureLinkerUnlabeledKD -in {input} -out {output} -algorithm:warp:enabled false -algorithm:link:rt_tol {params.rt_tol} -algorithm:link:mz_tol {params.mz_tol} -threads {threads} -no_progress -log {log} 2>> {log} 
        """

# 9) Filter out consensus features with too many missing values (skipped unless min_frac value changes).

rule missing_values_filter:
    input:
        join("results", "Interim", "Preprocessing", "consenus_features_unfiltered.consensusXML")
    output:
        join("results", "Interim", "Preprocessing", "consenus_features.consensusXML")
    log: join("workflow", "report", "logs", "Preprocessing", "MissingValuesFilter.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    threads: config["system"]["threads"]
    shell:
        """
        python workflow/scripts/missing_values_filter.py {input} {output} 0.0 > /dev/null 2>> {log}
        """

# 10) Export the consensusXML file to a tsv file to produce a single feature matrix for downstream processing.

rule FFM_matrix:
    input:
        join("results", "Interim", "Preprocessing", "consenus_features.consensusXML")
    output:
        join("results","Interim", "Preprocessing", "FeatureMatrix.tsv")
    log: join("workflow", "report", "logs", "Preprocessing", "FFM_matrix.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:
        """
        python workflow/scripts/export_consensus.py {input} {output} > /dev/null 2>> {log}
        """

# 11) Clean-up Feature Matrix.

rule FFM_cleanup:
    input:
        join("results", "Interim", "Preprocessing", "FeatureMatrix.tsv")
    output:
        join("results", "Preprocessing", "FeatureMatrix.tsv")
    log: join("workflow", "report", "logs", "Preprocessing", "cleanup_feature_matrix.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:
        """
        python workflow/scripts/cleanup_feature_matrix.py {input} {output} > /dev/null 2>> {log}
        """

# 12) Export the individual featureXML files to tsv files to produce a feature matrixes.

rule FFM_matrixes:
    input:
        join("results", "Interim", "Preprocessing", "IDMapper_{sample}.featureXML")
    output:
        join("results", "Preprocessing",  "FeatureTables", "FeatureMatrix_{sample}.tsv")
    log: join("workflow", "report", "logs", "Preprocessing", "FFM_matrix_{sample}.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:
        """
        python workflow/scripts/export_ft.py {input} {output} > /dev/null 2>> {log}
        """
