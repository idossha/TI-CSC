

#!/bin/sh
# Script for execution of deployed applications
# Sets up the MATLAB Runtime environment for the current $ARCH and executes 
# the specified command.

# Function to find MATLAB Runtime
find_matlab_runtime() {
  local potential_paths=(
    "/Applications/MATLAB/MATLAB_Runtime/R2023b"
    "/usr/local/MATLAB/MATLAB_Runtime/R2023b"
    "/opt/MATLAB/MATLAB_Runtime/R2023b"
  )

  for path in "${potential_paths[@]}"; do
    if [ -d "$path" ]; then
      echo "$path"
      return 0
    fi
  done

  echo "MATLAB Runtime not found. Please install it or update the script with the correct path."
  exit 1
}

exe_name=$0
exe_dir=$(cd `dirname $0` && pwd)  # Get the absolute path of the script directory

echo "------------------------------------------"
if [ "x$1" = "x" ]; then
  echo "Usage:"
  echo "   $0 <mesh_dir>"
else
  echo "Setting up environment variables"
  MCRROOT=$(find_matlab_runtime)
  echo "MATLAB Runtime root: ${MCRROOT}"
  echo "------------------------------------------"

  DYLD_LIBRARY_PATH=.:${MCRROOT}/runtime/maca64
  DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MCRROOT}/bin/maca64
  DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MCRROOT}/sys/os/maca64
  DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${MCRROOT}/sys/java/jre/maca64/jre/lib/server
  export DYLD_LIBRARY_PATH

  echo "DYLD_LIBRARY_PATH is ${DYLD_LIBRARY_PATH}"
  echo "------------------------------------------"
  
  # Ensure mesh_dir is passed as the first argument
  mesh_dir="$1"
  if [ -z "$mesh_dir" ]; then
    echo "Error: mesh_dir is not specified."
    exit 1
  fi

  shift 1
  args=
  while [ $# -gt 0 ]; do
      token=$1
      args="${args} \"${token}\""
      shift
  done

  eval "\"${exe_dir}/process_mesh_files.app/Contents/MacOS/process_mesh_files\" \"$mesh_dir\" $args"
fi
exit

