
#!/usr/bin/env python3

import copy
import os
import numpy as np
from itertools import product
from simnibs import mesh_io, sim_struct
from simnibs.utils import TI_utils as TI

# Function to generate all combinations
def generate_combinations(E1_plus, E1_minus, E2_plus, E2_minus):
    combinations = []
    for e1p, e1m in product(E1_plus, E1_minus):
        for e2p, e2m in product(E2_plus, E2_minus):
            combinations.append(((e1p, e1m), (e2p, e2m)))
    return combinations

# Function to get user input for electrode lists
def get_electrode_list(prompt):
    while True:
        user_input = input(prompt).strip()
        # Handle both space-separated and comma-separated inputs
        if ',' in user_input:
            electrodes = [e.strip() for e in user_input.split(',')]
        else:
            electrodes = user_input.split()
        
        if all(len(e) > 0 for e in electrodes):
            return electrodes
        else:
            print("Please enter valid electrode names separated by spaces or commas.")

# Get the intensity of stimulation from user input
def get_intensity(prompt):
    while True:
        try:
            intensity_mV = float(input(prompt).strip())
            return intensity_mV / 1000.0  # Convert mV to V
        except ValueError:
            print("Please enter a valid number for the intensity of stimulation.")

# Get electrode lists from user input
E1_plus = get_electrode_list("Enter electrodes for E1_plus separated by spaces or commas: ")
E1_minus = get_electrode_list("Enter electrodes for E1_minus separated by spaces or commas: ")
E2_plus = get_electrode_list("Enter electrodes for E2_plus separated by spaces or commas: ")
E2_minus = get_electrode_list("Enter electrodes for E2_minus separated by spaces or commas: ")

# Get intensity of stimulation
intensity = get_intensity("Intensity of stimulation in mV: ")

# Generate all combinations
all_combinations = generate_combinations(E1_plus, E1_minus, E2_plus, E2_minus)

# Load lead field
leadfield_hdf = "leadfield_element/101_leadfield_EGI_template_reduced.hdf5"
leadfield, mesh, idx_lf = TI.load_leadfield(leadfield_hdf)

# Create output directory if it doesn't exist
output_dir = "opt"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Iterate through all combinations of electrode pairs
for i, ((e1p, e1m), (e2p, e2m)) in enumerate(all_combinations):
    TIpair1 = [e1p, e1m, intensity]
    TIpair2 = [e2p, e2m, intensity]

    # Get fields for the two pairs
    ef1 = TI.get_field(TIpair1, leadfield, idx_lf)
    ef2 = TI.get_field(TIpair2, leadfield, idx_lf)

    # Add to mesh for later visualization
    mout = copy.deepcopy(mesh)
    
    # Commented these for reducing complexity and improving efficiency.
    #mout.add_element_field(ef1, f"E_magn1_{e1p}_{e1m}")
    #mout.add_element_field(ef2, f"E_magn2_{e2p}_{e2m}")

    # Option 1: get maximal TI amplitude
    TImax = TI.get_maxTI(ef1, ef2)
    mout.add_element_field(TImax, "TImax")  # for visualization

    # Save the updated mesh with a unique name in the output directory
    mesh_filename = os.path.join(output_dir, f"TI_field_{e1p}_{e1m}_and_{e2p}_{e2m}.msh")
    mesh_io.write_msh(mout, mesh_filename)
    
    v = mout.view(
        visible_tags=[1, 2, 1006],
        visible_fields="TImax",
    )
    v.write_opt(mesh_filename)

    print(f"Saved {mesh_filename}")

