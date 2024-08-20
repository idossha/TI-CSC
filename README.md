Partial TI-CSC Toolbox for docker image. See full toolbox at TI-2024 repo.
Developed and maintained by Ido Haber - ihaber@wisc.edu
last update: August 19, 2024

---

Compatible with: Linux, Windows, macOS (intel)
Currently MATLAB Runtime and GUI functionality do not work on ARM architecture (Apple silicon). 
Please ping if you encounter bugs.

---

#### How to run docker image:

1. Make sure you have [docker Desktop](https://www.docker.com/products/docker-desktop/) / [docker engine](https://docs.docker.com/engine/install/) on you machine.
* If you are using macOS / Windows, make sure you have XQuartz or Xming available. Only necessary if you wish to have GUI. 
2. Pull the [image](https://hub.docker.com/r/idossha/ti-package) from docker hub. 
3. Make sure you have the project directory set up correctly:

        project_name 
            |___Simulations
            |
            |___Subjects
                   |___m2m_001
                   |___m2m_002
                   |___leadfield_001
                   |___leadfield_002


The leadfield is only necessary if you want to run optimization scripts.
Also, for optimization allocate more RAM to docker. Recommended >32GB.


4. open terminal and run the starter bash script.

`bash start_TI_docker.sh`

* If you are using Windows and you do not have bash available you can mannually run the docker command for Windows which can be found in the script above.

---

#### TIPS:

* In the main scripts all the automatic screenshot functions are commented out. If you wish to have those simply remove comments.
* It is highly recommended before re-executing analysis / optimization so clear or remove previous outputs. 
* Sometimes the MATLAB Runtimes yells, but still give the correct output.

---

#### The container has:
FSL 6.0.1
Freesurfer 7.1.1
SimNIBS 4.1.0
MATLAB Runtime r2024a
github repo with scripts

---

#### For rebuilding an updated image yourself:

1. Make sure you have docker engine / desktop on your machine.
2. Place all these files in the same edirectory.
3. put in the following command: `docker build --no-cache -t <repo_name>:<tag_name> .` 
4. Verify your image works locally.
5. Push to docker hub.

---

## Project Functionality:

This is a CLI that allows users to:
1. Optimize montages for Temporal Interference Stimulation.
2. Analyze and visualize unipolar and bipolar montages very efficiently. 

#### Analyzer Requirements:

1. Project directory containing `Subjects` subdirectory with `m2m_SubjectID` subdir.
3. Tensor file (only for anisotropic simulation)

**How to run:**

`bash start-ana.sh` and follow the prompts. 

If you run multiple consecutive analyses, it is highly recommended to move the previous `sim_SubjectName` elsewhere.

#### Optimizer Requirements:

1. Project directory containing `Subjects` subdirectory with `m2m_SubjectID` and `leadfield_SubjectID` subdirs.

**How to run:** 

* If you have not created leadfield matrix yet, run `simnibs_python leadfield.py` 
* Once leadfiled is created, run `bash start-opt.sh` and follow the prompts.

---

cheers







