# Snakemake rules 

The pipeline consists of seven separate rules that are interconnected:

![dag](/images/UmetaFlow.svg) 

### `1) File conversion:`

Conversion of raw files from Thermo to open community-driven format mzML centroid (see documentation [here](https://github.com/compomics/ThermoRawFileParser)).

If you have Agilent or Bruker files, skip this step: write <span style="color: red">FALSE</span> for the rule fileconversion in the [config.yaml](/config/config.yaml) file, <span style="color: red">convert the files independently</span> using proteowizard (see https://proteowizard.sourceforge.io/) and add them to the `data/mzML/` directory.

### `2) Pre-processing:`

Converting raw data to a feature table with a series of OpenMS algorithms (see documentation [here](https://abibuilder.cs.uni-tuebingen.de/archive/openms/Documentation/nightly/html/index.html)). 

If the user defines blank/QC samples under `config/blanks.tsv`, the workflow will filter out the features found in those samples with a **cutoff > 0.3** (average int in blanks devided by average int in samples).

![dag](/images/Preprocessing.svg) 

### `3) Re-quantification:` 

Re-quantify all raw files to avoid missing values resulted by the pre-processing steps for statistical analysis and data exploration. Generate a FeatureMatrix for further statistical analysis. 

![dag](/images/Re-quantification.svg) 

### `4) SIRIUS and CSI:FingerID:`

The pre-processed feature tables are then introduced to SIRIUS and CSI:FingerID for formula and structural predictions (see documentation [here](https://boecker-lab.github.io/docs.sirius.github.io/)). 

CSI:FingerID is using external Web servers (from the Boecher lab in Jena) for the structural library seach and all computations for the structural predictions. The disadvantage in this case is that the workflow is dependent on the functionality of their servers, queued jobs, etc. 

CSI_FingeID is optional and to exclude it, rule [sirius.smk](sirius.smk) can be set as TRUE and the rule [sirius_csi.smk](sirius_csi.smk) as FALSE from the [config.yaml](/config/config.yaml) file.

Level 3 MSI annotations are added to the feature matrix.

### `5) GNPSexport:` 

Generate all the files necessary to create a FBMN job at GNPS (see documentation [here](https://ccms-ucsd.github.io/GNPSDocumentation/featurebasedmolecularnetworking-with-openms/)) or an IIMN job at GNPS (see documentation [here](https://ccms-ucsd.github.io/GNPSDocumentation/fbmn-iin/#iimn-networks-with-collapsed-ion-identity-edges). 


![dag](/images/GNPSExport.svg) 

### `6) Spectral matcher:`

Annotate the feature matrix with MS2 spectral matching through the OpenMS algorithm MetaboliteSpectralMatcher and an in-house or publicly available library (MSI level 2 identifications)

### `7) fbmn_integration:`

Once the FBMN or IIMN job is completed, the user can download the cytoscape data in a zipped format. The downloaded folder includes MS2 library search matches under the directory “DB_result”. The user can transfer the tab-separated file with all GNPS library annotations under the directory `resources/` of UmetaFlow. This will allow for additional metabolite annotation, through the rule annotate. The FBMN folder also contains a graphml file for visualization. The user can transfer the file under the `results/GNPSexport/` directory and choose to integrate the SIRIUS and CSI:FingerID predictions to the network to facilitate visual inspection. Both annotations are established through a unique scan number that is generated at the MS2 clustering level.

### `8) MS2Query:`

To run MS2Query, the user needs to download all model files manually from https://zenodo.org/record/7753249#.ZBmO_sLMJPY for positive mode and https://zenodo.org/record/7753267#.ZBmPYsLMJPY for negative mode and add them under the `resources/ms2query` directory.

Model files for positive mode:
ms2ds_model_GNPS_15_12_2021.hdf5
ms2query_random_forest_model.onnx
spec2vec_model_GNPS_15_12_2021.model
spec2vec_model_GNPS_15_12_2021.model.syn1neg.npy
spec2vec_model_GNPS_15_12_2021.model.wv.vectors.npy
ALL_GNPS_210409_positive_processed_annotated_CF_NPC_classes.txt (classes for MS2DeepScore compound class annotation)

Model files for negative mode:
neg_GNPS_15_12_2021_ms2ds_model.hdf5
neg_GNPS_15_12_2021_ms2query_random_forest_model.onnx
neg_mode_spec2vec_model_GNPS_15_12_2021.model
neg_mode_spec2vec_model_GNPS_15_12_2021.model.syn1neg.npy
neg_mode_spec2vec_model_GNPS_15_12_2021.model.wv.vectors.npy