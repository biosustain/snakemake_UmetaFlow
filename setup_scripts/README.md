# umetaflow_tutorial
This is a collection of scripts to install [umetaflow](https://github.com/biosustain/snakemake_UmetaFlow) resources

## Usage
- Get the latest release of the script 
```bash
SCRIPT_VERSION="0.1.4"
wget -O setup_scripts.zip https://github.com/NBChub/umetaflow_tutorial/archive/refs/tags/$SCRIPT_VERSION.zip
unzip setup_scripts.zip && mv umetaflow_tutorial-$SCRIPT_VERSION/ setup_scripts
```
- Run the script:
```bash
bash setup_scripts/setup.sh --help
```
- To run the script, remove the `--help` flag. By default, it will download the files to the `resources` folder. You can also change it to your desired path.
