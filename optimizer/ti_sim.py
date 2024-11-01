#!/usr/bin/env python3

import copy
import os
import re
import numpy as np
from itertools import product
from simnibs import mesh_io
from simnibs.utils import TI_utils as TI

'''
Ido Haber - ihaber@wisc.edu
October 3, 2024
Optimized for optimizer pipeline

This script is designed for performing Temporal Interference (TI) simulations 
based on two types of leadfields:

1. Volumetric Leadfield:
   - Used for calculating TI_max, the maximal amplitude of the TI field in the volume.

2. Surface Leadfield:
   - Used for calculating TI_localnorm, the TI amplitude along the local normal orientation in gray matter.

The script generates all possible electrode pair combinations, calculates the corresponding electric fields, 
and exports the results in mesh format for further visualization.
'''

# Define color variables
BOLD = '\033[1m'
UNDERLINE = '\033[4m'
RESET = '\033[0m'
RED = '\033[0;31m'     # Red for errors
GREEN = '\033[0;32m'   # Green for success messages and prompts
CYAN = '\033[0;36m'    # Cyan for actions being performed
BOLD_CYAN = '\033[1;36m'

# Function to generate all combinations
def generate_combinations(E1_plus, E1_minus, E2_plus, E2_minus):
    combinations = []
    for e1p, e1m in product(E1_plus, E1_minus):
        for e2p, e2m in product(E2_plus, E2_minus):
            combinations.append(((e1p, e1m), (e2p, e2m)))
    return combinations

# Function to get user input for electrode lists
def get_electrode_list(prompt):
    pattern = re.compile(r'^E\d{3}$')  # Match 'E' followed by exactly three digits
    while True:
        user_input = input(f"{GREEN}{prompt}{RESET}").strip()
        # Replace commas with spaces and split into a list
        electrodes = user_input.replace(',', ' ').split()
        # Validate electrodes
        if all(pattern.match(e) for e in electrodes):
            return electrodes
        else:
            print(f"{RED}Invalid input. Please enter electrodes in the format E###, e.g., E001, E100.{RESET}")

# Get the intensity of stimulation from user input
def get_intensity(prompt):
    while True:
        try:
            intensity_mV = float(input(f"{GREEN}{prompt}{RESET}").strip())
            return intensity_mV / 1000.0  # Convert mV to V
        except ValueError:
            print(f"{RED}Please enter a valid number for the intensity of stimulation.{RESET}")

# Function to process lead field and generate the meshes
def process_leadfield(leadfield_type, E1_plus, E1_minus, E2_plus, E2_minus, intensity, project_dir, subject_name):
    print(f"{CYAN}Processing {leadfield_type} leadfield...{RESET}")
    # Load lead field
    leadfield_dir = os.path.join(project_dir, f"Subjects/leadfield_{leadfield_type}_{subject_name}")
    leadfield_hdf = os.path.join(leadfield_dir, f"{subject_name}_leadfield_{os.getenv('EEG_CAP', 'EGI_template')}.hdf5")
    try:
        leadfield, mesh, idx_lf = TI.load_leadfield(leadfield_hdf)
    except Exception as e:
        print(f"{RED}Error loading leadfield: {e}{RESET}")
        return

    # Set the output directory based on the project directory and subject name
    output_dir = os.path.join(project_dir, f"Simulations/opt_{subject_name}")

    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Generate all combinations
    all_combinations = generate_combinations(E1_plus, E1_minus, E2_plus, E2_minus)
    total_combinations = len(all_combinations)  # Calculate total configurations

    # Iterate through all combinations of electrode pairs
    for i, ((e1p, e1m), (e2p, e2m)) in enumerate(all_combinations):
        TIpair1 = [e1p, e1m, intensity]
        TIpair2 = [e2p, e2m, intensity]

        # Get fields for the two pairs
        try:
            ef1 = TI.get_field(TIpair1, leadfield, idx_lf)
            ef2 = TI.get_field(TIpair2, leadfield, idx_lf)
        except Exception as e:
            print(f"{RED}Error calculating fields for electrodes {e1p}, {e1m}, {e2p}, {e2m}: {e}{RESET}")
            continue

        # Add to mesh for later visualization
        mout = copy.deepcopy(mesh)
        
        if leadfield_type == "gm":
            # Calculate the TI norm along the local normal orientation for gm
            surf_normals = mesh.nodes_normals().value
            TIamp_localnorm = TI.get_dirTI(ef1, ef2, surf_normals)
            mout.add_node_field(TIamp_localnorm, 'TIamp_localnorm')  # for visualization
            mesh_filename = os.path.join(output_dir, f"TI_norm_field_{e1p}_{e1m}_and_{e2p}_{e2m}.msh")
            visible_field = "TIamp_localnorm"
        else:
            # Calculate the maximal TI amplitude for vol
            TImax = TI.get_maxTI(ef1, ef2)
            mout.add_element_field(TImax, "TImax")  # for visualization
            mesh_filename = os.path.join(output_dir, f"TI_field_{e1p}_{e1m}_and_{e2p}_{e2m}.msh")
            visible_field = "TImax"

        # Save the updated mesh with a unique name in the output directory
        mesh_io.write_msh(mout, mesh_filename)
        
        v = mout.view(
            visible_tags=[1, 2, 1006],
            visible_fields=visible_field,
        )
        v.write_opt(mesh_filename)

        # Progress indicator (formatted as 003/256)
        progress_str = f"{i+1:03}/{total_combinations}"
        print(f"{progress_str} Saved {mesh_filename}")

if __name__ == "__main__":
    import sys

    # Check for required environment variables
    project_dir = os.getenv('PROJECT_DIR')
    subject_name = os.getenv('SUBJECT_NAME')
    if not project_dir or not subject_name:
        print(f"{RED}Error: PROJECT_DIR and SUBJECT_NAME environment variables must be set.{RESET}")
        sys.exit(1)

    # Get electrode lists from user input
    E1_plus = get_electrode_list("Enter electrodes for E1_plus separated by spaces or commas (format E###): ")
    E1_minus = get_electrode_list("Enter electrodes for E1_minus separated by spaces or commas (format E###): ")
    E2_plus = get_electrode_list("Enter electrodes for E2_plus separated by spaces or commas (format E###): ")
    E2_minus = get_electrode_list("Enter electrodes for E2_minus separated by spaces or commas (format E###): ")

    # Get intensity of stimulation
    intensity = get_intensity("Intensity of stimulation in mV: ")

    # Process both gm and vol lead fields
    process_leadfield("gm", E1_plus, E1_minus, E2_plus, E2_minus, intensity, project_dir, subject_name)
    process_leadfield("vol", E1_plus, E1_minus, E2_plus, E2_minus, intensity, project_dir, subject_name)

