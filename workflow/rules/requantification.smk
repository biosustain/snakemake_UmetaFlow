# Re-quantify the features in all data (missing values only)
import glob
from os.path import join 

# 1) Split the consensus map to features with no missing values (complete) and features with missing values (missing) and re-load the complete consensus to individual feature maps

rule split_consensus:
    input:
        in_cmap= join("results", "Interim", "Preprocessed", "consenus_features.consensusXML"),
    output:
        out_complete= join("results", "Interim", "Requantified", "Complete.consensusXML"),
        out_missing= join("results", "Interim", "Requantified", "Missing.consensusXML")
    log: join("workflow", "report", "logs", "requantification", "split_consensus.log")
    threads: config["system"]["threads"]
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:    
        """
        python workflow/scripts/split.py {input.in_cmap} {output.out_complete} {output.out_missing} > /dev/null 2>> {log}
        """

rule reload_maps:
    input:
        in_aligned= join("results", "Interim", "Preprocessed", "MapAligned_{samples}.featureXML"),
        in_complete= join("results", "Interim", "Requantified", "Complete.consensusXML")
    output:
        out_complete= join("results", "Interim", "Requantified", "Complete_{samples}.featureXML")
    log: join("workflow", "report", "logs", "requantification", "reload_maps_{samples}.log")
    threads: config["system"]["threads"]
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:    
        """
        python workflow/scripts/reloadmaps.py {input.in_aligned} {input.in_complete} {output.out_complete} > /dev/null 2>> {log}
        """

# 2) Build a library of features from the consensus with missing values

rule text_export:
    input:
        join("results", "Interim", "Requantified", "Missing.consensusXML")
    output:
        join("results", "Interim", "Requantified", "FeatureQuantificationTable.txt")
    log: join("workflow", "report", "logs", "requantification", "text_export.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        TextExporter -in {input} -out {output} -no_progress -log {log} 2>> {log} 
        """

rule build_library:
    input:
        matrix= join("results", "Interim", "Requantified", "FeatureQuantificationTable.txt")
    output:
        lib= join("results", "Interim", "Requantified", "MetaboliteNaN.tsv")
    log: join("workflow", "report", "logs", "requantification", "build_library.log")
    threads: config["system"]["threads"]
    conda:
        join("..", "envs", "pyopenms.yaml")
    params:
        script = ("workflow/scripts/metaboliteNaN_pos.py"
                if config["adducts"]["ion_mode"] == "positive" else
                "workflow/scripts/metaboliteNaN_neg.py")
    shell:    
        """
        python {params.script} {input.matrix} {output.lib} > /dev/null 2>> {log}  
        """

# 3) Re-quantify all the raw files to cover missing values (missing value imputation can be avoided with that step)

rule requantify:
    input:
        var1= join("results", "Interim", "Requantified", "MetaboliteNaN.tsv"),
        var2= join("results", "Interim", "mzML", "Aligned_{samples}.mzML")
    output:
        join("results", "Interim", "Requantified", "FFMID_{samples}.featureXML")
    log: join("workflow", "report", "logs", "requantification", "requantify_{samples}.log")
    conda:
        join("..", "envs", "openms.yaml")
    params:
        mz_window= config["requantification"]["mz_window"],        
        rt_window= config["requantification"]["RT_window"],
    threads: config["system"]["threads"]
    shell:
        """
        FeatureFinderMetaboIdent -id {input.var1} -in {input.var2} -out {output} -extract:mz_window {params.mz_window} -extract:rt_window {params.rt_window} -threads {threads} -no_progress -log {log} 2>> {log} 
        """

# 4) Merge the re-quantified with the complete feature files

rule merge:
    input:
        in_complete= join("results", "Interim", "Requantified", "Complete_{samples}.featureXML"),
        in_requant= join("results", "Interim", "Requantified", "FFMID_{samples}.featureXML")
    output:
        out_merged= join("results", "Interim", "Requantified", "Merged_{samples}.featureXML")
    log: join("workflow", "report", "logs", "requantification", "merge_{samples}.log")
    threads: config["system"]["threads"]
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:   
        """
        python workflow/scripts/merge.py {input.in_complete} {input.in_requant} {output.out_merged} > /dev/null 2>> {log}
        """


# 5) Decharger: Decharging algorithm for adduct assignment

rule adduct_annotations_FFMident:
    input:
        join("results", "Interim", "Requantified", "Merged_{sample}.featureXML")
    output:
        join("results", "Interim", "Requantified", "MFD_{sample}.featureXML")
    log:
        join("workflow", "report", "logs", "Requantified", "adduct_annotations_FFMident_{sample}.log")
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
        MetaboliteAdductDecharger -in {input} -out_fm {output} {params.ion_mode_flag} -algorithm:MetaboliteFeatureDeconvolution:potential_adducts {params.adducts} {params.charge_params} -algorithm:MetaboliteFeatureDeconvolution:retention_max_diff "3.0" -algorithm:MetaboliteFeatureDeconvolution:retention_max_diff_local "3.0" -no_progress -log {log} 2>> {log}
        """

# 6) Introduce the features to a protein identification file (idXML)- the only way to annotate MS2 spectra for GNPS FBMN  

rule IDMapper_FFMident:
    input:
        var1= join("resources", "emptyfile.idXML"),
        var2= join("results", "Interim", "Requantified", "MFD_{samples}.featureXML"),
        var3= join("results", "Interim", "mzML", "Aligned_{samples}.mzML")
    output:
        join("results", "Interim", "Requantified", "IDMapper_{samples}.featureXML")
    log: join("workflow", "report", "logs", "requantification", "IDMapper_FFMident_{samples}.log")
    conda:
        join("..", "envs", "openms.yaml")
    shell:
        """
        IDMapper -id {input.var1} -in {input.var2} -spectra:in {input.var3} -out {output} -no_progress -log {log} 2>> {log} 
        """

# 7) The FeatureLinkerUnlabeledKD is used to aggregate the feature information (from single files) into a ConsensusFeature, linking features from different sfiles together, which have a smiliar m/z and RT (MS1 level).

rule FeatureLinker_FFMident:
    input:
        expand(join("results", "Interim", "Requantified", "IDMapper_{samples}.featureXML"), samples=SUBSAMPLES)
    output:
        join("results", "Interim", "Requantified", "consenus_features_unfiltered.consensusXML")
    log: join("workflow", "report", "logs", "requantification", "FeatureLinker_FFMident.log")
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

# 8) Filter out consensus features with too many missing values (skipped unless min_frac value changes).

rule missing_values_filter_req:
    input:
        join("results", "Interim", "Requantified", "consenus_features_unfiltered.consensusXML")
    output:
        join("results", "Interim", "Requantified", "consenus_features.consensusXML")
    log: join("workflow", "report", "logs", "requantification", "MissingValuesFilter.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    threads: config["system"]["threads"]
    shell:
        """
        python workflow/scripts/missing_values_filter.py {input} {output} 0.0 > /dev/null 2>> {log}
        """

# 9) Export the consensusXML file to a tsv file to produce a single feature matrix for downstream processing.

rule FFMident_matrix:
    input:
        input_cmap= join("results", "Interim", "Requantified", "consenus_features.consensusXML")
    output:
        output_tsv= join("results", "Interim", "Requantified", "FeatureMatrix.tsv")
    log: join("workflow", "report", "logs", "requantification", "FFMident_matrix.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:
        """
        python workflow/scripts/export_consensus.py {input.input_cmap} {output.output_tsv} > /dev/null 2>> {log}
        """


# 10) Clean-up Feature Matrix.

rule FFMID_cleanup:
    input:
        join("results", "Interim", "Requantified", "FeatureMatrix.tsv")
    output:
        join("results", "Requantified", "FeatureMatrix.tsv")
    log: join("workflow", "report", "logs", "preprocessing", "cleanup_feature_matrix.log")
    conda:
        join("..", "envs", "pyopenms.yaml")
    shell:
        """
        python workflow/scripts/cleanup_feature_matrix.py {input} {output} > /dev/null 2>> {log}
        """