from ms2query.create_new_library.library_files_creator import LibraryFilesCreator
from ms2query.clean_and_filter_spectra import clean_normalize_and_split_annotated_spectra
from ms2query.utils import load_matchms_spectrum_objects_from_file, select_files_in_directory
from ms2query.run_ms2query import download_zenodo_files
from ms2query.ms2library import select_files_for_ms2query
import sys, os
from os.path import join 

def lib_training(input_LIB, ms2library, ion_mode):
    
    spectrum_file_location =  input_LIB # The file location of the library spectra
    library_spectra = load_matchms_spectrum_objects_from_file(spectrum_file_location)
    
    ionisation_mode =ion_mode # positive or negative defined in the config.yaml file
    
    directory_for_library_and_models= ms2library # Fill in the direcory in which the models will be downloaded and the library will be stored.
    
    isExist = os.path.exists(directory_for_library_and_models) #check if it exists
    if not isExist: #if the directory doesn't exist, then download the models from zenodo 
        download_zenodo_files(ionisation_mode, directory_for_library_and_models, only_models=True)
        files_in_directory = select_files_in_directory(directory_for_library_and_models)
  
    dict_with_file_names = select_files_for_ms2query(files_in_directory, ["s2v_model", "ms2ds_model", "ms2query_model"])
    ms2ds_model_file_name = join(directory_for_library_and_models, dict_with_file_names["ms2ds_model"])
    s2v_model_file_name = join(directory_for_library_and_models, dict_with_file_names["s2v_model"])
    ms2query_model = join(directory_for_library_and_models, dict_with_file_names["ms2query_model"])

    cleaned_library_spectra = clean_normalize_and_split_annotated_spectra(library_spectra, do_pubchem_lookup=False, ion_mode_to_keep=ion_mode)[0] 
    library_creator = LibraryFilesCreator(cleaned_library_spectra,
                                        output_directory=directory_for_library_and_models,  
                                        ms2ds_model_file_name= join(directory_for_library_and_models, dict_with_file_names["ms2ds_model"]),  # The file location of the ms2ds model
                                        s2v_model_file_name=join(directory_for_library_and_models, dict_with_file_names["s2v_model"])) # The file location of the s2v model
    library_creator.create_all_library_files()


if __name__ == "__main__":
    lib_training(sys.argv[1], sys.argv[2], sys.argv[3])