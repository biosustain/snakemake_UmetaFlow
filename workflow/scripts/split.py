from pyopenms import *
import glob
import sys

# Split the ConsensusMap into features that have no missing values, 
# and features that have at least one missing value; 
# requantify only the missing values. 

def split(in_cmap, out_complete, out_missing):
    # split ConsensusMap
    consensus_map = ConsensusMap()
    ConsensusXMLFile().load(in_cmap, consensus_map)

    headers = consensus_map.getColumnHeaders()

    complete = ConsensusMap(consensus_map)
    complete.clear(False)
    missing = ConsensusMap(consensus_map)
    missing.clear(False)

    for cf in consensus_map:
        if len(cf.getFeatureList()) < len(headers): #missing values
            missing.push_back(cf)
        else:
            complete.push_back(cf) #no missing values

    ConsensusXMLFile().store(out_complete, complete)
    ConsensusXMLFile().store(out_missing, missing)
    return out_complete, out_missing

if __name__ == "__main__":
    split(sys.argv[1], sys.argv[2], sys.argv[3])