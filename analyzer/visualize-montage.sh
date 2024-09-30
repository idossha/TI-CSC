#!/bin/bash

# Define paths
project_base="/mnt/$PROJECT_DIR_NAME"
utils_dir="$project_base/utils"
montage_file="$utils_dir/montage_list.json"

# Check if the montage file exists
if [[ ! -f "$montage_file" ]]; then
    echo "Error: Montage file not found at: $montage_file"
    exit 1
fi

# Capture the selected montages passed as arguments
selected_montages=("${@:1:$(($#-1))}")  # All but the last argument
output_directory="${!#}"  # The last argument

# Create output directory if it doesn't exist
mkdir -p "$output_directory"

# Ring images for each pair (up to 8 pairs)
ring_images=("pair1ring.png" "pair2ring.png" "pair3ring.png" "pair4ring.png" "pair5ring.png" "pair6ring.png" "pair7ring.png" "pair8ring.png")

# Function to generate output filename based on electrode pairs
generate_output_filename() {
    local montage_name=$1
    echo "$output_directory/${montage_name}_highlighted_visualization.png"
}

# Function to overlay the ring for a pair of electrodes
overlay_rings() {
    local electrode_label=$1
    local ring_image=$2  # Use the passed ring image

    # Get modified coordinates for the current electrode label from the CSV
    coords=$(awk -F, -v label="$electrode_label" '$1 == label {print $3, $5}' "/ti-csc/assets/amv/electrodes.csv")
    if [ -z "$coords" ]; then
        echo "Warning: Coordinates not found for electrode '$electrode_label'. Skipping overlay."
        return
    fi

    # Read coordinates into variables
    IFS=' ' read -r x_adjusted y_adjusted <<< "$coords"

    # Use ImageMagick (magick) to overlay the ring image onto the output image at the specified coordinates
    magick "$output_image" "/ti-csc/assets/amv/$ring_image" -geometry +${x_adjusted}+${y_adjusted} -composite "$output_image" || {
        echo "Error: Failed to overlay ring image '$ring_image' onto output image '$output_image'."
    }
}

# Loop through the selected montages and process each
for montage in "${selected_montages[@]}"; do
    # Extract pairs from the JSON file
    pairs=$(jq -r ".uni_polar_montages[\"$montage\"][] | @csv" "$montage_file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to parse JSON for montage '$montage'. Please check the format."
        continue
    fi

    # Generate the output image filename for the current montage
    output_image=$(generate_output_filename "$montage")

    # Initialize output image to the template image (create only once for the montage)
    cp "/ti-csc/assets/amv/256template.png" "$output_image" || {
        echo "Error: Failed to copy template image to '$output_image'."
        continue
    }

    # Split the pairs and overlay the corresponding rings
    IFS=$'\n' # Set internal field separator to handle multiline input
    pair_index=0  # Keep track of which pair we're processing for ring image assignment
    for pair in $pairs; do
        # Remove quotes and split by comma
        pair=${pair//\"/}  # Remove quotes
        IFS=',' read -r -a electrodes <<< "$pair"  # Split into individual electrodes

        # Check if we got exactly 2 electrodes
        if [ ${#electrodes[@]} -ne 2 ]; then
            echo "Warning: Expected 2 electrodes, got ${#electrodes[@]}. Skipping pair: $pair."
            continue
        fi

        # Get the appropriate ring image based on the pair index
        ring_image=${ring_images[$pair_index % ${#ring_images[@]}]}  # Loop through the ring images

        # Overlay rings for each electrode in the current pair
        for electrode in "${electrodes[@]}"; do
            overlay_rings "$electrode" "$ring_image"
        done

        # Increment pair index for the next pair
        pair_index=$((pair_index + 1))
    done

    echo "Ring overlays for montage '$montage' completed. Output saved to $output_image."
done
