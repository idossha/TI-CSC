# linux development for docker
# Developed by Ido Haber - ihaber@wisc.edu
# August 2024
# 

---

How to use:

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

Some of the functions are commented out because they require GUI functionality.
If you work locally / add necessary packages, remove # and it should work smooth.

---

the container has:
FSL
Freesurfer 7.1.1
SimNIBS 4.1.0
MATLAB Runtime r2024a
github repo with scripts

---

cheers







