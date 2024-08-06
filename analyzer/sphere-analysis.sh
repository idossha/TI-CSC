
#!/bin/bash

# Get the subject ID and simulation directory from the command-line arguments
subject_id="$1"
simulation_dir="$2"

# Debug: Print received arguments
echo "Debug: subject_id=$subject_id"
echo "Debug: simulation_dir=$simulation_dir"

# Set the designated directory for NIfTI files
nifti_dir="$simulation_dir/sim_${subject_id}/niftis"
echo "Debug: nifti_dir=$nifti_dir"

# Output directory setup
output_dir="$simulation_dir/sim_${subject_id}/ROI_analysis"
echo "Debug: output_dir=$output_dir"
mkdir -p "$output_dir"

# Voxel coordinates to check
locations=(
  "95 73 127"
  "95 56 116"
  "95 79 89"
  "101 101 81"
)

# Location names
location_names=(
  "Anterior"
  "Posterior"
  "RSC"
  "thalamus"
)

# Radius for the spherical region (in voxels)
radius=3

# Output file setup
output_file="$output_dir/mean_max_values.txt"
echo "Voxel Coordinates and Corresponding Mean and Max Values for Each Volume (Sphere Radius: $radius voxels)" > "$output_file"

# Loop through locations and volumes
declare -A mean_values

for i in "${!locations[@]}"; do
  location="${locations[$i]}"
  location_name="${location_names[$i]}"
  echo "" >> "$output_file"
  echo "Voxel Coordinates: ${location} (${location_name})" >> "$output_file"

  for volume_file in "$nifti_dir"/*.nii*; do
    volume_name=$(basename "$volume_file" .nii)

    echo "Processing volume: $volume_file at location: $location" >> "$output_file"

    # Use fslmaths to create a spherical mask around the voxel coordinates and extract the mean value
    IFS=' ' read -r vx vy vz <<< "$location"
    temp_sphere="temp_sphere_${volume_name}_${location_name}.nii.gz"
    temp_sphere_masked="temp_sphere_masked_${volume_name}_${location_name}.nii.gz"

    # Create the spherical ROI and mask out zero values
    fslmaths "$volume_file" -mul 0 -add 1 -roi "$vx" 1 "$vy" 1 "$vz" 1 0 1 temp_point -odt float
    fslmaths temp_point -kernel sphere "$radius" -dilM -bin "$temp_sphere" -odt float
    fslmaths "$volume_file" -mas "$temp_sphere" "$temp_sphere_masked"

    # Calculate the mean and max values, ignoring zeros
    mean_value=$(fslstats "$temp_sphere_masked" -M -l 0.0001)
    max_value=$(fslstats "$temp_sphere_masked" -R | awk '{print $2}')

    if [ -z "$mean_value" ]; then
      echo "Error extracting mean value for ${volume_file} at ${location}" >> "$output_file"
      continue
    fi

    # Store the mean value in an associative array for differential calculation
    mean_values["${volume_name}_${location_name}"]=$mean_value

    # Append the mean and max values to the output file
    echo "Extracted mean value: $mean_value" >> "$output_file"
    echo "Extracted max value: $max_value" >> "$output_file"
    echo "${volume_name}: mean=$mean_value, max=$max_value" >> "$output_file"

    # Clean up the temporary files
    rm -f temp_point.nii.gz "$temp_sphere" "$temp_sphere_masked"
  done
done

# Calculate and output differential values
echo "" >> "$output_file"
echo "Differential Mean Values between Anterior and Posterior Locations:" >> "$output_file"

for volume_file in "$nifti_dir"/*.nii*; do
  volume_name=$(basename "$volume_file" .nii)
  mean_anterior=${mean_values["${volume_name}_Anterior"]}
  mean_posterior=${mean_values["${volume_name}_Posterior"]}
  
  if [ -n "$mean_anterior" ] && [ -n "$mean_posterior" ]; then
    differential_value=$(echo "$mean_anterior - $mean_posterior" | bc)
    absolute_differential_value=$(echo "$differential_value" | awk '{if ($1<0) print -1*$1; else print $1}')
    echo "${volume_name} = ${absolute_differential_value}" >> "$output_file"
  else
    echo "Error: Missing mean value for ${volume_name} at Anterior or Posterior location" >> "$output_file"
  fi
done

