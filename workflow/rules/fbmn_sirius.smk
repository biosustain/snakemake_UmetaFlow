# This rule is for integrating the FBMN results with the SIRIUS annotations.
# After the FBMN job is done, download the graphml file under the directory workflow/GNPSexport and run the following rule:
# Credits to Ming Wang for sharing the Jupyter notebook for the integration
import glob
from os.path import join

if config["rules"]["requantification"]==True:
    rule graphml:
        input:
            input_matrix= join("results", "Requantified", "FeatureMatrix.tsv"),
            input_mgf= join("results", "GNPSexport", "MSMS.mgf"),
            input_graphml= glob.glob(join("results", "GNPSexport", "*.graphml"))
        output:    
            output_graphml= join("results", "GNPSexport", "fbmn_network_sirius.graphml")
        log: join("workflow", "report", "logs", "GNPSexport", "fbmn_sirius.log")
        threads: 4
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            python workflow/scripts/FBMN_SIRIUS.py {input.input_matrix} {input.input_mgf} {input.input_graphml} {output.output_graphml} 2>> {log}
            """
else:
    rule graphml:
        input:
            input_matrix= join("results", "Preprocessed", "FeatureMatrix.tsv"),
            input_mgf= join("results", "GNPSexport", "MSMS.mgf"),
            input_graphml= glob.glob(join("results", "GNPSexport", "*.graphml"))
        output:    
            output_graphml= join("results", "GNPSexport", "fbmn_network_sirius.graphml")
        log: join("workflow", "report", "logs", "GNPSexport", "fbmn_sirius.log")
        threads: 4
        conda:
            join("..", "envs", "openms.yaml")
        shell:
            """
            python workflow/scripts/FBMN_SIRIUS.py {input.input_matrix} {input.input_mgf} {input.input_graphml} {output.output_graphml} 2>> {log}
            """