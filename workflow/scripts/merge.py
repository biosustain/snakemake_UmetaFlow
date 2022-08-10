from pyopenms import *
import os
import glob
import sys

def merge(in_complete, in_requant, in_merge):
    for complete_map in sorted(glob.glob(in_complete)):
        for requant_map in sorted(glob.glob(in_requant)):
            if os.path.basename(complete_map)[9:] == os.path.basename(requant_map)[6:]:
                fm_ffm = FeatureMap()
                FeatureXMLFile().load(complete_map, fm_ffm)
                fm_ffmid = FeatureMap()
                FeatureXMLFile().load(requant_map, fm_ffmid)
                for f in fm_ffmid:
                    fm_ffm.push_back(f)
                fm_ffm.setUniqueIds()
                FeatureXMLFile().store(in_merge, fm_ffm)
    return in_merge

if __name__ == "__main__":
    merge(sys.argv[1], sys.argv[2], sys.argv[3])