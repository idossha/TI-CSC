

import os
import subprocess
import argparse
import time
import glob

def run_ti_simulation(script_dir):
    # Run the TI.py script
    print("Running TI simulation...")
    ti_script_path = os.path.join(script_dir, "TI.py")
    start_time = time.time()
    result = subprocess.run(["simnibs_python", ti_script_path])
    end_time = time.time()
    if result.returncode != 0:
        raise RuntimeError("TI simulation failed")
    print(f"TI simulation completed in {end_time - start_time:.2f} seconds")

def extract_gm_mesh(script_dir, input_file, output_file):
    # Run the gm_extract.py script
    print(f"Extracting GM from {input_file}...")
    gm_extract_script_path = os.path.join(script_dir, "gm_extract.py")
    cmd = ["simnibs_python", gm_extract_script_path, input_file, "--output_file", output_file]
    start_time = time.time()
    result = subprocess.run(cmd)
    end_time = time.time()
    if result.returncode != 0:
        raise RuntimeError(f"GM extraction failed for {input_file}")
    print(f"GM extraction completed in {end_time - start_time:.2f} seconds")

def transform_gm_to_nifti(script_dir, gm_mesh_dir):
    # Run the mesh2nii_loop.sh script
    print("Transforming GM mesh to NIfTI in MNI space...")
    mesh2nii_script_path = os.path.join(script_dir, "mesh2nii_loop.sh")
    start_time = time.time()
    result = subprocess.run(["bash", mesh2nii_script_path])
    end_time = time.time()
    if result.returncode != 0:
        raise RuntimeError("GM mesh to NIfTI transformation failed")
    print(f"GM mesh to NIfTI transformation completed in {end_time - start_time:.2f} seconds")

def process_mesh_files(script_dir, whole_brain_mesh_dir):
    # Run the process_mesh_files.sh script
    print("Processing mesh files...")
    process_mesh_script_path = os.path.join(script_dir, "field-analysis", "process_mesh_files.sh")
    start_time = time.time()
    result = subprocess.run(["bash", process_mesh_script_path, whole_brain_mesh_dir])
    end_time = time.time()
    if result.returncode != 0:
        raise RuntimeError("Processing mesh files failed")
    print(f"Mesh files processed in {end_time - start_time:.2f} seconds")

def run_sphere_analysis(script_dir, nifti_dir, output_dir):
    # Run the sphere-analysis.sh script
    print("Running sphere analysis...")
    sphere_analysis_script_path = os.path.join(script_dir, "sphere-analysis.sh")
    start_time = time.time()
    result = subprocess.run(["bash", sphere_analysis_script_path, nifti_dir, output_dir])
    end_time = time.time()
    if result.returncode != 0:
        raise RuntimeError("Sphere analysis failed")
    print(f"Sphere analysis completed in {end_time - start_time:.2f} seconds")

def generate_screenshots(script_dir, input_dir, output_dir):
    # Run the screenshot.sh script
    print("Generating screenshots...")
    screenshot_script_path = os.path.join(script_dir, "screenshot.sh")
    start_time = time.time()
    result = subprocess.run(["bash", screenshot_script_path, input_dir, output_dir])
    end_time = time.time()
    if result.returncode != 0:
        raise RuntimeError("Screenshot generation failed")
    print(f"Screenshots generated in {end_time - start_time:.2f} seconds")

def main(m2m_path, script_dir):
    # Ensure we are using absolute paths
    m2m_path = os.path.abspath(m2m_path)
    script_dir = os.path.abspath(script_dir)
    sim_dir = os.path.join(script_dir, "Simulations")
    gm_mesh_dir = os.path.join(script_dir, "GM_mesh")
    whole_brain_mesh_dir = os.path.join(script_dir, "Whole-Brain-mesh")
    niftis_dir = os.path.join(script_dir, "niftis")
    roi_analysis_dir = os.path.join(script_dir, "ROI_analysis")
    screenshots_dir = os.path.join(script_dir, "screenshots")

    # Ensure the mesh, niftis, ROI analysis, and screenshots directories exist
    os.makedirs(gm_mesh_dir, exist_ok=True)
    os.makedirs(whole_brain_mesh_dir, exist_ok=True)
    os.makedirs(niftis_dir, exist_ok=True)
    os.makedirs(roi_analysis_dir, exist_ok=True)
    os.makedirs(screenshots_dir, exist_ok=True)

    # Run TI simulation
    #run_ti_simulation(script_dir)
    
    # Extract GM from TI_vectors.msh
    for subdir in os.listdir(sim_dir):
        subdir_path = os.path.join(sim_dir, subdir)
        if os.path.isdir(subdir_path):
            mesh_files = glob.glob(os.path.join(subdir_path, "TI.msh"))
            for mesh_file in mesh_files:
                if os.path.exists(mesh_file):
                    output_file = os.path.join(gm_mesh_dir, f"grey_{subdir}.msh")
                    extract_gm_mesh(script_dir, mesh_file, output_file)
                    # Rename and move TI_vectors.msh to Whole-Brain-mesh directory
                    new_name = f"{subdir}_TI.msh"
                    new_path = os.path.join(whole_brain_mesh_dir, new_name)
                    os.rename(mesh_file, new_path)

    # Transform GM mesh to NIfTI in MNI space
    #transform_gm_to_nifti(script_dir, gm_mesh_dir)
    
    # Process mesh files
    #process_mesh_files(script_dir, whole_brain_mesh_dir)
    
    # Run sphere analysis on NIfTI files
    #run_sphere_analysis(script_dir, niftis_dir, roi_analysis_dir)
    
    # Generate screenshots
    generate_screenshots(script_dir, niftis_dir, screenshots_dir)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run the full simulation pipeline.')
    parser.add_argument('m2m_path', type=str, help='Path to the m2m directory')
    parser.add_argument('script_dir', type=str, help='Path to the directory containing the scripts')
    args = parser.parse_args()
    main(args.m2m_path, args.script_dir)

