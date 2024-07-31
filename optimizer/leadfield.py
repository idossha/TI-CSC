#!/Users/idohaber/Applications/SimNIBS-4.1/bin/simnibs_python
# -*- coding: utf-8 -*-

"""
Based on the work of Guilherme B Saturnini 2019
Modified by Ido Haber, 2024
Project: STRENGTHEN
Center for Sleep & Consciousness, UW Madison
"""

from simnibs import run_simnibs, sim_struct

tdcs_lf = sim_struct.TDCSLEADFIELD()

# file handling
tdcs_lf.subpath = "m2m_101"  # subject directory
tdcs_lf.pathfem = "leadfield_element"  # output directory
tdcs_lf.eeg_cap = "EGI_template_reduced.csv"  # eeg-cap directory

# electrode configuration
electrode = tdcs_lf.electrode
electrode.dimensions = [8, 8]  # in mm
electrode.shape = "ellipse"  # shape
electrode.thickness = [4, 4]  # argu1 = gel thickness , argu2=e thickness

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
tdcs_lf.tissues =tissue_list

"""
You can uncomment to use the pardiso solver which is faster.
This solver is faster than the default. However, it requires much more memory (~12 GB)
However, do not use this for hd-EEG caps
"""

# tdcs_lf.solver_options = "pardiso"

run_simnibs(tdcs_lf)

