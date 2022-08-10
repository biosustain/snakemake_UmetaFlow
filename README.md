# UmetaFlow: An Untargeted Metabolomics workflow for high-throughput data processing and analysis for Linux and MacOS systems

[![Snakemake](https://img.shields.io/badge/snakemake-≥6.7.0-brightgreen.svg)](https://snakemake.bitbucket.io)
[![Build Status](https://travis-ci.org/snakemake-workflows/snakemake-bgc-analytics.svg?branch=master)](https://travis-ci.org/snakemake-workflows/snakemake-bgc-analytics)

This is a snakemake implementation of the pyOpenMS workflow (see https://github.com/eeko-kon/pyOpenMS_untargeted_metabolomics.git) tailored by [Eftychia Eva Kontou](https://github.com/eeko-kon) and [Axel Walter](https://github.com/axelwalter).

## Workflow overview

The pipeline consists of five interconnected steps:

1) File conversion: Simply add your Thermo raw files in data/raw/ and they will be converted to centroid mzML files. If you have Agilent or Bruker files, skip that step (write "FALSE" for rule fileconversion in the config.yaml file - see more under "Configure workflow") and convert them independently using proteowizard (see https://proteowizard.sourceforge.io/) and add them to the data/mzML/ directory.

2) Pre-processing: converting raw data to a feature table with a series of algorithms 

3) Re-quantification: Re-quantify all raw files to avoid missing values resulted by the pre-processing workflow for statistical analysis and data exploration.

4) Structural and formula predictions (SIRIUS and CSI:FingeID)

5) GNPSexport: generate all the files necessary to create a [FBMN](https://ccms-ucsd.github.io/GNPSDocumentation/featurebasedmolecularnetworking-with-openms/) or [IIMN](https://ccms-ucsd.github.io/GNPSDocumentation/fbmn-iin/#iimn-networks-with-collapsed-ion-identity-edges)job at GNPS. 

6) Annotate the feature matrix with formula and structural predictions (GNPS metabolite annotations optional).

7) Integrate Sirius and CSI predictions to the network (after FBMN)

### Overview
![dag](/images/UmetaFlow_graph.svg)

## Usage

### Step 1: Clone the workflow

[Clone](https://help.github.com/en/articles/cloning-a-repository) this repository to your local system, into the place where you want to perform the data analysis.

(Make sure to have the right access / SSH Key. If **not**, follow the steps:
Step 1: https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

Step 2: https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)


    git clone https://github.com/NBChub/snakemake-UmetaFlow.git

### Step 2: Configure workflow

Configure the workflow according to your needs via editing the files in the `config/` folder. Adjust `config.yaml` to configure the workflow execution (write TRUE/FALSE if you want to run/skip the specific rules of the workflow), and `samples.tsv` to specify the samples (files) that will be processed. 

**Suggestion: Use the Jupyter notebook [Create_sampletsv_file](./Create_sampletsv_file.ipynb) after you add all your files in the data/raw/ or data/mzML/ directory and avoid spaces in sample names.**

`samples.tsv` example:

|  sample_name |       comment                |
|-------------:|-----------------------------:|
| NBC_00162    | pyracrimicin                 |
| MDNA_WGS_14  | epemicins_A_B                |


Further formatting rules can be defined in the `workflow/schemas/` folder.

### Step 3: Create a conda environment& install snakemake

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

Install conda for any [system](https://docs.conda.io/en/latest/miniconda.html#linux-installers).
Installing Snakemake using [Mamba](https://github.com/mamba-org/mamba) is advised. In case you don’t use [Mambaforge](https://github.com/conda-forge/miniforge#mambaforge) you can always install [Mamba](https://github.com/mamba-org/mamba) into any other Conda-based Python distribution with:

    conda install -n base -c conda-forge mamba

Then install Snakemake with:

    mamba create -c conda-forge -c bioconda -n snakemake snakemake

For installation details, see the [instructions in the Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).

### Step 4: Execute workflow

Activate the conda environment:

    conda activate snakemake

Build OpenMS on [Linux](https://abibuilder.informatik.uni-tuebingen.de/archive/openms/Documentation/nightly/html/install_linux.html) or [MacOS](https://abibuilder.informatik.uni-tuebingen.de/archive/openms/Documentation/release/latest/html/install_mac.html) until the 3.0 release is published.

#### For Linux only !

Install mono with sudo:

    sudo apt install mono-devel

If sudo cannot find the package, then follow the directions in the [link](https://www.mono-project.com/download/stable/#download-lin) for the Ubuntu version that you work with.

Press enter (RETURN) to continue 

#### Get example input data (only for testing the workflow with the example dataset)

    (cd data && wget https://zenodo.org/record/6948449/files/Commercial_std_raw.zip?download=1 && unzip *.zip -d raw)
    
#### Execute the workflow
    
Get the latest pyOpenMS wheels (until pyOpenMS 3.0 is available in conda):

    MY_OS="Linux" # or "macOS" or "Windows" (case-sensitive)
    mkdir -p .snakemake/conda/
    wget -O .snakemake/conda/${MY_OS}-wheels.zip https://nightly.link/OpenMS/OpenMS/workflows/pyopenms-wheels/nightly/${MY_OS}-wheels.zip\?status\=completed
    (cd .snakemake/conda/ && mv ${MY_OS}-wheels.zip\?status=completed ${MY_OS}-wheels.zip && unzip *.zip)
    find .snakemake/conda/*cp39*.whl > .snakemake/conda/requirements.txt
    rm .snakemake/conda/*.whl & rm .snakemake/conda/*.zip

Create the environment with the executables manually:

    mamba env create --prefix ".snakemake/conda/exe" -f "workflow/envs/exe.yaml"

Test your configuration by performing a dry-run via

    snakemake --use-conda -n

Execute the workflow locally via

    snakemake --use-conda --cores $N

See the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/executable.html) for further details.


### Step 5: Investigate results

All the results are in a .TSV format and can be opened simply with excel or using pandas dataframes. All the files under results/interim can be ignored or deleted.

## Developer Notes
### Config & Schemas

* [Config & schemas](https://snakemake.readthedocs.io/en/stable/snakefiles/configuration.html) define the input formatting and are important to generate `wildcards`. The idea of using `samples` and `units` came from [here](https://github.com/snakemake-workflows/dna-seq-gatk-variant-calling). I think we should use `units.txt` as a central metadata of the runs which are regulary updated (and should be the same for all use case). Then, `samples.txt` can be used to decide which strains need to be assembled per use case. 

### Rules

* [Snakefile](workflow/Snakefile): the main entry of the pipeline which tells the final output to be generated and the rules being used
* [common.smk](workflow/rules/common.smk): a rule that generate the variable used (strain names) & other helper scripts
* [The main rules (*.smk)](workflow/rules/): is the bash code that has been chopped into modular units, with defined input & output. Snakemake then chain this rules together to generate required jobs. This should be intuitive and makes things easier for adding / changing steps in the pipeline.

### Environments

* Conda environments are defined as .yaml file in `workflow/envs`
* Note that not all dependencies are compatible/available as conda libraries. Once installed, the virtual environment are stored in `.snakemake/conda` with unique hashes. The ALE and pilon are example where environment needs to be modified / dependencies need to be installed.
* It might be better to utilise containers / dockers and cloud execution for "hard to install" dependencies
* Custom dependencies and databases are stored in the `resources/` folder.
* Snakemake dependencies with conda packages is one of the drawbacks and why [Nextflow](https://www.nextflow.io/) might be more preferable. Nevertheless, the pythonic language of snakemake enable newcomers to learn and develop their own pipeline faster.

### Test Data (only for testing the workflow with the example dataset)

* Current test data are built from known metabolite producer strains or standard samples that have been analyzed with a Thermo Orbitrap IDX instrument. The presence of the metabolites and their fragmentation patterns has been manually confirmed using TOPPView.

### Citations

Pfeuffer J, Sachsenberg T, Alka O, et al. OpenMS – A platform for reproducible analysis of mass spectrometry data. J Biotechnol. 2017;261:142-148. doi:10.1016/j.jbiotec.2017.05.016

Dührkop K, Fleischauer M, Ludwig M, et al. SIRIUS 4: a rapid tool for turning tandem mass spectra into metabolite structure information. Nat Methods. 2019;16(4):299-302. doi:10.1038/s41592-019-0344-8

Dührkop K, Shen H, Meusel M, Rousu J, Böcker S. Searching molecular structure databases with tandem mass spectra using CSI:FingerID. Proc Natl Acad Sci. 2015;112(41):12580-12585. doi:10.1073/pnas.1509788112

Nothias LF, Petras D, Schmid R, et al. Feature-based molecular networking in the GNPS analysis environment. Nat Methods. 2020;17(9):905-908. doi:10.1038/s41592-020-0933-6

Mölder F, Jablonski KP, Letcher B, et al. Sustainable data analysis with Snakemake. Published online January 18, 2021. doi:10.12688/f1000research.29032.1
