
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

def main():
    # Create the directory for saving ROIs if it does not exist
    roi_directory = 'ROIs'
    create_directory(roi_directory)
    
    # List to store the paths of generated CSV files
    roi_files = []
    
    # Get the number of ROIs
    num_rois = int(input("How many ROIs? "))
    
    for i in range(1, num_rois + 1):
        # Get the name and coordinates for each ROI
        while True:
            roi_name = input(f"Name of ROI {i}: ")
            if " " in roi_name:
                print("The name must be a single word. Please try again.")
            else:
                break
        
        while True:
            coordinates = input("x,y,z values: ").split()
            if len(coordinates) != 3 or not all(coord.replace('.', '', 1).replace('-', '', 1).isdigit() for coord in coordinates):
                print("Please enter exactly three numbers separated by spaces. Example: -10.5 5 20.0")
            else:
                # Convert the coordinates to floats
                coordinates = [float(coord) for coord in coordinates]
                break
        
        # Save the ROI data to a CSV file without a header
        roi_file = save_roi_to_csv(roi_name, coordinates, roi_directory)
        roi_files.append(roi_file)
    
    # Write the list of ROI files to a text file
    with open('roi_list.txt', 'w') as file:
        for roi_file in roi_files:
            file.write(f"{roi_file}\n")
    
    print(f"All ROIs have been saved in the '{roi_directory}' directory.")

if __name__ == "__main__":
    main()

