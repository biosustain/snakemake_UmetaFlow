# Snakemake rules 

The pipeline consists of seven separate rules that are interconnected:

![dag](/images/UmetaFlow.svg) 

### `1) File conversion:`

Conversion of raw files from Thermo to open community-driven format mzML centroid (see documentation [here](https://github.com/compomics/ThermoRawFileParser)).

If you have Agilent or Bruker files, skip this step: write <span style="color: red">FALSE</span> for the rule fileconversion in the [config.yaml](/config/config.yaml) file, <span style="color: red">convert the files independently</span> using proteowizard (see https://proteowizard.sourceforge.io/) and add them to the `data/mzML/` directory.

### `2) Pre-processing:`

Converting raw data to a feature table with a series of OpenMS algorithms (see documentation [here](https://abibuilder.cs.uni-tuebingen.de/archive/openms/Documentation/nightly/html/index.html)). 

If the user defines blank/QC samples under `config/blanks.tsv`, the workflow will filter out the features found in those samples with a **cutoff > 0.3** (average int in blanks divided by average int in samples).

![dag](/images/Preprocessing.svg) 

### `3) Re-quantification:` 

Re-quantify all raw files to avoid missing values resulted by the pre-processing steps for statistical analysis and data exploration. Generate a FeatureMatrix for further statistical analysis. 

![dag](/images/Re-quantification.svg) 

### `4) SIRIUS:`

The pre-processed feature tables are then introduced to SIRIUS, CSI:FingerID and CANOPUS for formula, structural and compound class predictions (see documentation [here](https://boecker-lab.github.io/docs.sirius.github.io/)). 

CSI:FingerID is using external Web servers (from the Boecher lab in Jena) for the structural library seach and all computations for the structural predictions. The disadvantage in this case is that the workflow is dependent on the functionality of their servers, queued jobs, etc. 

CSI:FingerID and CANOPUS are optional. To exclude them set the parameters in the config file accordingly.

The user will be asked to provide a SIRIUS user email and password at the start of the run and the workflow will set it temporarily as an environmental variable. If the user adds it permanently as an environmental variable (independently of the present workflow) , they will not be asked to provide it again.

### `5) GNPS_export:` 

Generate all the files necessary to create a FBMN job at GNPS (see documentation [here](https://ccms-ucsd.github.io/GNPSDocumentation/featurebasedmolecularnetworking-with-openms/)) or an IIMN job at GNPS (see documentation [here](https://ccms-ucsd.github.io/GNPSDocumentation/fbmn-iin/#iimn-networks-with-collapsed-ion-identity-edges). 

![dag](/images/GNPSExport.svg) 

### `6) Spectral matcher:`

Annotate the feature matrix with MS2 spectral matching through the OpenMS algorithm MetaboliteSpectralMatcher and an in-house or publicly available library (MSI level 2 identifications)

### `7) FBMN integration:`

Once the FBMN or IIMN job is completed, the user can download the cytoscape data in a zipped format. The downloaded folder includes MS2 library search matches under the directory “DB_result”. The user can transfer the tab-separated file with all GNPS library annotations under the directory `resources/` of UmetaFlow. This will allow for additional metabolite annotation, through the rule annotate. The FBMN folder also contains a graphml file for visualization. The user can transfer the file under the `results/GNPS/` directory and choose to integrate the SIRIUS and CSI:FingerID predictions to the network to facilitate visual inspection. Both annotations are established through a unique scan number that is generated at the MS2 clustering level.

### `8) MS2Query:`

Models for analog search will be downloaded automatically. Besides the correct ion mode in the config file, no parameters need to be set by the user.