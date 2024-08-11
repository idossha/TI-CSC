 linux development for docker
 Developed by Ido Haber - ihaber@wisc.edu
 August 2024

---

Currently MATLAB executables or GUI functionality does not work on ARM base Apple machines. 

---

#### How to use:

1. Make sure you have docker Desktop / docker engine on you machine.
2. Download the image from docker hub
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


4. open terminal and run the following command:

genreal form:
docker run -v /path/to/project_name:/mnt/project_name --rm -ti  image-name:tag

example:
docker run -v /home/idossha/Destkop/strengthe:/mnt/strengthen --rm -ti  package-compelte:update1

---

If you wish to run applications: SimNIBS, Freesurfer, Gmsh  with GUI addional steps are required:

1. Type the following command on your host machine: xhost +local:docker
2. Make sure you have XQuartz or Xming if you are working on a mac or windows respectively. Linux i xh xh xhost +local:docker
3. Run your docker command as follow (or put it in a bash script for easier execution):

docker run --rm -it \
    -e DISPLAY=$DISPLAY \
    -v /tmp/.11-unix/tmp/.X11-unix \
    -v /path/to/project:/mnt/project_name
    image_name:tag

ps might need to add also that: -e LIBGL_ALWAYS_INDIRECT=1

---

#### TIPS:

* In the main scripts all the automatic screenshot functions are commented out. If you wish to have those simply remove comments.

* It is highly recommended before re-executing analysis / optimization so clear or remove previous outputs. 


---

#### The container has:
FSL
Freesurfer 7.1.1
SimNIBS 4.1.0
MATLAB Runtime r2024a
github repo with scripts

---

cheers







