from pyopenms import *
import glob
import sys

def reloadmaps(in_aligned, in_complete, out_complete):
    # first load feature files in an OpenMS format 
    featurexml_files= glob.glob(in_aligned)
    feature_maps = []
    for featurexml_file in featurexml_files:
        fmap = FeatureMap()
        FeatureXMLFile().load(featurexml_file, fmap)
        feature_maps.append(fmap)

    consensus_map = ConsensusMap()
    ConsensusXMLFile().load(in_complete, consensus_map)
    to_keep_ids = [item for sublist in [[feature.getUniqueId() for feature in cf.getFeatureList()] for cf in consensus_map] for item in sublist]

    for fm in feature_maps:
        fm_filterd = FeatureMap(fm)
        fm_filterd.clear(False)
        for f in fm:
            if f.getUniqueId() in to_keep_ids:
                fm_filterd.push_back(f)
        FeatureXMLFile().store(out_complete, fm_filterd)
    
    return out_complete

if __name__ == "__main__":
    reloadmaps(sys.argv[1], sys.argv[2], sys.argv[3])