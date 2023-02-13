import glob
from os.path import join 
import peppy
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
        HighResPrecursorMassCorrector -in {input} -out {output} -highest_intensity_peak:mz_tolerance "100.0" -log {log} 2>> {log}
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
    threads: 4
    shell:
        """
        FeatureFinderMetabo -in {input} -out {output} -algorithm:common:noise_threshold_int "1.0e03" -algorithm:mtd:mass_error_ppm "10.0" -algorithm:epd:width_filtering "fixed" -algorithm:ffm:isotope_filtering_model "none" -algorithm:ffm:remove_single_traces "true" -algorithm:ffm:report_convex_hulls "true" -threads {threads} -log {log} 2>> {log}
        """

# 3) Remove all features in blanks/control/QC samples:
 
rule filter:
    input:
        feature_files= expand(join("results", "Interim", "Preprocessed", "FFM_{sample}.featureXML"), sample=SUBSAMPLES)
    output:
        out_filtered= expand(join("results", "Interim", "Preprocessed", "Filtered_{sample}.featureXML"), sample=SUBSAMPLES)
    log: join("workflow", "report", "logs", "preprocessing", "filtered.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    threads: 4
    shell:
        """
        python workflow/scripts/filter.py {input.feature_files} {output.out_filtered} 2>> {log}
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
        HighResPrecursorMassCorrector -in {input.var1} -feature:in {input.var2} -out {output}  -nearest_peak:mz_tolerance "100.0" -log {log} 2>> {log} 
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
    threads: 4
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        echo "Preparing maps for alignment..." > {log.general}
        MapAlignerPoseClustering -algorithm:max_num_peaks_considered -1 -algorithm:superimposer:mz_pair_max_distance 0.05 -algorithm:pairfinder:distance_MZ:max_difference 10.0 -algorithm:pairfinder:distance_MZ:unit ppm -in {input} -out {output.var1} -trafo_out {output.var2} -threads {threads} -log {log.job} 2>> {log.job}
        """ 

# 5) (ii) MapRTTransformer is used to perform a linear retention time alignment, to correct for linear shifts in retention time between different runs using the transformation files from the reprocessing rule MapAlignerPoseClustering (faster computationally)

rule mzMLaligner:
    input:
        var1= join("results", "Interim", "mzML", "PCfeature_{sample}.mzML"),
        var2= join("results", "Interim", "Preprocessed", "MapAligned_{sample}.trafoXML")
    output:
        join("results", "Interim", "mzML", "Aligned_{sample}.mzML")
    log: join("workflow", "report", "logs", "preprocessing", "mzMLaligner_{sample}.log")
    threads: 4
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        MapRTTransformer -in {input.var1} -trafo_in {input.var2} -out {output} -threads {threads} -log {log} 2>> {log} 
        """ 

# 6) Decharger: Decharging algorithm for adduct assignment

rule adduct_annotations_FFM:
    input:
        join("results", "Interim", "Preprocessed", "MapAligned_{sample}.featureXML")
    output:
        join("results", "Interim", "Preprocessed", "MFD_{sample}.featureXML")
    log: join("workflow", "report", "logs", "preprocessing", "adduct_annotations_FFM_{sample}.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        MetaboliteAdductDecharger -in {input} -out_fm {output} -algorithm:MetaboliteFeatureDeconvolution:potential_adducts "H:+:0.6" "Na:+:0.1" "NH4:+:0.1" "H-1O-1:+:0.1" "H-3O-2:+:0.1" -algorithm:MetaboliteFeatureDeconvolution:charge_max "1" -algorithm:MetaboliteFeatureDeconvolution:charge_span_max "1"  -algorithm:MetaboliteFeatureDeconvolution:max_neutrals "1" -algorithm:MetaboliteFeatureDeconvolution:retention_max_diff "3.0" -algorithm:MetaboliteFeatureDeconvolution:retention_max_diff_local "3.0" -log {log} 2>> {log} 
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
        IDMapper -id {input.var1} -in {input.var2}  -spectra:in {input.var3} -out {output} -log {log} 2>> {log} 
        """

# 8) The FeatureLinkerUnlabeledKD is used to aggregate the feature information (from single files) into a ConsensusFeature, linking features from different files together, which have a similar m", "z and rt (MS1 level).

rule FeatureLinker_FFM:
    input:
        expand(join("results", "Interim", "Preprocessed", "IDMapper_{sample}.featureXML"), sample=SUBSAMPLES)
    output:
        join("results", "Interim", "Preprocessed", "Preprocessed.consensusXML")
    log: join("workflow", "report", "logs", "preprocessing", "FeatureLinker_FFM.log")
    conda:
        join("..", "envs", "openms.yaml")
    threads: 4
    shell:
        """
        FeatureLinkerUnlabeledKD -in {input} -out {output} -algorithm:warp:enabled false -algorithm:link:rt_tol 30.0 -algorithm:link:mz_tol 8.0 -threads {threads} -log {log} 2>> {log} 
        """

# 9) export the consensusXML file to a tsv file to produce a single matrix for PCA

rule FFM_matrix:
    input:
        input_cmap= join("results", "Interim", "Preprocessed", "Preprocessed.consensusXML")
    output:
        output_tsv= join("results", "Preprocessed", "FeatureMatrix.tsv")
    log: join("workflow", "report", "logs", "preprocessing", "FFM_matrix.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:
        """
        python workflow/scripts/cleanup.py {input.input_cmap} {output.output_tsv} 2>> {log}
        """
