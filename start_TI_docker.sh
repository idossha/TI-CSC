
#!/bin/bash

# Allow local root access to X server
xhost +local:root

# Display a note regarding processor compatibility
echo "Note: This pipeline is not fully ready for ARM processors (e.g., Apple Silicon). It is good for Intel/AMD processors."

# Prompt the user to input the path to the local project directory
echo "Give path to local project dir:"
read LOCAL_PROJECT_DIR

# Extract the project directory name from the provided path
PROJECT_DIR_NAME=$(basename "$LOCAL_PROJECT_DIR")

# Prompt the user to specify their operating system
echo "Are you running on Linux or macOS? (Enter 'Linux' or 'macOS'):"
read OS_TYPE

# Run the Docker container based on the user's OS
if [[ "$OS_TYPE" == "Linux" ]]; then
  docker run --rm -ti \
    -e DISPLAY=$DISPLAY \
    -e LIBGL_ALWAYS_SOFTWARE=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v "$LOCAL_PROJECT_DIR":/mnt/"$PROJECT_DIR_NAME" \
    idossha/ti-package:v1.0.1 bash -c "echo 'Your project was mounted to /mnt/$PROJECT_DIR_NAME' && bash" 
elif [[ "$OS_TYPE" == "macOS" ]]; then
  docker run --rm -ti \
    -e DISPLAY=$DISPLAY \
    -e DISPLAY=docker.for.mac.host.internal:0 \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -v "$LOCAL_PROJECT_DIR":/mnt/"$PROJECT_DIR_NAME" \
    idossha/ti-package:v1.0.2 bash -c "echo 'Your project was mounted to /mnt/$PROJECT_DIR_NAME' && bash" 
else
  echo "Unsupported OS type. Please enter 'Linux' or 'macOS'."
fi

# Revert X server access permissions
xhost -local:root

