
#!/bin/bash

# Define the main directory path containing the sub-directories
# Each subdirectory should be a ppt containing anatomical data 
subjects_dir="/mnt/${PROJECT_DIR_NAME}/Subjects"

# Change to the main directory
cd "$subjects_dir"

# Loop over each sub-directory in the main directory (which should correspond to different subjects)
for subdir in */; do

  # Strip the trailing slash from subdir name (based on how your subject directories are named)
    subdir="${subdir%/}"

    # Extract the last three characters from the directory name
    x=${subdir: -3}

    # Define the paths for y and z (drop z if you are only using T1)
    y="/mnt/${PROJECT_DIR_NAME}/Subjects/${x}/sub-${x}_ses-base_acq-MPRAGE_T1w.nii.gz"
    z="/mnt/${PROJECT_DIR_NAME}/Subjects/${x}/sub-${x}_ses-base_acq-CUBE_T2w.nii.gz"

    # Run the command
    # qform is a rigid body transformation while sform is another option performing affine transformation.
    charm "$x" "$y" "$z" --forceqform
done
