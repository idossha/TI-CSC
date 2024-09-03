
#!/bin/bash

##############################################
# Ido Haber - ihaber@wisc.edu
# September 2, 2024
# Optimized for optimizer pipeline
#
# This script transforms NIfTI files containing the normal component of the TI field 
# back into mesh (.msh) format and integrates it with the original mesh containing TI_max. 
# It then performs a cleanup of intermediate files to maintain an organized project directory.
##############################################


# Set up the project and subject directories
project_dir=$1
subject_name=$2

# Define directories
mesh_dir="$project_dir/Simulations/opt_$subject_name"
nifti_dir="$mesh_dir/niftis"

# Iterate over all volumetric NIfTI files in the nifti directory
for nifti_file in "$nifti_dir"/*_volumetric.nii.gz; do
    # Extract the base name from the nifti file (e.g., TI_norm_field_E003_E005_and_E007_E009)
    base_name=$(basename "$nifti_file" "_volumetric.nii.gz")
    
    # Modify base_name to match the correct mesh file pattern
    mesh_base_name=${base_name/TI_norm_field/TI_field}

    # Define the respective input mesh file
    input_mesh_file="$mesh_dir/${mesh_base_name}.msh"
    
    # Extract the part of the filename after "TI_field_" to use in the output name
    output_suffix=$(echo "$mesh_base_name" | sed 's/^TI_field_//')

    # Define the output mesh file name
    output_mesh_file="$mesh_dir/TI_max_norm_${output_suffix}.msh"

    # Check if the input mesh file exists
    if [ ! -f "$input_mesh_file" ]; then
        echo "Input mesh file $input_mesh_file not found. Skipping."
        continue
    fi

    # Run the nii2msh command
    echo "Running nii2msh $nifti_file $input_mesh_file $output_mesh_file"
    nii2msh "$nifti_file" "$input_mesh_file" "$output_mesh_file"

    # Check if the nii2msh command was successful
    if [ $? -eq 0 ]; then
        echo "Successfully converted $nifti_file to $output_mesh_file"
    else
        echo "Conversion failed for $nifti_file. Exiting."
        exit 1
    fi
done

echo "NIfTI to mesh conversion completed for subject $subject_name."

# Remove the nifti directory and its contents
if [ -d "$nifti_dir" ]; then
    echo "Deleting NIfTI directory and its contents: $nifti_dir"
    rm -rf "$nifti_dir"
else
    echo "NIfTI directory not found: $nifti_dir"
fi

# Remove all mesh & opt files starting with TI_field
echo "Deleting all mesh files starting with TI_field..."
rm -f "$mesh_dir"/TI_field_*.msh
rm -f "$mesh_dir"/TI_field_*.opt

# Remove all mesh & opt files starting with TI_norm
echo "Deleting all mesh files starting with TI_norm..."
rm -f "$mesh_dir"/TI_norm_field_*.msh
rm -f "$mesh_dir"/TI_norm_field_*.opt

echo "Cleanup completed for subject $subject_name."
