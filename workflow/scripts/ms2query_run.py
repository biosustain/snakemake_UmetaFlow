from ms2query.run_ms2query import download_zenodo_files, run_complete_folder
from ms2query.ms2library import create_library_object_from_one_dir

# Set the location where downloaded library and model files are stored
ms2query_library_files_directory = "results/Interim/MS2Query/ms2query_library_files"

# Define the folder in which your query spectra are stored.
# Accepted formats are: "mzML", "json", "mgf", "msp", "mzxml", "usi" or a pickled matchms object.
ms2_spectra_directory = "results/GNPS"
ion_mode = "positive"  # Fill in "positive" or "negative" to indicate for which ion mode you would like to download the library
results_folder = "results/Interim/MS2Query"

# Downloads pretrained models and files for MS2Query (>2GB download)

download_zenodo_files(ion_mode, ms2query_library_files_directory)

# Create a MS2Library object
ms2library = create_library_object_from_one_dir(ms2query_library_files_directory)

# Run library search and analog search on your files.
run_complete_folder(
    ms2library=ms2library,
    folder_with_spectra=ms2_spectra_directory,
    results_folder=results_folder,
)
