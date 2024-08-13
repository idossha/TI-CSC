
import os
from simnibs import run_simnibs, sim_struct

tdcs_lf = sim_struct.TDCSLEADFIELD()

# User input for subject ID and EEG cap
subject_ID = input("Enter the full path to the m2m_subjectID directory (e.g., '/Users/idohaber/Desktop/strengthen/Subjects/m2m_101'): ")
eeg_cap = input("Enter the EEG cap filename (e.g., 'EGI_template.csv'): ")

# Extract the subject number or ID from the provided path
subject_number = os.path.basename(subject_ID).replace('m2m_', '')

print("############################################")
print("############################################")
print("Make sure the output file is:")
print(f"leadfield_{subject_number}, and it should be placed next to {subject_ID} directory.")
print("############################################")
print("############################################")

# file handling
tdcs_lf.subpath = subject_ID  # subject directory
tdcs_lf.pathfem = os.path.join(os.path.dirname(subject_ID), f"leadfield_{subject_number}")  # output directory next to m2m_subjectID
tdcs_lf.eeg_cap = eeg_cap  # specific file in eeg-cap directory.

# electrode configuration
electrode = tdcs_lf.electrode
electrode.dimensions = [8, 8]  # in mm
electrode.shape = "ellipse"  # shape
electrode.thickness = [4, 4]  # arg1=gel_thickness , arg2=electrode_thickness

# Disable surface interpolation to avoid conflict
tdcs_lf.interpolation = None

'''
Tissue names & values:

Scalp: 1
Skull: 2
CSF (Cerebrospinal fluid): 3
GM (Gray Matter): 4
WM (White Matter): 5
Electrodes: 6
Air: 7
Gel: 8
Cortical Spongy Bone: 9
Cortical Compact Bone: 10
Eyes: 11
Muscle: 12
Tumor: 13
Fat: 14
Blood: 15
'''
tissue_list = list(range(1, 16))
tdcs_lf.tissues = tissue_list

"""
You can uncomment to use the pardiso solver which is faster than default. However not that significant. 
Also, it requires much more memory (~12 GB for normal net, 30GB for high density).

Does not work well on Apple Silicon chips.
"""

# tdcs_lf.solver_options = "pardiso"

run_simnibs(tdcs_lf)

