
# TI-CSC Toolbox for Docker Image

**Developed and maintained by Ido Haber - [ihaber@wisc.edu](mailto:ihaber@wisc.edu)**  
**Last update: August 20, 2024**

---

### Overview

The TI-CSC Toolbox is designed for researchers and engineers involved in Temporal Interference (TI) stimulation. This CLI-based toolbox facilitates the optimization of montages and the analysis of unipolar and bipolar montages. All dependencies are preinstalled & configured using docker, to facilitate easy of use and collaboration.

### Container Contents

The Docker container includes the following tools and libraries:

- **FSL** 6.0.1
- **Freesurfer** 7.1.1
- **SimNIBS** 4.1.0
- **MATLAB Runtime** r2024a
- Git repository with analysis and optimization scripts
- Commonly used CLI tools: VIM, NVIM, TMUX, Git, and more.

---

### Compatibility

- **Operating Systems:** Linux, Windows, macOS
- **Important Notes:**  
- **MATLAB Runtime and GUI functionality** do not currently work on ARM architecture (Apple silicon).  
- Please reach out if you encounter any bugs or issues.

---

### How to Run the Docker Container

1. **Ensure Docker is Installed:**
   - Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop) for macOS and Windows, or [Docker Engine](https://docs.docker.com/engine/install/) for Linux.

2. **Set Up XQuartz or Xming:**
   - For macOS: Install [XQuartz](https://www.xquartz.org/).
   - For Windows: Install [Xming](https://sourceforge.net/projects/xming/).
   - *Note: These are only necessary if you plan to use GUI functionality.*

3. **Pull the Docker Image:**
   - Use the following command to pull the image from Docker Hub:
     ```sh
     docker pull idossha/ti-package:vx.x.x
     ```
   - Replace `vx.x.x` with the version number you intend to use.

4. **Set Up Project Directory:**
   - Ensure your project directory follows this structure:
     ```
     project_name/
     ├── Simulations/
     └── Subjects/
         ├── m2m_001/
         └── m2m_002/
     ```

5. **Run the Docker Container:**
   - On Unix systems (Linux/macOS), use the provided starter bash script:
     ```sh
     bash start_TI_docker.sh
     ```
   - On Windows, if you do not have bash available, run the following command manually:
     ```sh
     docker run --rm -ti -e DISPLAY=host.docker.internal:0.0 -v C:\path\to\project_dir:/mnt/project_dir idossha/ti-package:vx.x.x
     ```
   - *Replace `C:\path\to\project_dir` with the actual path to your project directory on Windows.*

---

### Tips

- **Automatic Screenshots:**  
  If you wish to enable automatic screenshots in the main scripts, simply uncomment the relevant lines in the script files.

- **Clearing Previous Outputs:**  
  Before re-executing analysis or optimization, it is highly recommended to clear or remove previous outputs to avoid conflicts.

- **MATLAB Runtime Warnings:**  
  MATLAB Runtime may display warnings, but they generally do not affect the correctness of the output.

---

#### Analyzer Requirements:

1. A project directory containing the `Subjects` subdirectory with `m2m_SubjectID` directories.
2. A tensor file (required only for anisotropic simulation).

**How to Run:**

```sh
bash start-ana.sh
```

Follow the on-screen prompts.  
If running multiple consecutive analyses, move the previous `sim_SubjectID` directory elsewhere before starting a new one.

### Optimizer Requirements:
A project directory containing the `Subjects` subdirectory with `m2m_SubjectID` directories.

**How to Run:**

If you have not created the leadfield matrix yet, run:

```sh
simnibs_python leadfield.py
```

Ensure that the `leadfield_SubjectID` directory is created and populated next to `m2m_SubjectID`.

Once the leadfield is created, run:

```bash
bash start-opt.sh
```

Follow the on-screen prompts.  
For optimization, allocate more RAM to Docker. Recommended: >32GB.

### To-Do List

- [ ] Figure out why MATLAB Runtime does not work on Apple Silicon.
- [ ] Develop a GUI solution for Apple Silicon.
- [ ] Improve placement for ROI & Montage JSONs.
- [ ] Create an in-house FSL image based on Ubuntu 20.04.
- [ ] Create an in-house Freesurfer image, version 7.4.1.
- [ ] Enhance optimizer prompting to behave similarly to the analyzer.
- [ ] Eliminate NVIM popups.
- [ ] Solve FSL GUI problem.
- [ ] Add ROI analysis for patches of the cortex using different atlases.
- [ ] Replace prompting in the pipeline with a GUI.

### Documentation and Possible Solutions for MATLAB Runtime on Apple Silicon:

- [WSL Issue #286 on GitHub](https://github.com/microsoft/WSL/issues/286) - Follow the `metorm` comment.
- Recompile MATLAB as suggested by `Shubham` in MATLAB Central.

Cheers,  
Ido Haber
