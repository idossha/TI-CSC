### To-Do List

- [x] Figure out why MATLAB Runtime does not work on Apple Silicon.
- [ ] Develop a GUI solution for Apple Silicon.
- [ ] Improve placement for ROI & Montage JSONs.
- [ ] Create an in-house FSL image based on Ubuntu 20.04.
- [ ] Create an in-house Freesurfer image, version 7.4.1.
- [ ] Enhance optimizer prompting to behave similarly to the analyzer.
- [ ] Eliminate NVIM popups.
- [ ] Solve FSL GUI problem.
- [ ] Add ROI analysis for patches of the cortex using different atlases.
- [ ] Replace prompting in the pipeline with a GUI.


## [VERSION 1.1.0] - 2024-08-24

### Added
- MATLAB runtime now works on Apple silicon machines.

### Changed
- bash script to load image now changed from `start_TI_docker.sh` to `img-loader.sh`

#### Reference
- [WSL Issue #286 on GitHub](https://github.com/microsoft/WSL/issues/286) - Follow the `metorm` comment.
- Recompile MATLAB as suggested by `Shubham` in MATLAB Central.
