# **PRESTUS 2D benchmark example**

This directory contains simulations for 2D phantoms using [PRESTUS v0.4](https://github.com/Donders-Institute/PRESTUS/releases/tag/v0.4.0).

1. Create the benchmark data:
    1a. Generate the phantoms using ```PRESTUS/examples/createPhantom.m```
    1b. ```gzip``` benchmark1.nii, and rename it to ```PRESTUS_2D_demo/data/simnibs/m2m_sub-001/final_tissues.nii.gz```
2. Inspect the configuration files: ```PRESTUS_2D_demo/data/configs/default_config.yaml``` and ```config_setup1.yaml```
3. Install SimNIBS
4. Run the simulation script: ```PRESTUS_2D_demo/code/simulations```
5. Inspect the outputs