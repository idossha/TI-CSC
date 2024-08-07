Ido Haber
SimNIBS-TI Pipeline
July 2024

---

This is a CLI that allows users to:
1. Optimize montages for Temporal Interference Stimulation.
2. Analyze and visualize unipolar and bipolar montages very efficiently. 

Docker prooved to be highly complicated for this project, so for the meantime, Conda will be used.

---

#### Requirements:

1. Download and install SimNIBS & FSL (Gmsh and Freesurfer come automatically with SimNIBS)
2. Clone repo
3. Create conda enviroment from helper/enviroment.yml
4. Move subject subdirs to Project_name/Subjects/ (feel free to change name or path of Project_Name)
5. It is recomanded to `source` or restrat terminal after big updates/downloads to make changes effective.

**Enjoy!**

p.s. Of course further requirements are necessary, but these will be typical to any CL user. ie git, conda, etc. 

#### Important conda commands:

conda env create -f environment.yml : creating your environment
conda activate myenv                : activate it
conda deactivate                    : deactivate it
conda env list                      : list all envs in your system
conda install package_name          : install another package to active env
conda list                          : list packages of active env
conda env export > environment.yml  : export packages of active env to a yml file

---

# Analyzer

Required:

1. Project directory containing `Subjects` subdirectory with `m2m_SubjectName` subdirs.
2. EGI cap named `EEG_template.csv` (can use bs2sn.py for conversion)
3. tensor file (only for anisotropic simulation)

How to run:

`bash start-ana.sh` and follow the prompts.

If you run multiple conscutive analyses, it is recommended to move the previous `sim_SubjectName` elsewhere.


---

# Optimizer

Required:

1. Project directory containing `Subjects` subdirectory with `m2m_SubjectName` subdirs.
2. `leadfield_SubjectName` directory in `Subjects`

How to run:

`bash start-opt.sh` and follow the prompts.

---

Cheers!
