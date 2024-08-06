
#!/bin/bash

# Prompt the user for the project directory and subject name
read -p "Enter project directory (the default is /Users/idohaber/Desktop/strengthen): " project_dir
project_dir=${project_dir:-/Users/idohaber/Desktop/strengthen}

read -p "Enter subject name (e.g., 'beril'): " subject_name

# Call the ROI creator script
echo "Running roi-creator.py..."
python3 roi-creator.py

# Check if the ROI creation was successful
if [ $? -eq 0 ]; then
    echo "ROI creation completed successfully."
else
    echo "ROI creation failed. Exiting."
    exit 1
fi

# Set the leadfield_hdf path
leadfield_hdf="$project_dir/Subjects/leadfield_$subject_name/${subject_name}_leadfield_EGI_template.hdf5"
export LEADFIELD_HDF=$leadfield_hdf
export PROJECT_DIR=$project_dir
export SUBJECT_NAME=$subject_name

# Call the TI optimizer script
echo "Running ti-optimizer.py..."
simnibs_python ti-optimizer.py

# Check if the TI optimization was successful
if [ $? -eq 0 ]; then
    echo "TI optimization completed successfully."
else
    echo "TI optimization failed. Exiting."
    exit 1
fi

# Call the ROI analyzer script
echo "Running roi-analyzer.py..."
python3 roi-analyzer.py

# Check if the ROI analysis was successful
if [ $? -eq 0 ]; then
    echo "ROI analysis completed successfully."
else
    echo "ROI analysis failed. Exiting."
    exit 1
fi

# Set the correct path for the output.csv file
output_csv="$project_dir/Simulations/opt_$subject_name/output.csv"
echo "Opening $output_csv..."
open "$output_csv"

# List .msh files in the opt directory
msh_files=$(ls "$project_dir/Simulations/opt_$subject_name"/*.msh 2> /dev/null)
if [ -z "$msh_files" ]; then
    echo "No .msh files found in the opt directory."
else
    echo "Here are the .msh files in the opt directory:"
    echo "$msh_files"
fi

bash mesh-selector.sh

echo "All tasks completed successfully."

