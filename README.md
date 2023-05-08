# UmetaFlow: An Untargeted Metabolomics workflow for high-throughput data processing and analysis for Linux and MacOS systems

[![Snakemake](https://img.shields.io/badge/snakemake-≥7.14.0-brightgreen.svg)](https://snakemake.bitbucket.io)
[![PEP compatible](https://pepkit.github.io/img/PEP-compatible-green.svg)](https://pep.databio.org)

This is the Snakemake implementation of the [pyOpenMS workflow](https://github.com/biosustain/pyOpenMS_UmetaFlow.git) tailored by [Eftychia Eva Kontou](https://github.com/eeko-kon) and [Axel Walter](https://github.com/axelwalter).

## Workflow overview

The pipeline consists of seven interconnected steps:

1) File conversion: Simply add your Thermo raw files under the directory data/raw/ and they will be converted to centroid mzML files. If you have Agilent, Bruker, or other vendor files, skip that step (write "FALSE" for rule fileconversion in the config.yaml file - see more under "Configure workflow"), convert them independently using [proteowizard](https://proteowizard.sourceforge.io/) and add them under the data/mzML/ directory.

2) Pre-processing: converting raw data to a feature table with a series of algorithms through feature detection, alignment and grouping. This step includes an optional removal of blank/QC samples if defined by the user. Optional "minfrac" step here allows for removal of consensus features with too many missing values.

3) Re-quantification (optional): Re-quantify all features with missing values across samples resulted from the pre-processing step for more reliable statistical analysis and data exploration. Optional "minfrac" step here allows for removal of consensus features with too many missing values.

4) Structural and formula predictions (SIRIUS and CSI:FingeID) and annotation of the feature matrix with those predictions (MSI level 3).

5) GNPSexport: generate all the files necessary to create a [FBMN](https://ccms-ucsd.github.io/GNPSDocumentation/featurebasedmolecularnetworking-with-openms/) or [IIMN](https://ccms-ucsd.github.io/GNPSDocumentation/fbmn-iin/#iimn-networks-with-collapsed-ion-identity-edges) job at GNPS. 

6) Spectral matching with in-house or a publicly available library (MGF/MSP/mzML format) and annotation of the feature matrix with matches that have a score above 60 (MSI level 2).

7) After FBMN or IIMN: Integrate Sirius and CSI predictions to the network (GraphML) and MSMS spectral library annotations to the feature matrix- MSI level 2 (optional).

8) MS2Query: add another annotation step with a machine learning tool, MS2Query, that searches for exact spectral matches, as well as analogues, using Spec2Vec and MS2Deepscore.

See [README](workflow/rules/README.md) file for details.
### Overview
![dag](/images/UmetaFlow_graph.svg)

## Usage

### Step 1: Clone the workflow

[Clone](https://help.github.com/en/articles/cloning-a-repository) this repository to your local system, into the place where you want to perform the data analysis.

Make sure to have the right access / SSH Key. If **not**, follow the steps:

Step 1: https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

Step 2: https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account

    git clone https://github.com/NBChub/snakemake-UmetaFlow.git

### Step 2: Install all dependencies

#### For both systems

Install homebrew and wget:

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
Press enter (RETURN) to continue

#### For Linux only !

Follow the Next steps instructions to add Linuxbrew to your PATH and to your bash shell profile script, either ~/.profile on Debian/Ubuntu or ~/.bash_profile on CentOS/Fedora/RedHat (https://github.com/Linuxbrew/brew).

    test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
    test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
    echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile
    
#### For both systems

    brew install wget

(Windows usually have the windows version of wget== **winget** already installed, otherwise follow the [link](https://learn.microsoft.com/en-us/windows/package-manager/winget/) for directions)

Install conda for any [system](https://docs.conda.io/en/latest/miniconda.html#).
Installing Snakemake using [Mamba](https://github.com/mamba-org/mamba) is advised. In case you don’t use [Mambaforge](https://github.com/conda-forge/miniforge#mambaforge) you can always install [Mamba](https://github.com/mamba-org/mamba) into any other Conda-based Python distribution with:

    conda install -n base -c conda-forge mamba

Then install Snakemake with:

    mamba create -c conda-forge -c bioconda -n snakemake snakemake

For installation details, see the [instructions in the Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).

Download the latest SIRIUS executable manually from [here](https://github.com/boecker-lab/sirius/releases) until available as a conda-forge installation. Choose the headless zipped file compatible for your operating system (linux, macOS or windows) and unzip it under the directory "resources/". Make sure to register using your university email and password. 

Tip: Download a version >5.6. Avoid SNAPSHOT versions. Example (for linux OS:)
    
    (cd resources/ && wget https://github.com/boecker-lab/sirius/releases/download/v5.6.3/sirius-5.6.3-linux64-headless.zip && unzip *.zip)

Then, add your email and password to the scripts (required for SIRIUS versions > 5):
- rule [SIRIUS and CSI:FingerID](workflow/rules/sirius_csi.smk) lines 21, 22 and 42, 43
- rule [SIRIUS](workflow/rules/sirius.smk) lines 18, 19 and 37, 38

#### For both systems

Build OpenMS on [Linux](https://abibuilder.cs.uni-tuebingen.de/archive/openms/Documentation/nightly/html/install_linux.html), [MacOS](https://abibuilder.cs.uni-tuebingen.de/archive/openms/Documentation/nightly/html/install_mac.html) (or [Windows](https://abibuilder.cs.uni-tuebingen.de/archive/openms/Documentation/nightly/html/install_win.html)) until the 3.0 release is published.

Then add the binaries to your path (Linux):

    export PATH=$PATH:/path/to/openms-build/bin/
    source ~/.bashrc

Then add the binaries to your path (MacOS) by opening one of these files in a text editor:

    /etc/profile
    ~/.bash_profile
    ~/.bash_login (if .bash_profile does not exist)
    ~/.profile (if .bash_login does not exist)

and adding the path to the binaries at the very end:

    export PATH=$PATH:/path/to/openms-build/bin/

### Step 3: Configure workflow

Configure the workflow according to your needs via editing the files in the `config/` folder. Adjust `config.yaml` to configure the workflow execution (write TRUE/FALSE if you want to run/skip the specific rules of the workflow), and `samples.tsv` to specify the samples (files) that will be processed. 

**Suggestion: Use the Jupyter notebook [Create_dataset_tsv](./Create_dataset_tsv.ipynb) after you add all your files in the data/raw/ or data/mzML/ directory and avoid errors in the sample names or simply run:**
    
    python data_files.py

`config/dataset.tsv` example:

|  sample_name |       comment                |
|-------------:|-----------------------------:|
| ISP2_blank   | blank media                  |
| NBC_00162    | pyracrimicin                 |
| MDNA_WGS_14  | epemicins_A_B                |

If there are blanks in the file list, then add them to the config/blanks.tsv file
`config/blanks.tsv` example:

|  sample_name |       comment                |
|-------------:|-----------------------------:|
| ISP2_blank   | blank media                  |

`config/samples.tsv` example:

|  sample_name |       comment                |
|-------------:|-----------------------------:|
| NBC_00162    | pyracrimicin                 |
| MDNA_WGS_14  | epemicins_A_B                |


### Step 4: Execute workflow

Activate the conda environment:

    conda activate snakemake


#### Get example input data (only for testing the workflow with the example dataset)

    (cd data && wget https://zenodo.org/record/6948449/files/Commercial_std_raw.zip?download=1 && unzip *.zip -d raw)
    

Test your configuration by performing a dry-run via

    snakemake --use-conda -n

Execute the workflow locally via

    snakemake --use-conda --cores $N

See the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/executable.html) for further details.


### Step 5: Investigate results

All the results are in a .TSV format and can be opened simply with excel or using pandas dataframes. All the files under results/interim can be ignored and eventualy discarded.

## Developer Notes
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

Pfeuffer J, Sachsenberg T, Alka O, et al. OpenMS – A platform for reproducible analysis of mass spectrometry data. J Biotechnol. 2017;261:142-148. doi:10.1016/j.jbiotec.2017.05.016

Dührkop K, Fleischauer M, Ludwig M, et al. SIRIUS 4: a rapid tool for turning tandem mass spectra into metabolite structure information. Nat Methods. 2019;16(4):299-302. doi:10.1038/s41592-019-0344-8

Dührkop K, Shen H, Meusel M, Rousu J, Böcker S. Searching molecular structure databases with tandem mass spectra using CSI:FingerID. Proc Natl Acad Sci. 2015;112(41):12580-12585. doi:10.1073/pnas.1509788112

Nothias LF, Petras D, Schmid R, et al. Feature-based molecular networking in the GNPS analysis environment. Nat Methods. 2020;17(9):905-908. doi:10.1038/s41592-020-0933-6

Schmid R, Petras D, Nothias LF, et al. Ion identity molecular networking for mass spectrometry-based metabolomics in the GNPS environment. Nat Commun. 2021;12(1):3832. doi:10.1038/s41467-021-23953-9

Mölder F, Jablonski KP, Letcher B, et al. Sustainable data analysis with Snakemake. Published online January 18, 2021. doi:10.12688/f1000research.29032.1

de Jonge, N.F., Louwen, J.J.R., Chekmeneva, E. et al. MS2Query: reliable and scalable MS2 mass spectra-based analogue search. Nat Commun 14, 1752 (2023). doi:10.1038/s41467-023-37446-4
