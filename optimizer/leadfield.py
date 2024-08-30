
import os
from simnibs import run_simnibs, sim_struct
import sys

# Ensure the correct number of arguments are provided
if len(sys.argv) != 3:
    print("Usage: leadfield.py <subject_directory> <eeg_cap_filename>")
    sys.exit(1)

# Get the subject path and EEG cap filename from command line arguments
subject_ID = sys.argv[1]
eeg_cap = sys.argv[2]

# Function to create the leadfield matrix
def create_leadfield(subject_ID, eeg_cap, interpolation=None, tissues=None, suffix=''):
    tdcs_lf = sim_struct.TDCSLEADFIELD()

    # Extract the subject number or ID from the provided path
    subject_number = os.path.basename(subject_ID).replace('m2m_', '')

    # File handling
    output_dir = os.path.join(os.path.dirname(subject_ID), f"leadfield_{suffix}_{subject_number}")
    
    # Ensure the output directory exists
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    tdcs_lf.subpath = subject_ID  # subject directory
    tdcs_lf.pathfem = output_dir  # output directory next to m2m_subjectID
    tdcs_lf.eeg_cap = eeg_cap  # specific file in eeg-cap directory.

    # Electrode configuration
    electrode = tdcs_lf.electrode
    electrode.dimensions = [8, 8]  # in mm
    electrode.shape = "ellipse"  # shape
    electrode.thickness = [4, 4]  # arg1=gel_thickness , arg2=electrode_thickness

    # Set interpolation and tissues
    tdcs_lf.interpolation = interpolation
    if tissues is not None:
        tdcs_lf.tissues = tissues

    # Optionally enable the faster pardiso solver if memory allows
    # tdcs_lf.solver_options = "pardiso"

    # Run the simulation
    run_simnibs(tdcs_lf)

# Full path to the m2m_subjectID directory
subject_path = subject_ID

# Create the volumetric leadfield
create_leadfield(
    subject_ID=subject_path,
    eeg_cap=eeg_cap,
    interpolation=None,  # No interpolation for volumetric data
    tissues=list(range(1, 16)),  # All tissues
    suffix='vol'
)

# Create the GM surface leadfield
create_leadfield(
    subject_ID=subject_path,
    eeg_cap=eeg_cap,
    interpolation='middle gm',  # Interpolation for the GM surface
    tissues=None,  # No tissue list for surface data
    suffix='gm'
)

print("Leadfield matrices have been successfully created.")

