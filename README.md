# UmetaFlow: An Untargeted Metabolomics workflow for high-throughput data processing and analysis for Linux and MacOS systems

[![Snakemake](https://img.shields.io/badge/snakemake-≥7.14.0-brightgreen.svg)](https://snakemake.bitbucket.io)
[![PEP compatible](https://pepkit.github.io/img/PEP-compatible-green.svg)](https://pep.databio.org)

This is the Snakemake implementation of the [pyOpenMS workflow](https://github.com/biosustain/pyOpenMS_UmetaFlow.git) tailored by [Eftychia Eva Kontou](https://github.com/eeko-kon) and [Axel Walter](https://github.com/axelwalter).

## Overview

![dag](/images/UmetaFlow_graph.svg)

The pipeline consists of seven interconnected steps:

1) **File conversion**: Simply add your Thermo raw files under the directory `data/raw/` and they will be converted to centroid mzML files. If you have Agilent, Bruker, or other vendor files, skip that step (write "FALSE" for rule file conversion in the config.yaml file - see more under "Configure workflow"), convert them independently using [proteowizard](https://proteowizard.sourceforge.io/) and add them under the `data/mzML/` directory.

2) **Pre-processing**: converting raw data to a feature table with a series of algorithms through feature detection, alignment and grouping. This step includes an optional removal of blank/QC samples if defined by the user. Optional "minfrac" step here allows for removal of consensus features with too many missing values.

3) **Re-quantification (optional)**: Re-quantify all features with missing values across samples resulted from the pre-processing step for more reliable statistical analysis and data exploration. Optional "minfrac" step here allows for removal of consensus features with too many missing values.

4) **Structural, formula and compound class predictions** (SIRIUS, CSI:FingerID and CANOPUS) and annotation of the feature matrix with those predictions (MSI level 3).

5) **GNPS**: generate all the files necessary to create a GNPS [FBMN](https://ccms-ucsd.github.io/GNPSDocumentation/featurebasedmolecularnetworking-with-openms/) or [IIMN](https://ccms-ucsd.github.io/GNPSDocumentation/fbmn-iin/#iimn-networks-with-collapsed-ion-identity-edges) job at GNPS. 

6) **Spectral matching** with in-house or a publicly available library (MGF/MSP/mzML format) and annotation of the feature matrix with matches that have a score above 60 (MSI level 2).

7) **Graph view**: Integrate SIRIUS predictions to the network (GraphML) and GNPS library annotations to the feature matrix - MSI level 2 (optional).

8) **MS2Query**: add another annotation step with a machine learning tool, MS2Query, that searches for exact spectral matches, as well as analogues, using Spec2Vec and MS2Deepscore.

See [README](workflow/rules/README.md) file for details.

## Installation

1. Install [**conda**](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html) or [**mamba**](https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html) following the linked guides (skip if already installed).

2. Create and activate your **snakemake-umetaflow** environment (using conda or mamba).

```
conda create -c conda-forge -c bioconda -n umetaflow-snakemake snakemake python=3.12 -y
conda activate umetaflow-snakemake
```


3. [Clone](https://help.github.com/en/articles/cloning-a-repository) this repository to your local system, into the place where you want to perform the data analysis.

```
git clone https://github.com/biosustain/snakemake_UmetaFlow.git
```

### Installation on MacOS with Silicon Chips

1. **Run the MacOS setup script**

Requires [Homebrew](https://brew.sh/) to be installed. This script will download SIRIUS and ThermoRawFileParser (for file conversion) into the `resources` folder and install `mono` via the `brew` package manager. 

```
python macos_setup.py
```

2. **Install OpenMS manually**

[Download the installer for OpenMS 3.3.0. for MacOS Silicon.](https://abibuilder.cs.uni-tuebingen.de/archive/openms/OpenMSInstaller/release/3.3.0/OpenMS-3.3.0-macOS-Silicon.pkg). To run the installer you need to allow installation from unknown sources in the system settings on the bottom of the *Privacy and Security* tab.

With this specific release you need to update the code signature manually. Open a terminal and move to the location of your OpenMS installation (typically `Users/username/Applications/OpenMS-3.3.0`) and execute the following command:

```
sudo codesign --force -s - ./bin/*
```

Now, add the location of the OpenMS TOPP tools to PATH, to make them accessible globally. Append this line to the end of your shell profile (typically `.zshrc` in your home directory).

```
export PATH="$PATH:/Users/your-user-name/Applications/OpenMS-3.3.0/bin"
```

**⚠️ WARNING FOR DEVELOPERS:** This script will modify workflow code and conda environment files, changes should not be commited. To revert changes simply run the setup script again with the `--revert` flag.

```
python macos_setup.py --revert
```

## Configuration
Configure the workflow according to your metabolomics data and instrument method via editing the files in the `config/` folder. 

### 1. Adjust configuration file

The `config.yaml` file determines the workflow steps: 
- Write <span style="color: green">TRUE</span>/<span style="color: red">FALSE</span> if you want to run/skip a specific rules of the workflow.
- Set parameters according to your dataset as explained in the commented section in the yaml file (e.g. positive/negative ionisation etc.).

### 2. Add MS data files

Add all your files in the `data/raw/` or `data/mzML/` directory and generate the `dataset.tsv` table to specify the samples (filenames) that will be processed. 

Use the Jupyter notebook [Create_dataset_tsv](./Create_dataset_tsv.ipynb) or simply run:


    python data_files.py


`config/dataset.tsv` example:

|  sample_name |       comment                |
|-------------:|-----------------------------:|
| ISP2_blank   | blank media                  |
| NBC_00162    | pyracrimicin                 |
| MDNA_WGS_14  | epemicins_A_B                |

### 3. Define QC and Blank samples (optional)

If there are blanks/QC samples in the file list, add them to the appropriate table.

`config/blanks.tsv` example:

|  sample_name |       comment                |
|-------------:|-----------------------------:|
| ISP2_blank   | blank media                  |

`config/samples.tsv` example:

|  sample_name |       comment                |
|-------------:|-----------------------------:|
| NBC_00162    | pyracrimicin                 |
| MDNA_WGS_14  | epemicins_A_B                |


### 4. Test workflow configuration (optional)

Test your configuration by performing a dry-run via

    snakemake --use-conda --dry-run

See the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/executable.html) for further details.

## Execution

Make sure the `umetaflow-snakemake` conda environment is activated and you are in the `snakemake_UmetaFlow` directory.

    snakemake --use-conda --cores all

## Results

All the results are in a .TSV format and can be opened simply with excel or using Pandas dataframes. All the files under results/interim can be ignored and eventualy discarded.

## Developer Notes

All the workflow outputs are silenced for performance enhancement through the flag `-no_progress` or  `>/dev/null` in each rule or `--quiet` for snakemake command (see Execute the workflow locally via) that one can remove. Nevertheless, the error outputs, if any, are written in the specified log files.

### Config & Schemas

* [Config & schemas](https://snakemake.readthedocs.io/en/stable/snakefiles/configuration.html) define the input formatting and are important to generate `wildcards`. The idea of using `samples` and `units` came from [here](https://github.com/snakemake-workflows/dna-seq-gatk-variant-calling).  

### Rules

* [Snakefile](workflow/Snakefile): the main entry of the pipeline which tells the final output to be generated and the rules being used
* [common.smk](workflow/rules/common.smk): a rule that generates the variables used (sample names) & other helper scripts
* [The main rules (*.smk)](workflow/rules/): the bash code that has been chopped into modular units, with defined input & output. Snakemake then chains this rules together to generate required jobs. This should be intuitive and makes things easier for adding / changing steps in the pipeline.

### Environments

* Conda environments are defined as .yaml file in `workflow/envs`
* Note that not all dependencies are compatible/available as conda libraries. Once installed, the virtual environment are stored in `.snakemake/conda` with unique hashes. The ALE and pilon are example where environment needs to be modified / dependencies need to be installed.
* It might be better to utilise containers / dockers and cloud execution for "hard to install" dependencies
* Custom dependencies and databases are stored in the `resources/` folder.
* Snakemake dependencies with conda packages is one of the drawbacks and why [Nextflow](https://www.nextflow.io/) might be more preferable. Nevertheless, the pythonic language of snakemake enables newcomers to learn and develop their own pipeline faster.

### Test Data (only for testing the workflow with the example dataset)

* Current test data are built from known metabolite producer strains or standard samples that have been analyzed with a Thermo Orbitrap IDX instrument. The presence of the metabolites and their fragmentation patterns has been manually confirmed using TOPPView.

### Citations

Kontou, E.E., Walter, A., Alka, O. et al. UmetaFlow: an untargeted metabolomics workflow for high-throughput data processing and analysis. J Cheminform 15, 52 (2023). https://doi.org/10.1186/s13321-023-00724-w

Pfeuffer J, Sachsenberg T, Alka O, et al. OpenMS – A platform for reproducible analysis of mass spectrometry data. J Biotechnol. 2017;261:142-148. doi:10.1016/j.jbiotec.2017.05.016

Dührkop K, Fleischauer M, Ludwig M, et al. SIRIUS 4: a rapid tool for turning tandem mass spectra into metabolite structure information. Nat Methods. 2019;16(4):299-302. doi:10.1038/s41592-019-0344-8

Dührkop K, Shen H, Meusel M, Rousu J, Böcker S. Searching molecular structure databases with tandem mass spectra using CSI:FingerID. Proc Natl Acad Sci. 2015;112(41):12580-12585. doi:10.1073/pnas.1509788112

Nothias LF, Petras D, Schmid R, et al. Feature-based molecular networking in the GNPS analysis environment. Nat Methods. 2020;17(9):905-908. doi:10.1038/s41592-020-0933-6

Schmid R, Petras D, Nothias LF, et al. Ion identity molecular networking for mass spectrometry-based metabolomics in the GNPS environment. Nat Commun. 2021;12(1):3832. doi:10.1038/s41467-021-23953-9

Mölder F, Jablonski KP, Letcher B, et al. Sustainable data analysis with Snakemake. Published online January 18, 2021. doi:10.12688/f1000research.29032.1

de Jonge, N.F., Louwen, J.J.R., Chekmeneva, E. et al. MS2Query: reliable and scalable MS2 mass spectra-based analogue search. Nat Commun 14, 1752 (2023). doi:10.1038/s41467-023-37446-4
