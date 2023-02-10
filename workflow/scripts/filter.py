from pyopenms import *
import sys
import os
import pandas as pd
import glob

def filter(feature_files, out_filtered):
    featurexml_files= glob.glob(os.path.join("results", "Interim", "Preprocessed", "FFM_*.featureXML"))
    feature_maps = []
    for file in featurexml_files:
        fmap = FeatureMap()
        FeatureXMLFile().load(file, fmap)
        feature_maps.append(fmap)
    # first we need to link the files (group)
    # 2nd export the dataframe with the individual feature IDs
    feature_grouper = FeatureGroupingAlgorithmKD()
    consensus_map = ConsensusMap()
    file_descriptions = consensus_map.getColumnHeaders()

    for i, feature_map in enumerate(feature_maps):
        file_description = file_descriptions.get(i, ColumnHeader())
        file_description.filename = os.path.basename(feature_map.getMetaValue("spectra_data")[0].decode())[7:]
        file_description.size = feature_map.size()
        file_descriptions[i] = file_description

    feature_grouper.group(feature_maps, consensus_map)
    consensus_map.setUniqueIds()
    consensus_map.setColumnHeaders(file_descriptions)

    # get intensities as a DataFrame
    df = consensus_map.get_df()
    df["feature_ids"] = [[handle.getUniqueId() for handle in cf.getFeatureList()] for cf in consensus_map]
    df= df.reset_index()
    df= df.drop(columns= ["sequence"])
    # blank filtering (define the blanks== user input)
    df= df.drop(columns=["id", "charge", "quality", "mz", "RT"])
    blank_df= pd.read_csv(os.path.join("config", "blanks.tsv"), sep="\t")
    if blank_df.empty:
        print("no blanks, controls or QCs given")
        for fmap in feature_maps:
            FeatureXMLFile().store(out_filtered, fmap)
    else:    
        blank_df["sample_name"]= blank_df["sample_name"].astype(str) +".mzML"
        blank_files= blank_df["sample_name"].values.tolist()
        samples= df[[col for col in df.columns if col not in blank_files]]
        blanks= df[[col for col in df.columns if col in blank_files]]
        #split samples and blanks
        def remove_blank_features(blanks, samples, cutoff):
            # Getting mean for every feature in blank and Samples
            avg_blank = blanks.mean(axis=1, skipna=False) # set skipna = False do not exclude NA/null values when computing the result.
            #avg_samples= samples.set_index("feature_ids")
            avg_samples = samples.mean(axis=1, skipna=False)
            # Getting the ratio of blank vs samples
            ratio_blank_samples = (avg_blank+1)/(avg_samples+1)

            # Create an array with boolean values: True (is a real feature, ratio<cutoff) / False (is a blank, background, noise feature, ratio>cutoff)
            is_real_feature = (ratio_blank_samples<cutoff)
            # get all the feature IDs for the filtered/"real" features
            real_features = samples[is_real_feature.values]
            keep_ids=[item for sublist in real_features["feature_ids"] for item in sublist]
            return keep_ids
        keep_ids= remove_blank_features(blanks, samples, 0.3) #use a cutoff at 0.3
        for fmap in feature_maps:
            if os.path.basename(fmap.getMetaValue("spectra_data")[0].decode())[7:] not in blank_files:
                fmap_clean= FeatureMap(fmap)
                fmap_clean.clear(False)
                for f in fmap:
                    if f.getUniqueId() in keep_ids:
                        fmap_clean.push_back(f)
                FeatureXMLFile().store(out_filtered, fmap_clean)
    return out_filtered

if __name__ == "__main__":
    filter(sys.argv[1], sys.argv[2])