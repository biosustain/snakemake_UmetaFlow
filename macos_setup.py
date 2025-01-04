import os
import subprocess
import shutil

"""
Download resources required for running UmetaFlow on MacOS Silicon.

- Downloads SIRIUS and Thermorawfileparser into resources directory
- Modifies the workflow code to be compatible with MacOS
    - updates env files to not install SIRIUS, Thermorawfileparser and mono
    - updates the commands for file conversion and SIRIUS to use the path of downloaded executables
- attempts to install mono via brew
"""

def download_and_extract(url, target_folder, zip_name):
    """
    Download and extract a zip file from the given URL.

    Args:
        url (str): URL of the file to download.
        target_folder (str): Directory to extract the zip file.
        zip_name (str): Name of the zip file to save locally.
    """
    # Remove the target folder if it exists
    if os.path.exists(target_folder):
        shutil.rmtree(target_folder)
    
    # Create the target folder
    os.makedirs(target_folder, exist_ok=True)

    # Path to save the zip file
    zip_file = os.path.join(target_folder, zip_name)

    # Download the file using curl
    subprocess.run(["curl", "-L", "-o", zip_file, url], check=True)

    # Extract the zip file
    subprocess.run(["unzip", "-o", zip_file, "-d", target_folder], check=True)

    # Remove the zip file
    os.remove(zip_file)


def update_env_file(file_path, exclusions):
    """
    Filters out lines containing any of the exclusion keywords from a file.

    Parameters:
        file_path (str): The path to the file to process.
        exclusions (list): List of keywords to exclude.

    Returns:
        None
    """
    print(f"\nUpdating {file_path} ...")
    with open(file_path, "r") as f:
        content = f.readlines()

    filtered_content = [
        line for line in content if not any(exclusion in line for exclusion in exclusions)
    ]

    with open(file_path, "w") as f:
        f.writelines(filtered_content)

def update_workflow_code(file_path, replacements):
    """
    Replaces occurrences of specified text snippets in a file with their corresponding replacements.

    Parameters:
        file_path (str): The path to the file to process.
        replacements (dict): A dictionary where keys are text snippets to replace, and values are their replacements.

    Returns:
        None
    """
    print(f"\nUpdating {file_path} ...")
    with open(file_path, "r") as f:
        content = f.read()

    # Replace text based on the dictionary
    for old_text, new_text in replacements.items():
        content = content.replace(old_text, new_text)

    with open(file_path, "w") as f:
        f.write(content)

def check_installed(tool: str):
    """
    Checks if a given command line tool is installed.

    Parameters:
        tool (str): The tool to check.

    Returns:
        None
    """
    try:
        # Run 'brew --version' and check the output
        result = subprocess.run([tool, '--version'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode == 0:
            print(f"{tool} is installed.")
            print("Version:", result.stdout.strip())
            return True
        else:
            print(f"{tool} is not installed.")
    except FileNotFoundError:
        # If the command is not found, brew is not installed
        print(f"{tool} is not installed.")
    return False

def main():
    print("This script will set up UmetaFlow for MacOS Silicon.")

    main_folder = "resources"

    # OpenMS
    update_env_file("workflow/envs/openms.yaml", ["dependencies", "openms=3.2", "zlib"])

    # SIRIUS
    sirius_folder = os.path.join(main_folder, "Sirius")
    sirius_url = "https://github.com/sirius-ms/sirius/releases/download/v5.8.6/sirius-5.8.6-osx64.zip"
    sirius_zip_name = "sirius-5.8.6-osx64.zip"

    print("\nDownloading and extracting SIRIUS...")
    download_and_extract(sirius_url, sirius_folder, sirius_zip_name)
    update_env_file("workflow/envs/sirius.yaml", ["dependencies", "sirius-ms"])
    update_workflow_code("workflow/rules/SIRIUS.smk", {" sirius ": " resources/Sirius/sirius.app/Contents/MacOS/sirius "})
    print("\nSIRIUS setup complete.")

    # ThermoRawFileParser
    trfp_folder = os.path.join(main_folder, "ThermoRawFileParser")
    trfp_url = "https://github.com/compomics/ThermoRawFileParser/releases/download/v1.3.4/ThermoRawFileParser.zip"
    trfp_zip_name = "ThermoRawFileParser.zip"

    print("\nDownloading and extracting ThermoRawFileParser...")
    download_and_extract(trfp_url, trfp_folder, trfp_zip_name)
    update_env_file("workflow/envs/file-conversion.yaml", ["dependencies", "mono", "thermorawfileparser"])
    update_workflow_code("workflow/rules/fileconversion.smk", {"thermorawfileparser": "mono resources/ThermoRawFileParser/ThermoRawfileparser.exe", "--output ": "--output_file "})

    if not check_installed("mono"):
        # Install mono via brew
        if check_installed("brew"):
            print("\nInstalling 'mono' via homebrew...")
            subprocess.run(["brew", "install", "mono"])
    
    if not check_installed("mono"):
        print("\nWARNING: 'mono' is not installed, but required for the file conversion step. Make sure it is installed (e.g. via homebrew).\n\nhttps://formulae.brew.sh/formula/mono\n\nOR install homebrew and run this script again\n\nInstall homebrew running this command:\n\n/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
    else:
        print("\nThermoRawFileParser setup complete.")

    print("\nDONE")

if __name__ == "__main__":
    main()
