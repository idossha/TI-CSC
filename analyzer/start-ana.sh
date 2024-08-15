
#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Function to validate ROI input
validate_coordinates() {
    local coords=$1
    if [[ ! $coords =~ ^[0-9]+\ [0-9]+\ [0-9]+$ ]]; then
        echo "Invalid format. Please enter in the format X Y Z."
        return 1
    fi
    return 0
}

# Function to validate electrode pair input
validate_pair() {
    local pair=$1
    if [[ ! $pair =~ ^E[0-9]+,E[0-9]+$ ]]; then
        echo "Invalid format. Please enter in the format E1,E2."
        return 1
    fi
    return 0
}

# Prompt for project base directory with a default value
read -p "Enter the base directory of the project (default: /Users/idohaber/Desktop/strengthen): " project_base
project_base=${project_base:-/Users/idohaber/Desktop/strengthen}
subject_dir="$project_base/Subjects"
simulation_dir="$project_base/Simulations"

# List available subjects based on the project directory input
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

# Prompt for simulation type
echo "What type of simulation do you want to run?"
echo "1. Isotropic"
echo "2. Anisotropic"
read -p "Enter your choice (1 or 2): " sim_type

if [ "$sim_type" -eq 1 ]; then
    conductivity="scalar"
elif [ "$sim_type" -eq 2 ]; then
    anisotropic_selected=false
    while [ "$anisotropic_selected" = false ]; do
        echo "Which anisotropic type?"
        echo "1. vn"
        echo "2. dir"
        echo "3. mc"
        echo "4. Explain the difference"
        read -p "Enter your choice (1, 2, 3, or 4): " anisotropic_type

        if [ "$anisotropic_type" -eq 1 ]; then
            conductivity="vn"
            anisotropic_selected=true
        elif [ "$anisotropic_type" -eq 2 ]; then
            conductivity="dir"
            anisotropic_selected=true
        elif [ "$anisotropic_type" -eq 3 ]; then
            conductivity="mc"
            anisotropic_selected=true
        elif [ "$anisotropic_type" -eq 4 ]; then
            echo "Description: Type of conductivity values to use in gray and white matter."
            echo ""
            echo "'scalar': Isotropic, piecewise-constant conductivity values (default)"
            echo ""
            echo "'vn': Volume normalized anisotropic conductivities. In the volume normalization process, tensors are normalized to have the same trace and re-scaled according to their respective tissue conductivity (recommended for simulations with anisotropic conductivities, see Opitz et al., 2011)"
            echo ""
            echo "'dir': Direct anisotropic conductivity. Does not normalize individual tensors, but re-scales them accordingly to the mean gray and white matter conductivities (see Opitz et al., 2011)."
            echo ""
            echo "'mc': Isotropic, varying conductivities. Assigns to each voxel a conductivity value related to the volume of the tensors obtained from the direct approach (see Opitz et al., 2011)."
        else
            echo "Invalid choice. Please enter a valid option."
        fi
    done
else
    echo "Invalid choice. Exiting."
    exit 1
fi

# Prompt for simulation mode
read -p "Unipolar or Multipolar simulation? Enter U or M: " sim_mode

if [ "$sim_mode" == "U" ]; then
    montage_type="uni_polar_montages"
    main_script="main-TI.sh"
elif [ "$sim_mode" == "M" ]; then
    montage_type="multi_polar_montages"
    main_script="main-mTI.sh"
else
    echo "Invalid choice. Exiting."
    exit 1
fi

# Function to prompt and select montages
prompt_montages() {
    while true; do
        # Load montages from JSON file using jq
        montages=$(jq -r ".${montage_type} | keys[]" montage_list.json)

        echo "Available montages:"
        montage_array=($montages)
        half_count=$(( (${#montage_array[@]} + 1) / 2 ))

        for (( i=0; i<half_count; i++ )); do
            left="${montage_array[$i]}"
            right="${montage_array[$((i + half_count))]}"
            printf "%2d. %-20s" $((i + 1)) "$left"
            if [ -n "$right" ]; then
                printf "%2d. %s" $((i + 1 + half_count)) "$right"
            fi
            printf "\n"
        done

        echo "$(( ${#montage_array[@]} + 1 )). Wish to add a new montage?"

        read -p "Enter the numbers of the montages to simulate (comma-separated): " montage_choices

        # Convert user input into an array of selected montages
        IFS=',' read -r -a selected_numbers <<< "$montage_choices"
        selected_montages=()
        new_montage_added=false

        for number in "${selected_numbers[@]}"; do
            if [ "$number" -eq "$(( ${#montage_array[@]} + 1 ))" ]; then
                read -p "Enter a name for the new montage: " new_montage_name
                if [ "$sim_mode" == "U" ]; then
                    valid=false
                    until $valid; do
                        read -p "Enter Pair 1 (format: E1,E2): " pair1
                        validate_pair "$pair1" && valid=true
                    done
                    valid=false
                    until $valid; do
                        read -p "Enter Pair 2 (format: E1,E2): " pair2
                        validate_pair "$pair2" && valid=true
                    done
                    new_montage=$(jq -n --arg name "$new_montage_name" --argjson pairs "[[\"${pair1//,/\",\"}\"], [\"${pair2//,/\",\"}\"]]" '{($name): $pairs}')
                    jq ".${montage_type} += $new_montage" montage_list.json > temp.json && mv temp.json montage_list.json
                elif [ "$sim_mode" == "M" ]; then
                    valid=false
                    until $valid; do
                        read -p "Enter Pair 1a (format: E1,E2): " pair1a
                        validate_pair "$pair1a" && valid=true
                    done
                    valid=false
                    until $valid; do
                        read -p "Enter Pair 2a (format: E1,E2): " pair2a
                        validate_pair "$pair2a" && valid=true
                    done
                    valid=false
                    until $valid; do
                        read -p "Enter Pair 1b (format: E1,E2): " pair1b
                        validate_pair "$pair1b" && valid=true
                    done
                    valid=false
                    until $valid; do
                        read -p "Enter Pair 2b (format: E1,E2): " pair2b
                        validate_pair "$pair2b" && valid=true
                    done
                    new_montage=$(jq -n --arg name "$new_montage_name" --argjson pairs_a "[[\"${pair1a//,/\",\"}\"], [\"${pair2a//,/\",\"}\"]]" --argjson pairs_b "[[\"${pair1b//,/\",\"}\"], [\"${pair2b//,/\",\"}\"]]" '{($name + "_1"): $pairs_a, ($name + "_2"): $pairs_b}')
                    jq ".${montage_type} += $new_montage" montage_list.json > temp.json && mv temp.json montage_list.json
                fi
                new_montage_added=true
                break  # Re-prompt the user with the updated montage list
            else
                selected_montage=$(echo "$montages" | sed -n "${number}p")
                if [ -n "$selected_montage" ]; then
                    selected_montages+=("$selected_montage")
                else
                    echo "Invalid montage number: $number. Exiting."
                    exit 1
                fi
            fi
        done

        if ! $new_montage_added; then
            break  # Exit the loop if no new montage was added
        fi
    done
}

# Function to prompt and select ROIs
prompt_rois() {
    while true; do
        # Load ROIs from JSON file
        roi_file="roi_list.json"
        rois=$(jq -r '.ROIs | keys[]' "$roi_file")

        echo "Available ROIs:"
        roi_array=($rois)
        for (( i=0; i<${#roi_array[@]}; i++ )); do
            echo "$((i+1)). ${roi_array[$i]}"
        done

        echo "$(( ${#roi_array[@]} + 1 )). Add a new ROI"

        read -p "Enter the numbers of the ROIs to analyze (comma-separated): " roi_choices

        IFS=',' read -r -a selected_rois <<< "$roi_choices"
        selected_roi_names=()
        new_roi_added=false

        for roi in "${selected_rois[@]}"; do
            if [ "$roi" -eq "$(( ${#roi_array[@]} + 1 ))" ]; then
                read -p "Enter new ROI name: " new_roi_name
                valid=false
                until $valid; do
                    read -p "Enter Voxel Coordinates (format: X Y Z): " new_coordinates
                    validate_coordinates "$new_coordinates" && valid=true
                done
                jq ".ROIs[\"$new_roi_name\"]=\"$new_coordinates\"" "$roi_file" > temp.json && mv temp.json "$roi_file"
                new_roi_added=true
                break  # Re-prompt the user with the updated ROI list
            else
                roi_name=$(echo "$rois" | sed -n "${roi}p")
                if [ -n "$roi_name" ]; then
                    selected_roi_names+=("$roi_name")
                else
                    echo "Invalid ROI number: $roi. Exiting."
                    exit 1
                fi
            fi
        done

        if ! $new_roi_added; then
            break  # Exit the loop if no new ROI was added
        fi
    done
}

# Prompt the user to select montages
prompt_montages

# Prompt the user to select ROIs
prompt_rois

# Loop through selected subjects and run the pipeline
for subject_index in "${selected_subjects[@]}"; do
    subject_id="${subjects[$((subject_index-1))]}"

    # Call the appropriate main pipeline script with the gathered parameters
    ./"$main_script" "$subject_id" "$conductivity" "$subject_dir" "$simulation_dir" "${selected_montages[@]}"

    # Call sphere-analysis.sh with the selected ROIs
    ./sphere-analysis.sh "$subject_id" "$simulation_dir" "${selected_roi_names[@]}"
done

if $new_montage_added; then
    echo "New montage added to montage_list.json."
fi

if $new_roi_added; then
    echo "New ROI added to roi_list.json."
fi

