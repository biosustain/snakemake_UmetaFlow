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
    log: join("workflow", "report", "logs", "preprocessing", "precursorcorrection_peak_{dataset}.log")
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
        join("results", "Interim", "Preprocessed", "FFM_{dataset}.featureXML")
    log: join("workflow", "report", "logs", "preprocessing", "preprocess_{dataset}.log")
    conda:
        join("..", "envs", "openms.yaml")
    params:
        noise_thr= config["preprocess"]["noise_thr"],
        mass_error= config["preprocess"]["mass_error"],
        fwhm= config["preprocess"]["fwhm"],
        min_trace= config["preprocess"]["min_trace"],
    threads: config["system"]["threads"]
    shell:
        """
        FeatureFinderMetabo -in {input} -out {output} -algorithm:common:noise_threshold_int {params.noise_thr} -algorithm:mtd:mass_error_ppm {params.mass_error} -algorithm:common:chrom_fwhm {params.fwhm} -algorithm:mtd:min_trace_length {params.min_trace} -algorithm:ffm:isotope_filtering_model "none" -algorithm:ffm:remove_single_traces "true" -algorithm:ffm:report_convex_hulls "true" -no_progress -threads {threads} -log {log} 2>> {log}
        """

# 3) Remove all features in blanks/control/QC samples:
blanks= pd.read_csv(join("config", "blanks.tsv"), sep="\t")
blanks= blanks.dropna()
if len(blanks)==0:
    print("no blanks, controls or QCs given")
    rule filter:
        input:
            join("results", "Interim", "Preprocessed", "FFM_{sample}.featureXML")
        output:
            join("results", "Interim", "Preprocessed", "Filtered_{sample}.featureXML")
        log: join("workflow", "report", "logs", "preprocessing", "filtered_{sample}.log")
        conda:
            join("..", "envs", "pyopenms.yaml")
        threads: config["system"]["threads"]
        shell:
            """
            cp {input} {output} 2>> {log}
            """
else:
    rule filter:
        input:
            feature_files= expand(join("results", "Interim", "Preprocessed", "FFM_{sample}.featureXML"), sample=SUBSAMPLES)
        output:
            out_filtered= expand(join("results", "Interim", "Preprocessed", "Filtered_{sample}.featureXML"), sample=SUBSAMPLES)
        log: join("workflow", "report", "logs", "preprocessing", "filtered.log")
        conda:
            join("..", "envs", "pyopenms.yaml")
        threads: config["system"]["threads"]
        shell:
            """
            python workflow/scripts/blank_filter.py {input.feature_files} {output.out_filtered} > /dev/null 2>> {log}
            """

# 4) Correct the MS2 precursor in a feature level (for GNPS FBMN).        

rule precursorcorrection_feature:
    input:
        var1= join("results", "Interim", "mzML", "PCpeak_{sample}.mzML"),
        var2= join("results", "Interim", "Preprocessed", "Filtered_{sample}.featureXML")
    output:
        join("results", "Interim", "mzML", "PCfeature_{sample}.mzML")
    log: join("workflow", "report", "logs", "preprocessing", "precursorcorrection_feature_{sample}.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        HighResPrecursorMassCorrector -in {input.var1} -feature:in {input.var2} -out {output}  -nearest_peak:mz_tolerance "100.0" -no_progress -log {log} 2>> {log} 
        """ 

# 5) (i) MapAlignerPoseClustering is used to perform a linear retention time alignment, to correct for linear shifts in retention time between different runs.

rule MapAligner:
    input:
        expand(join("results", "Interim", "Preprocessed", "Filtered_{sample}.featureXML"), sample=SUBSAMPLES)
    output:
        var1= expand(join("results", "Interim", "Preprocessed", "MapAligned_{sample}.featureXML"), sample=SUBSAMPLES),
        var2= expand(join("results", "Interim", "Preprocessed", "MapAligned_{sample}.trafoXML"), sample=SUBSAMPLES)
    log: 
        general= join("workflow", "report", "logs", "preprocessing", "MapAlignerGeneral.log"),
        job= join("workflow", "report", "logs", "preprocessing", "MapAligner.log")
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
        var2= join("results", "Interim", "Preprocessed", "MapAligned_{sample}.trafoXML")
    output:
        join("results", "Interim", "mzML", "Aligned_{sample}.mzML")
    log: join("workflow", "report", "logs", "preprocessing", "mzMLaligner_{sample}.log")
    conda:
        join("..", "envs", "openms.yaml")    
    threads: config["system"]["threads"]
    shell:
        """
        MapRTTransformer -in {input.var1} -trafo_in {input.var2} -out {output} -threads {threads} -no_progress -log {log} 2>> {log} 
        """ 

# 6) Decharger: Decharging algorithm for adduct assignment

if config["adducts"]["ion_mode"]=="positive":
    rule adduct_annotations_FFM:
        input:
            join("results", "Interim", "Preprocessed", "MapAligned_{sample}.featureXML")
        output:
            join("results", "Interim", "Preprocessed", "MFD_{sample}.featureXML")
        log: join("workflow", "report", "logs", "preprocessing", "adduct_annotations_FFM_{sample}.log")
        conda:
            join("..", "envs", "openms.yaml")
        params:
            adducts_pos= config["adducts"]["adducts_pos"]
        shell:
            """
            MetaboliteAdductDecharger -in {input} -out_fm {output} -algorithm:MetaboliteFeatureDeconvolution:potential_adducts {params.adducts_pos} -algorithm:MetaboliteFeatureDeconvolution:charge_max "1" -algorithm:MetaboliteFeatureDeconvolution:charge_span_max "1"  -algorithm:MetaboliteFeatureDeconvolution:max_neutrals "1" -algorithm:MetaboliteFeatureDeconvolution:retention_max_diff "3.0" -algorithm:MetaboliteFeatureDeconvolution:retention_max_diff_local "3.0" -no_progress -log {log} 2>> {log} 
            """    
else:
    rule adduct_annotations_FFM:
        input:
            join("results", "Interim", "Preprocessed", "MapAligned_{sample}.featureXML")
        output:
            join("results", "Interim", "Preprocessed", "MFD_{sample}.featureXML")
        log: join("workflow", "report", "logs", "preprocessing", "adduct_annotations_FFM_{sample}.log")
        conda:
            join("..", "envs", "openms.yaml")
        params:
            adducts_neg= config["adducts"]["adducts_neg"]
        shell:
            """
            MetaboliteAdductDecharger -in {input} -out_fm {output} -algorithm:MetaboliteFeatureDeconvolution:negative_mode -algorithm:MetaboliteFeatureDeconvolution:potential_adducts {params.adducts_neg} -algorithm:MetaboliteFeatureDeconvolution:charge_max "0" -algorithm:MetaboliteFeatureDeconvolution:charge_min "-2" -algorithm:MetaboliteFeatureDeconvolution:charge_span_max "3" -algorithm:MetaboliteFeatureDeconvolution:max_neutrals "1" -algorithm:MetaboliteFeatureDeconvolution:retention_max_diff "3.0" -algorithm:MetaboliteFeatureDeconvolution:retention_max_diff_local "3.0" -no_progress -log {log} 2>> {log}              
            """   

# 7) Introduce the features to a protein identification file (idXML)- the only way to annotate MS2 spectra for GNPS FBMN  

rule IDMapper_FFM:
    input:
        var1= join("resources", "emptyfile.idXML"),
        var2= join("results", "Interim", "Preprocessed", "MFD_{sample}.featureXML"),
        var3= join("results", "Interim", "mzML", "Aligned_{sample}.mzML")
    output:
        join("results", "Interim", "Preprocessed", "IDMapper_{sample}.featureXML")
    log: join("workflow", "report", "logs", "preprocessing", "IDMapper_FFM_{sample}.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        IDMapper -id {input.var1} -in {input.var2} -spectra:in {input.var3} -out {output} -no_progress -log {log} 2>> {log} 
        """

# 8) The FeatureLinkerUnlabeledKD is used to aggregate the feature information (from single files) into a ConsensusFeature, linking features from different files together, which have a similar m/z and rt (MS1 level).

rule FeatureLinker_FFM:
    input:
        expand(join("results", "Interim", "Preprocessed", "IDMapper_{sample}.featureXML"), sample=SUBSAMPLES)
    output:
        join("results", "Interim", "Preprocessed", "Preprocessed_unfiltered.consensusXML")
    log: join("workflow", "report", "logs", "preprocessing", "FeatureLinker_FFM.log")
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
        join("results", "Interim", "Preprocessed", "Preprocessed_unfiltered.consensusXML")
    output:
        join("results", "Interim", "Preprocessed", "Preprocessed.consensusXML")
    log: join("workflow", "report", "logs", "preprocessing", "MissingValuesFilter.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    threads: config["system"]["threads"]
    shell:
        """
        python workflow/scripts/missing_values_filter.py {input} {output} 0.0 > /dev/null 2>> {log}
        """

# 10) export the consensusXML file to a tsv file to produce a single matrix for PCA

rule FFM_matrix:
    input:
        join("results", "Interim", "Preprocessed", "Preprocessed.consensusXML")
    output:
        join("results", "Preprocessed", "FeatureMatrix.tsv")
    log: join("workflow", "report", "logs", "preprocessing", "FFM_matrix.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:
        """
        python workflow/scripts/cleanup.py {input} {output} > /dev/null 2>> {log}
        """
