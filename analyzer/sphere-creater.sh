
#!/bin/bash

##############################################
# Ido Haber - ihaber@wisc.edu
# September 2, 2024
# Optimized for TI-CSC toolbox
#
# This script helps create spherical regions of interest (ROIs) with a specified radius 
# as NIfTI files for visualization purposes. The spheres are based on voxel coordinates 
# from an input NIfTI volume. The script combines these spheres into a single ROI volume 
# for easier visualization and overlays it on the original volume using Freeview.
#
# Modifications:
# - Takes input ROI from roi_list.json under the project directory /utils/roi_list.json
# - Takes the volume under project_dir/Subjects/m2m_subjectID/T1_subjectID_MNI.nii.gz
# - Outputs to project_dir/Simulation/sim_subjectID/niftis/
#
# Usage:
# ./scriptname.sh <project_base_directory> <subject_id>
##############################################

# Check for required arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <project_base_directory> <subject_id>"
    exit 1
fi

# Get arguments
project_base="$1"
subject_id="$2"

# Set up directories
utils_dir="$project_base/utils"
subject_dir="$project_base/Subjects/m2m_$subject_id"

# Volume file path
volume_file="$subject_dir/T1_${subject_id}_MNI.nii.gz"

# ROI file path
roi_file="$utils_dir/roi_list.json"

# Output directory
simulation_dir="$project_base/Simulations/sim_$subject_id"
output_dir="$simulation_dir/niftis/"
mkdir -p "$output_dir"

# Check if volume exists
if [ ! -f "$volume_file" ]; then
    echo "Volume file not found: $volume_file"
    exit 1
fi

# Check if roi_list.json exists
if [ ! -f "$roi_file" ]; then
    echo "ROI file not found: $roi_file"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq command not found. Please install jq."
    exit 1
fi

# Read ROIs into arrays
rois=$(jq -r '.ROIs | keys[]' "$roi_file")
locations=()
location_names=()

for roi_name in $rois; do
    coord=$(jq -r ".ROIs[\"$roi_name\"]" "$roi_file")
    locations+=("$coord")
    location_names+=("$roi_name")
done

# If no ROIs are found
if [ ${#locations[@]} -eq 0 ]; then
    echo "No ROIs found in $roi_file"
    exit 1
fi

# Radius for the spherical region (in voxels)
radius=3

# Initialize the combined ROI volume with zeros
combined_roi_file="${output_dir}/combined-spheres.nii.gz"
fslmaths "$volume_file" -mul 0 "$combined_roi_file" -odt float

# Create spherical ROIs and combine them into the combined ROI volume
for i in "${!locations[@]}"; do
  location="${locations[$i]}"
  location_name="${location_names[$i]}"

  IFS=' ' read -r vx vy vz <<< "$location"

  roi_file="${output_dir}/sphere_${location_name}.nii.gz"

  # Create the spherical ROI
  fslmaths "$volume_file" -mul 0 -add 1 -roi "$vx" 1 "$vy" 1 "$vz" 1 0 1 temp_point -odt float
  fslmaths temp_point -kernel sphere "$radius" -dilM -bin "$roi_file" -odt float

  # Add the spherical ROI to the combined volume
  fslmaths "$combined_roi_file" -add "$roi_file" "$combined_roi_file" -odt float

  # Delete the temporary spherical ROI file
  rm -f "$roi_file"
done

# Delete the temporary point file
rm -f temp_point.nii.gz

# Visualize the original volume and the combined spherical ROIs with Freeview
freeview -v "$volume_file":colormap=grayscale "$combined_roi_file":colormap=heat:opacity=0.4 &
