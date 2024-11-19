from pathlib import Path
import sys
from ms2query.run_ms2query import run_complete_folder, run_ms2query_single_file
from ms2query.ms2library import create_library_object_from_one_dir
from ms2query.utils import SettingsRunMS2Query


def analog_search(mgf_spectra, results_file, library_success):

    # Create a MS2Library object
    ms2library = create_library_object_from_one_dir(Path(library_success).parent)

    if Path(results_file).exists():
        Path(results_file).unlink()

    # Run library search and analog search on your files.
    run_ms2query_single_file(
        spectrum_file_name=Path(mgf_spectra).name,
        ms2library=ms2library,
        folder_with_spectra=Path(mgf_spectra).parent,
        results_folder=Path(results_file).parent,
        settings=SettingsRunMS2Query(additional_metadata_columns=("FEATURE_ID",))
    )


if __name__ == "__main__":
    analog_search(sys.argv[1], sys.argv[2], sys.argv[3])
