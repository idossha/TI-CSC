
#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Prompt for project base directory with a default value
read -p "Enter project directory (the default is /Users/idohaber/Desktop/strengthen): " project_dir
project_dir=${project_dir:-/Users/idohaber/Desktop/strengthen}
subject_dir="$project_dir/Subjects"

# Function to list available subjects
list_subjects() {
    subjects=()
    i=1
    for subject_path in "$subject_dir"/m2m_*; do
        if [ -d "$subject_path" ]; then
            subject_id=$(basename "$subject_path" | sed 's/m2m_//')
            subjects+=("$subject_id")
            echo "$i. $subject_id"
            ((i++))
        fi
    done
}

echo "Choose subjects:"
list_subjects

read -p "Enter the numbers of the subjects to analyze (comma-separated): " subject_choices
IFS=',' read -r -a selected_subjects <<< "$subject_choices"

# Get the current script directory
script_dir=$(pwd)

# Loop through selected subjects and run the pipeline
for subject_index in "${selected_subjects[@]}"; do
    subject_name="${subjects[$((subject_index-1))]}"

    # Call the ROI creator script
    echo "Running roi-creator.py for subject $subject_name..."
    python3 roi-creator.py

    # Check if the ROI creation was successful
    if [ $? -eq 0 ]; then
        echo "ROI creation completed successfully for subject $subject_name."
    else
        echo "ROI creation failed for subject $subject_name. Exiting."
        exit 1
    fi

    # Set the leadfield_hdf path
    leadfield_hdf="$project_dir/Subjects/leadfield_$subject_name/${subject_name}_leadfield_EGI_template.hdf5"
    export LEADFIELD_HDF=$leadfield_hdf
    export PROJECT_DIR=$project_dir
    export SUBJECT_NAME=$subject_name

    # Call the TI optimizer script
    echo "Running ti-optimizer.py for subject $subject_name..."
    simnibs_python ti-optimizer.py

    # Check if the TI optimization was successful
    if [ $? -eq 0 ]; then
        echo "TI optimization completed successfully for subject $subject_name."
    else
        echo "TI optimization failed for subject $subject_name. Exiting."
        exit 1
    fi

    # Call the ROI analyzer script
    echo "Running roi-analyzer.py for subject $subject_name..."
    python3 roi-analyzer.py

    # Check if the ROI analysis was successful
    if [ $? -eq 0 ]; then
        echo "ROI analysis completed successfully for subject $subject_name."
    else
        echo "ROI analysis failed for subject $subject_name. Exiting."
        exit 1
    fi

    # Define the mesh directory
    mesh_dir="$project_dir/Simulations/opt_$subject_name"

    # Run the process_mesh_files_new.sh script
    echo "Running process_mesh_files_new.sh for subject $subject_name..."
    ./field-analysis/run_process_mesh_files.sh "$mesh_dir"

    # Check if the mesh processing was successful
    if [ $? -eq 0 ]; then
        echo "Mesh processing completed successfully for subject $subject_name."
    else
        echo "Mesh processing failed for subject $subject_name. Exiting."
        exit 1
    fi

    # Run the Python script to update the output.csv file
    echo "Running update_output_csv.py for subject $subject_name..."
    python3 update_output_csv.py "$project_dir" "$subject_name"

    # Check if the Python script was successful
    if [ $? -eq 0 ]; then
        echo "Updated output.csv successfully for subject $subject_name."
    else
        echo "Failed to update output.csv for subject $subject_name. Exiting."
        exit 1
    fi

    # Set the correct path for the output.csv file
    output_csv="$mesh_dir/output.csv"
    echo "Opening $output_csv..."
    #open "$output_csv"

    # Run the mesh selector script
    bash mesh-selector.sh
done

echo "All tasks completed successfully for all selected subjects."

