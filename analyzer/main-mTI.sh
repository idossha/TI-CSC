#!/bin/bash


#!/bin/bash

##############################################
# Ido Haber - ihaber@wisc.edu
# October 3, 2024
# Optimized for optimizer pipeline
#
# This script orchestrates the full workflow for Multi-Polar Temporal Interference (mTI) simulations 
# using SimNIBS and other related tools. It handles the entire process from simulation execution 
# to mesh processing, Grey Matter (GM) extraction, and NIfTI conversion. It includes safeguards to 
# ensure that each step completes successfully and allows for easy debugging.
#
# Key Features:
# - Runs mTI simulations based on selected montages.
# - Extracts and processes GM meshes, converting them to NIfTI format in MNI space.
# - Converts T1-weighted MRI to MNI space for accurate anatomical reference.
# - Provides mechanisms to handle errors at each stage of the pipeline.
# - Supports the generation of screenshots for visual inspection of results.
#
##############################################

set -e  # Exit immediately if a command exits with a non-zero status

# Gather arguments from the prompter script
subject_id=$1
conductivity=$2
subject_dir=$3
simulation_dir=$4
shift 4
selected_montages=("$@")

# Set the script directory to the present working directory
script_dir="$(pwd)"

# Set subdirectory paths
sim_dir="$simulation_dir/sim_${subject_id}"
fem_dir="$sim_dir/FEM"
whole_brain_mesh_dir="$sim_dir/Whole-Brain-mesh"
gm_mesh_dir="$sim_dir/GM_mesh"
nifti_dir="$sim_dir/niftis"
output_dir="$sim_dir/ROI_analysis"
screenshots_dir="$sim_dir/screenshots"
visualization_output_dir="$sim_dir/montage_imgs/" 

# Ensure directories exist
mkdir -p "$whole_brain_mesh_dir" "$gm_mesh_dir" "$nifti_dir" "$output_dir" "$screenshots_dir" "$visualization_output_dir"

# Main script: Run mTI.py with the selected parameters
run_mti_simulation() {
    local script_dir=$1
    local subject_id=$2
    local conductivity=$3
    local subject_dir=$4
    local simulation_dir=$5
    local selected_montages=("${@:6}")
    local mti_script_path="${script_dir}/mTI.py"
    echo "Running mTI simulation..."
    simnibs_python "$mti_script_path" "$subject_id" "$conductivity" "$subject_dir" "$simulation_dir" "${selected_montages[@]}"
    if [ $? -ne 0 ]; then
        echo "mTI simulation failed"
        exit 1
    fi
    echo "mTI simulation completed"
}

# Function to visualize montages
run_visualize_montages() {
    echo "Visualizing selected montages..."
    visualize_montage_script_path="$script_dir/visualize-montage.sh"
    bash "$visualize_montage_script_path" "${selected_montages[@]}" "$visualization_output_dir"
    echo "Montage visualization completed"
}

# Function to extract GM mesh
extract_gm_mesh() {
    local input_file="$1"
    local output_file="$2"
    echo "Extracting GM from $input_file..."
    gm_extract_script_path="$script_dir/gm_extract.py"
    simnibs_python "$gm_extract_script_path" "$input_file" --output_file "$output_file"
    if [ $? -ne 0 ]; then
        echo "GM extraction failed for $input_file"
        exit 1
    fi
    echo "GM extraction completed"
}

# Function to transform GM mesh to NIfTI
transform_gm_to_nifti() {
    echo "Transforming GM mesh to NIfTI in MNI space..."
    mesh2nii_script_path="$script_dir/mesh2nii_loop.sh"
    bash "$mesh2nii_script_path" "$subject_id" "$subject_dir" "$simulation_dir"
    echo "GM mesh to NIfTI transformation completed"
  }

# Function to convert T1 to MNI space
convert_t1_to_mni() {
  local t1_file="$subject_dir/m2m_${subject_id}/T1.nii.gz"
  local m2m_dir="$subject_dir/m2m_${subject_id}"
  local output_file="$subject_dir/m2m_${subject_id}/T1_${subject_id}"
  echo "Converting T1 to MNI space..."
  subject2mni -i "$t1_file" -m "$m2m_dir" -o "$output_file"
  echo "T1 conversion to MNI completed: $output_file"
}

# Function to process mesh files
process_mesh_files() {
    echo "Processing mesh files..."
    process_mesh_script_path="$script_dir/field-analysis/run_process_mesh_files.sh"
    bash "$process_mesh_script_path" "$whole_brain_mesh_dir"
    if [ $? -ne 0 ]; then
        echo "Mesh files processing failed"
        exit 1
    fi
    echo "Mesh files processed"
}

# Function to run sphere analysis
run_sphere_analysis() {
    echo "Running sphere analysis..."
    sphere_analysis_script_path="$script_dir/sphere-analysis.sh"
    bash "$sphere_analysis_script_path" "$subject_id" "$simulation_dir"
    if [ $? -ne 0 ]; then
        echo "Sphere analysis failed"
        exit 1
    fi
    echo "Sphere analysis completed"
}

# Function to generate screenshots
generate_screenshots() {
    local input_dir="$1"
    local output_dir="$2"
    echo "Generating screenshots..."
    screenshot_script_path="$script_dir/screenshot.sh"
    bash "$screenshot_script_path" "$input_dir" "$output_dir"
    if [ $? -ne 0 ]; then
        echo "Screenshot generation failed"
        exit 1
    fi
    echo "Screenshots generated"
}

# Run the main mTI simulation
run_mti_simulation "$script_dir" "$subject_id" "$conductivity" "$subject_dir" "$simulation_dir" "${selected_montages[@]}"

# # Move .msh files to the whole-brain-mesh directory
for ti_msh_file in "$fem_dir"/*.msh; do
    if [ -e "$ti_msh_file" ]; then
        new_name="${subject_id}_$(basename "$ti_msh_file")"
        new_path="$whole_brain_mesh_dir/$new_name"
        mv "$ti_msh_file" "$new_path"
        echo "Moved $ti_msh_file to $new_path"
    fi
done

# Extract GM from TI.msh
for mesh_file in "$whole_brain_mesh_dir"/*.msh; do
    output_file="$gm_mesh_dir/grey_$(basename "$mesh_file")"
    extract_gm_mesh "$mesh_file" "$output_file"
done

run_visualize_montages
transform_gm_to_nifti
convert_t1_to_mni
process_mesh_files
run_sphere_analysis
#generate_screenshots "$nifti_dir" "$screenshots_dir"

echo "All tasks completed successfully for subject ID: $subject_id"

