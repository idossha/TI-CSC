### To-Do List in order of importance

- [x] Figure out why MATLAB Runtime does not work on Apple Silicon.
- [ ] Enhance optimizer prompting to behave similarly to the analyzer.
- [ ] Automatic montage visualization.
    1. create a subdirectory called: `Presentation_material` 
    2. have an image of the net with the montage marked with the channels
    3. name and title should correspond to montage+subject_name
- [ ] Develop a GUI solution for Apple Silicon.
- [ ] Improve placement for ROI & Montage JSONs.
- [ ] Add ROI analysis for patches of the cortex using different atlases.
- [ ] Solve FSL GUI problem.
- [ ] Create an in-house FSL image based on Ubuntu 20.04.
- [ ] Create an in-house Freesurfer image, version 7.4.1.
- [ ] Eliminate NVIM popups.
- [ ] Create a GUI for the Application


---

## [VERSION 1.1.0] - 2024-08-24

### Added
- MATLAB runtime now works on Apple silicon machines.

### Changed
- bash script to load image now changed from `start_TI_docker.sh` to `img-loader.sh`

#### Reference
- [WSL Issue #286 on GitHub](https://github.com/microsoft/WSL/issues/286) - Follow the `metorm` comment.
- Recompile MATLAB as suggested by `Shubham` in MATLAB Central.

---
