
#!/bin/bash

# Create the ROI and opt directories if they don't exist
mkdir -p ROIs
mkdir -p opt

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

# Open the output.csv file
echo "Opening output.csv file..."
open opt/output.csv

bash mesh-selector.sh


echo "All tasks completed successfully."
