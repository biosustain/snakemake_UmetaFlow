from ms2query.create_new_library.library_files_creator import LibraryFilesCreator
from ms2query.clean_and_filter_spectra import clean_normalize_and_split_annotated_spectra
from ms2query.utils import load_matchms_spectrum_objects_from_file
from ms2query.ms2library import create_library_object_from_one_dir
import sys
from os.path import join 

def lib_training(input_LIB, ms2library):
    spectrum_file_location =  input_LIB # The file location of the library spectra
    library_spectra = load_matchms_spectrum_objects_from_file(spectrum_file_location)
    # Fill in the missing values:
    cleaned_library_spectra = clean_normalize_and_split_annotated_spectra(library_spectra, ion_mode_to_keep="positive")[0]  # fill in "positive" or "negative"
    library_creator = LibraryFilesCreator(cleaned_library_spectra,
                                        output_directory=join("results", "Interim", "annotations", "ms2query"),  # For instance "data/library_data/all_GNPS_positive_mode_"
                                        ms2ds_model_file_name=join("resources", "ms2query", "ms2ds_model_GNPS_15_12_2021.hdf5"),  # The file location of the ms2ds model
                                        s2v_model_file_name=join("resources", "ms2query","spec2vec_model_GNPS_15_12_2021.model"))  # The file location of the s2v model
    library_creator.create_all_library_files()

    ms2_library_directory = join("resources", "ms2query") # Specify the directory containing all the library and model files

    # Create a MS2Library object from one directory
    # If this does not work (because files have unexpected names or are not in one dir) see below.
    ms2library = create_library_object_from_one_dir(ms2_library_directory)

    return ms2library

if __name__ == "__main__":
    lib_training(sys.argv[1], sys.argv[2])