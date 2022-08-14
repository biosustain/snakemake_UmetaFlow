# Snakemake rules 

The pipeline consists of seven separate rules that are interconnected:

![dag](/images/UmetaFlow.svg) 

### `1) File conversion:`

Conversion of raw files from Thermo to open community-driven format mzML centroid (see documentation [here](https://github.com/compomics/ThermoRawFileParser)).

If you have Agilent or Bruker files, skip that step (write "FALSE" for rule fileconversion in the [config.yaml](/config/config.yaml) file, convert the files independently using proteowizard (see https://proteowizard.sourceforge.io/) and add them to the data/mzML/ directory.

### `2) Pre-processing:`

Converting raw data to a feature table with a series of OpenMS algorithms (see documentation [here](https://abibuilder.informatik.uni-tuebingen.de/archive/openms/Documentation/nightly/html/index.html)). Important note: the MetaboAdductDecharger is in positive mode. Use adduct list: [H-1:-:1,H-2O-1:0:0.05,CH2O2:0:0.5] for negative mode.

![dag](/images/Preprocessing.svg) 

### `3) Re-quantification:` 

Re-quantify all raw files to avoid missing values resulted by the pre-processing steps for statistical analysis and data exploration. Generate a FeatureMatrix for further statistical analysis. Important note: the MetaboAdductDecharger is in positive mode. Use adduct list: [H-1:-:1,H-2O-1:0:0.05,CH2O2:0:0.5] for negative mode. Also, edit the script workflow/scripts/metaboliteidentification.py: comment the positive ionisation part of the script and uncomment the negative ionisation version. 

![dag](/images/Re-quantification.svg) 

### `4) SIRIUS and CSI:FingerID:`

The pre-processed feature tables are then introduced to SIRIUS and CSI:FingerID for formula and structural predictions (see documentation [here](https://boecker-lab.github.io/docs.sirius.github.io/)).

CSI:FingerID is using external Web servers (from the Boecher lab in Jena) for the structural library seach and all computations for the structural predictions. The disadvantage in this case is that the workflow is dependent on the functionality of their servers, queued jobs, etc. 

CSI_FingeID is optional and to exclude it, rule [sirius.smk](sirius.smk) can be set as TRUE and the rule [sirius_csi.smk](sirius_csi.smk) as FALSE from the [config.yaml](/config/config.yaml) file.

### `5) GNPSexport:` 

Generate all the files necessary to create a FBMN job at GNPS (see documentation [here](https://ccms-ucsd.github.io/GNPSDocumentation/featurebasedmolecularnetworking-with-openms/)) or an IIMN job at GNPS (see documentation [here](https://ccms-ucsd.github.io/GNPSDocumentation/fbmn-iin/#iimn-networks-with-collapsed-ion-identity-edges). 

![dag](/images/GNPSExport.svg) 

### `6) Annotate:`

Annotate the feature matrix with formula and structural predictions, as well as GNPS spectral matches after FBMN. 
When FBMN is done, download the cytoscape files. Under the directory "DB_result", there is a .TSV file with all metabolite identifications through MSMS matching. Tranfer that file under "resources". The result is a Feature Matrix with SIRIUS, CSI and GNPS annotations.

### `7) fbmn_sirius:`

This rule allows for integration of the SIRIUS and CSI predictions to the .GRAPHML file from FBMN. 
After FBMN is done, download the cytoscape files and transfer the graphml network under the directory "results/GNPSexport". 