from pathlib import Path
import sys
import shutil
from ms2query.run_ms2query import download_zenodo_files


def download_ms2query_libraries(ion_mode, flag_file):
    # Set the location where downloaded library and model files are stored
    ms2query_library_files_directory = Path("results", "Interim", "MS2Query", "library_files")

    if ms2query_library_files_directory.exists():
        shutil.rmtree(ms2query_library_files_directory)

    ms2query_library_files_directory.mkdir(exist_ok=True, parents=True)

    # Downloads pretrained models and files for MS2Query (>2GB download)
    download_zenodo_files(ion_mode, ms2query_library_files_directory)

    Path(flag_file).touch()


if __name__ == "__main__":
    download_ms2query_libraries(sys.argv[1], sys.argv[2])
