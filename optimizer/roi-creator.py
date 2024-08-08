
import os
import csv

def create_directory(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)

def save_roi_to_csv(roi_name, coordinates, directory):
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
            coordinates = [float(coord) for coord in coordinates]
            return coordinates
    return []

def main():
    # Create the directory for saving ROIs if it does not exist
    roi_directory = 'ROIs'
    create_directory(roi_directory)
    
    # List to store the paths of generated CSV files
    roi_files = []
    
    # Get the number of ROIs to create or modify
    num_rois = int(input("How many ROIs to create/modify? "))
    
    # List existing ROIs
    existing_rois = list_existing_rois(roi_directory)
    
    # Display existing ROIs
    print("Existing ROIs:")
    for idx, roi in enumerate(existing_rois, start=1):
        print(f"{idx}. {roi}")
    print(f"{len(existing_rois) + 1}. Add new ROI")
    
    for i in range(1, num_rois + 1):
        while True:
            choice = int(input(f"Select an ROI to modify (1-{len(existing_rois) + 1}): "))
            if 1 <= choice <= len(existing_rois) + 1:
                break
            else:
                print("Invalid choice. Please try again.")
        
        if choice == len(existing_rois) + 1:
            while True:
                roi_name = input(f"Name of new ROI {i}: ")
                if " " in roi_name:
                    print("The name must be a single word. Please try again.")
                else:
                    break
            coordinates = []
        else:
            roi_name = existing_rois[choice - 1]
            coordinates = read_roi_coordinates(roi_name, roi_directory)
            print(f"Current coordinates for '{roi_name}': {coordinates}")
        
        if not coordinates:
            while True:
                coordinates = input(f"Coordinates for ROI '{roi_name}' (x y z): ").split()
                if len(coordinates) != 3 or not all(coord.replace('.', '', 1).replace('-', '', 1).isdigit() for coord in coordinates):
                    print("Please enter exactly three numbers separated by spaces. Example: -10.5 5 20.0")
                else:
                    coordinates = [float(coord) for coord in coordinates]
                    break
        
        roi_file = save_roi_to_csv(roi_name, coordinates, roi_directory)
        roi_files.append(roi_file)
    
    # Write the list of ROI files to a text file
    with open('roi_list.txt', 'w') as file:
        for roi_file in roi_files:
            file.write(f"{roi_file}\n")
    
    print(f"All ROIs have been saved in the '{roi_directory}' directory.")

if __name__ == "__main__":
    main()

