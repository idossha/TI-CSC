Partial TI-CSC Toolbox for docker image. See full toolbox at TI-2024 repo.
Developed and maintained by Ido Haber - ihaber@wisc.edu
last update: August 2024

---

Currently MATLAB Runtime and GUI functionality do not work on ARM base Apple machines. AMD/Intel should work smooth. Please ping if you encounter bugs.

---

#### How to use:

1. Make sure you have [docker Desktop](https://www.docker.com/products/docker-desktop/) / [docker engine](https://docs.docker.com/engine/install/) on you machine.
2. Download the [image](https://hub.docker.com/r/idossha/ti-package) from docker hub
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
Also, for optimization allocate more RAM to docker. Reccomanded >32GB.


4. open terminal and run the starter bash script.

`bash start_TI_docker.sh`


Potential troubleshooting:

* Make sure you have XQuartz or Xming if you are working on a Mac or Windows respectively. Linux should be fine out of the box.

* Might need to change the last line based on the specific tag you are using.

---

#### TIPS:

* In the main scripts all the automatic screenshot functions are commented out. If you wish to have those simply remove comments.

* It is highly recommended before re-executing analysis / optimization so clear or remove previous outputs. 


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


cheers







