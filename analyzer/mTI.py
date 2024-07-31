
import os
import time
from copy import deepcopy
import numpy as np
from simnibs import mesh_io, run_simnibs, sim_struct
from simnibs.utils import TI_utils as TI


# Multipolar - Make sure you run at half the Unipolar intensity.
montages = {
    "RSC_1": [("E066", "E079"), ("E164", "E143")],
    "RSC_2": [("E098", "E100"), ("E129", "E152")],
    "thala_1": [("E111", "E122"), ("E133", "E144")],
    "thala_2": [("E145", "E156"), ("E167", "E178")]
}


# List of montage pairs for mTI calculations
montage_pairs = [
    ("RSC_1", "RSC_2"),
    ("thala_1", "thala_2")
]

# Base paths
base_subpath = "m2m_101"
main_dir = os.path.abspath(os.path.join(base_subpath, os.pardir))
base_pathfem = os.path.join(main_dir, "Multipolar_Simulations")
conductivity_path = "m2m_101"
tensor_file = os.path.join(conductivity_path, "DTI_coregT1_tensor.nii.gz")

# Ensure the base_pathfem directory exists
if not os.path.exists(base_pathfem):
    os.makedirs(base_pathfem)

# Function to run simulations
def run_simulation(montage_name, montage):
    S = sim_struct.SESSION()
    S.subpath = base_subpath
    S.anisotropy_type = "dir"
    S.pathfem = os.path.join(base_pathfem, f"TI_{montage_name}")
    S.eeg_cap = "m2m_101/eeg_positions/EGI_template.csv"
    S.map_to_surf = False
    S.map_to_fsavg = False
    S.map_to_vol = False
    S.map_to_mni = False
    S.open_in_gmsh = False
    S.tissues_in_niftis = "all"

    # Load the conductivity tensors
    S.dti_nii = tensor_file

    # First electrode pair
    tdcs = S.add_tdcslist()
    tdcs.anisotropy_type = 'dir'  # Set anisotropy_type to 'dir'
    tdcs.currents = [0.005, -0.005]
    electrode = tdcs.add_electrode()
    electrode.channelnr = 1
    electrode.centre = montage[0][0]
    electrode.shape = "ellipse"
    electrode.dimensions = [8, 8]
    electrode.thickness = [4, 4]

    electrode = tdcs.add_electrode()
    electrode.channelnr = 2
    electrode.centre = montage[0][1]
    electrode.shape = "ellipse"
    electrode.dimensions = [8, 8]
    electrode.thickness = [4, 4]

    # Second electrode pair
    tdcs_2 = S.add_tdcslist(deepcopy(tdcs))
    tdcs_2.currents = [0.005, -0.005]
    tdcs_2.electrode[0].centre = montage[1][0]
    tdcs_2.electrode[1].centre = montage[1][1]

    run_simnibs(S)

    last_three_digits = base_subpath[-3:]
    anisotropy_type = S.anisotropy_type

    m1_file = os.path.join(S.pathfem, f"{last_three_digits}_TDCS_1_{anisotropy_type}.msh")
    m2_file = os.path.join(S.pathfem, f"{last_three_digits}_TDCS_2_{anisotropy_type}.msh")

    m1 = mesh_io.read_msh(m1_file)
    m2 = mesh_io.read_msh(m2_file)

    tags_keep = np.hstack((np.arange(1, 100), np.arange(1001, 1100)))
    m1 = m1.crop_mesh(tags=tags_keep)
    m2 = m2.crop_mesh(tags=tags_keep)

    ef1 = m1.field["E"]
    ef2 = m2.field["E"]
    TImax_vectors = TI.get_TImax_vectors(ef1.value, ef2.value)

    mout = deepcopy(m1)
    mout.elmdata = []
    mout.add_element_field(TImax_vectors, "TI_vectors")
    output_mesh_path = os.path.join(S.pathfem, f"TI_{montage_name}.msh")
    mesh_io.write_msh(mout, output_mesh_path)

    v = mout.view(visible_tags=[1002, 1006], visible_fields=["TI_vectors"])
    v.write_opt(output_mesh_path)
    
    return output_mesh_path

# Run the simulations and collect the output paths
output_paths = {name: run_simulation(name, montage) for name, montage in montages.items()}


#################################################
######### THIS IS mTI calculation ###############
#################################################

# Iterate through the montage pairs for mTI calculation
for pair in montage_pairs:
    m1_name, m2_name = pair
    if m1_name in output_paths and m2_name in output_paths:
        m1_path = output_paths[m1_name]
        m2_path = output_paths[m2_name]

        m1 = mesh_io.read_msh(m1_path)
        m2 = mesh_io.read_msh(m2_path)

        # Calculate the maximal amplitude of the TI envelope
        ef1 = m1.field["TI_vectors"]
        ef2 = m2.field["TI_vectors"]

        # Use the get_maxTI function
        TI_MultiPolar = TI.get_maxTI(ef1.value, ef2.value)

        # Make a new mesh for visualization of the field strengths
        # and the amplitude of the TI envelope
        mout = deepcopy(m1)
        mout.elmdata = []

        mout.add_element_field(TI_MultiPolar, "TI_Max")

        mp_pathfem = base_pathfem
        output_mesh_path = os.path.join(mp_pathfem, f"mTI_{m1_name}_{m2_name}.msh")
        mesh_io.write_msh(mout, output_mesh_path)
    else:
        print(f"Montage names {m1_name} and {m2_name} are not in the output paths.")
