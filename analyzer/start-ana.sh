
#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Function to validate pair input
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

# Prompt for subject ID
read -p "Enter Subject ID: " subject_id
echo "Subject ID: $subject_id"

# Prompt for type of simulation
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
        read -p "Want to simulate the new montage? (yes/no): " simulate_new
        if [ "$simulate_new" == "yes" ]; then
            if [ "$sim_mode" == "U" ]; then
                selected_montages+=("$new_montage_name")
            elif [ "$sim_mode" == "M" ]; then
                selected_montages+=("${new_montage_name}_1" "${new_montage_name}_2")
            fi
        fi
        new_montage_added=true
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

# Call the appropriate main pipeline script with the gathered parameters
./"$main_script" "$subject_id" "$conductivity" "$subject_dir" "$simulation_dir" "${selected_montages[@]}"

if $new_montage_added; then
    echo "New montage added to montage_list.json."
fi

