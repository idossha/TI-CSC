
import os
import csv
import sys
import subprocess


'''
Ido Haber - ihaber@wisc.edu
September 2, 2024
Optimized for optimizer pipeline

This script manages the creation and modification of Regions of Interest (ROIs) for simulations. 
It allows users to select existing ROIs or add new ones, with the option to visualize the 
subject's T1-weighted MRI in Freeview before specifying ROI coordinates.

Key Features:
- Lists existing ROIs and provides an option to modify or add new ones.
- Invokes Freeview for visual reference when adding new ROIs.
- Saves ROI coordinates to a CSV file and maintains a list of all ROI files.
- Handles file permissions and directory creation as needed.
'''


def save_roi_to_csv(roi_name, coordinates, directory):
    if not os.path.exists(directory):
        os.makedirs(directory)
    file_path = os.path.join(directory, f"{roi_name}.csv")
    with open(file_path, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(coordinates)
    return file_path

def list_existing_rois(directory):
    existing_rois = []
    if os.path.exists(directory):
        for file_name in os.listdir(directory):
            if file_name.endswith('.csv'):
                existing_rois.append(file_name[:-4])
    return existing_rois

def read_roi_coordinates(roi_name, directory):
    file_path = os.path.join(directory, f"{roi_name}.csv")
    if os.path.exists(file_path):
        with open(file_path, mode='r') as file:
            reader = csv.reader(file)
            coordinates = next(reader)
            coordinates = [float(coord.strip()) for coord in coordinates]
            return coordinates
    return []

def call_view_nifti(roi_directory):
    # Assuming the script is in the same directory, you may need to adjust this path
    view_nifti_script = os.path.join(os.path.dirname(__file__), "view-nifti.sh")

    # Ensure the script has execute permissions
    subprocess.call(['chmod', '+x', view_nifti_script])

    # Extract project directory and subject name
    subject_name = os.path.basename(os.path.dirname(roi_directory)).replace('m2m_', '')
    project_dir = os.path.dirname(os.path.dirname(roi_directory))
    
    subprocess.call([view_nifti_script, project_dir, subject_name])

def main():
    # Check if the ROI directory is passed as an argument
    if len(sys.argv) < 2:
        print("Error: ROI directory path is required as an argument.")
        sys.exit(1)

    roi_directory = sys.argv[1]
    
    # List to store the paths of generated CSV files
    roi_files = []
    
    # List existing ROIs
    existing_rois = list_existing_rois(roi_directory)
    
    if existing_rois:
        # Display existing ROIs and option to add a new one
        print("Existing ROIs:")
        for idx, roi in enumerate(existing_rois, start=1):
            print(f"{idx}. {roi}")
        print(f"{len(existing_rois) + 1}. Add new ROI")
        
        while True:
            choice = int(input(f"Select an ROI to modify (1-{len(existing_rois) + 1}): "))
            if 1 <= choice <= len(existing_rois) + 1:
                break
            else:
                print("Invalid choice. Please try again.")
        
        if choice == len(existing_rois) + 1:
            # Call view-nifti.sh before adding a new ROI
            call_view_nifti(roi_directory)
            roi_name = input("Name of new ROI: ")
            coordinates = []
        else:
            roi_name = existing_rois[choice - 1]
            coordinates = read_roi_coordinates(roi_name, roi_directory)
            print(f"Current coordinates for '{roi_name}': {coordinates}")
        
        if not coordinates:
            coordinates = input(f"Enter RAS coordinates for ROI '{roi_name}' (x y z): ").split(',')
            coordinates = [float(coord.strip()) for coord in coordinates]
        
    else:
        # No existing ROIs, so call view-nifti.sh and then prompt to add a new one
        call_view_nifti(roi_directory)
        roi_name = input("Name of new ROI: ")
        coordinates = input(f"Enter RAS coordinates for ROI '{roi_name}' (x y z): ").split(',')
        coordinates = [float(coord.strip()) for coord in coordinates]
    
    # Save the ROI to a CSV file
    roi_file = save_roi_to_csv(roi_name, coordinates, roi_directory)
    roi_files.append(roi_file)
    
    # Write the list of ROI files to a text file
    roi_list_path = os.path.join(roi_directory, 'roi_list.txt')
    with open(roi_list_path, 'w') as file:
        for roi_file in roi_files:
            file.write(f"{roi_file}\n")
    
    print(f"ROI '{roi_name}' has been saved in the '{roi_directory}' directory.")
    # End the script after processing the single ROI
    return

if __name__ == "__main__":
    main()

