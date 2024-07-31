
#!/usr/bin/env python3

import os
import re
import pandas as pd
import subprocess
import json
import csv
import shutil

# Directory paths
roi_directory = 'ROIs'
opt_directory = 'opt'

# Read the list of ROI files from roi_list.txt
with open('roi_list.txt', 'r') as file:
    position_files = [line.strip() for line in file]

# Create a dictionary to hold the data
mesh_data = {}

# Iterate over all .msh files in the opt directory
for msh_file in os.listdir(opt_directory):
    if msh_file.endswith('.msh'):
        msh_file_path = os.path.join(opt_directory, msh_file)
        print(f"Processing {msh_file_path}")
        mesh_data[msh_file_path] = {}

        # Iterate over all position files
        for pos_file in position_files:
            pos_base = os.path.splitext(os.path.basename(pos_file))[0]  # Extract the base name of the position file without extension
            print(f"  Using position file {pos_file}")
            # Run the command to generate CSV files in the opt directory
            try:
                subprocess.run(["get_fields_at_coordinates", "-s", pos_file, "-m", msh_file_path], check=True)
            except subprocess.CalledProcessError as e:
                print(f"Error running get_fields_at_coordinates: {e}")
                continue
            
            # Move the generated CSV file to the opt directory
            generated_csv_file = os.path.join(roi_directory, f"{pos_base}_TImax.csv")
            target_csv_file = os.path.join(opt_directory, f"{pos_base}_TImax.csv")
            
            if os.path.exists(generated_csv_file):
                shutil.move(generated_csv_file, target_csv_file)
            else:
                print(f"    CSV file {generated_csv_file} not found. Skipping this file.")
                continue
            
            # Extract parts of the mesh file name to construct the CSV file names
            parts = re.findall(r'E\d{3}_E\d{3}', msh_file_path)
            if len(parts) == 2:
                part1 = parts[0]
                part2 = parts[1]
                mesh_key = msh_file_path
                
                # Check if the file exists before reading
                if os.path.exists(target_csv_file):
                    try:
                        # Read the CSV file into a dataframe without headers
                        df3 = pd.read_csv(target_csv_file, header=None)
                        
                        # Ensure all data can be converted to float
                        df3 = df3.apply(pd.to_numeric, errors='coerce')
                        df3 = df3.dropna()  # Drop rows with non-numeric data
                        
                        # Extract values from the dataframe
                        ti_values = df3[0].tolist()  # Assuming the TImax CSV has values in the first column
                        
                        # Store the values in the dictionary
                        if pos_base not in mesh_data[mesh_key]:
                            mesh_data[mesh_key][pos_base] = {}
                        
                        mesh_data[mesh_key][pos_base] = ti_values
                        
                        # Delete the CSV file
                        os.remove(target_csv_file)
                    except Exception as e:
                        print(f"Error processing file {target_csv_file}: {e}")
                else:
                    print(f"    CSV file {target_csv_file} not found. Skipping this file.")
            else:
                print(f"    Could not extract required parts from {msh_file_path} using {pos_file}. Skipping this file.")

# Save the dictionary to a file for later use
json_output_path = os.path.join(opt_directory, 'mesh_data.json')
with open(json_output_path, 'w') as json_file:
    json.dump(mesh_data, json_file, indent=4)

print(f"Dictionary saved to {json_output_path}")

# Convert JSON to CSV
# Get all the ROI names (columns)
columns = set()
for mesh in mesh_data.values():
    for roi in mesh.keys():
        columns.add(roi)

# Convert set to sorted list for consistent ordering
columns = sorted(list(columns))

# Prepare the CSV data
csv_data = []
header = ['Mesh'] + columns
csv_data.append(header)

for mesh_name, rois in mesh_data.items():
    # Format the mesh name as "E076_E172 <> E097_E162"
    parts = re.findall(r'E\d{3}_E\d{3}', mesh_name)
    if len(parts) == 2:
        formatted_mesh_name = f"{parts[0]} <> {parts[1]}"
    else:
        formatted_mesh_name = mesh_name  # Fallback to the original name if the pattern doesn't match
    
    row = [formatted_mesh_name]
    for column in columns:
        if column in rois:
            ti = rois[column][0]  # Get the first TI value
            value = ti
        else:
            value = ''
        row.append(value)
    csv_data.append(row)

# Write to CSV file
csv_output_path = os.path.join(opt_directory, 'output.csv')
with open(csv_output_path, 'w', newline='') as file:
    writer = csv.writer(file)
    writer.writerows(csv_data)

print(f'CSV file created successfully at {csv_output_path}.')

