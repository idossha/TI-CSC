
#!/bin/bash

##############################################
# Ido Haber - ihaber@wisc.edu
# October 2, 2024
# Script to create spherical ROIs dynamically
#
# This script creates spherical regions of interest (ROIs) with a radius of 3 voxels 
# based on voxel coordinates provided as input. The output is a NIfTI file for each ROI.
##############################################

set -e  # Exit immediately if a command exits with a non-zero status

# Check if the required arguments are passed
if [ $# -lt 3 ]; then
    echo "Usage: $0 <project_base_dir> <subject_id> <roi_coordinates>"
    echo "Example: $0 /path/to/project sim_subjectID '95 73 127'"
    exit 1
fi

# Arguments
project_base=$1
subject_id=$2
roi_coordinates=$3  # This is the user-provided ROI coordinates (X Y Z) collected by start-ana.sh

# Set important directories
simulation_dir="${project_base}/Simulations/sim_${subject_id}"
nifti_dir="${simulation_dir}/niftis"

# Ensure output directory exists
mkdir -p "$nifti_dir"

# Input volume (e.g., an MNI152 template or subject-specific volume)
input_volume="${nifti_dir}/T1_${subject_id}_MNI.nii.gz"
if [ ! -f "$input_volume" ]; then
    echo "Error: Input volume $input_volume not found."
    exit 1
fi

# Output file
roi_output="${nifti_dir}/ROI-sphere.nii.gz"

# Split ROI coordinates into X, Y, Z
IFS=' ' read -r vx vy vz <<< "$roi_coordinates"

# Radius for the spherical ROI (3 voxels)
radius=3

# Initialize the output NIfTI file with zeros
fslmaths "$input_volume" -mul 0 "$roi_output" -odt float

# Create the spherical ROI
temp_sphere="temp_sphere.nii.gz"
fslmaths "$input_volume" -mul 0 -add 1 -roi "$vx" 1 "$vy" 1 "$vz" 1 0 1 temp_point.nii.gz -odt float
fslmaths temp_point.nii.gz -kernel sphere $radius -dilM -bin "$temp_sphere" -odt float

# Add the spherical ROI to the output volume
fslmaths "$roi_output" -add "$temp_sphere" "$roi_output" -odt float

# Clean up temporary files
rm -f temp_point.nii.gz "$temp_sphere"

echo "Sphere created for ROI at ($vx, $vy, $vz) and saved to $roi_output."

