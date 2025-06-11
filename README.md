# **PRESTUS 2D benchmark example**

This directory contains simulations for 2D phantoms using [PRESTUS v0.4](https://github.com/Donders-Institute/PRESTUS/releases/tag/v0.4.0).

## Installation

You may want to clone this repository in addition to the subtoolboxes (i.e. the PRESTUS code) using the following command:

```
git clone --recurse-submodules https://github.com/jkosciessa/PRESTUS_2D_demo.git
```

of if you have your SSH keys deposited on GitHub:

```
git clone --recurse-submodules git@github.com:jkosciessa/PRESTUS_2D_demo.git
```

## Workflow

This simple demo is intended to give you an impression of the inputs and outputs for the use of PRESTUS. We will neither simulate a complex 3D head with differentiated tissue, nor set up complex transducers. Instead, we will conceptually try to replicate a variant of the benchmarking setup reported by Aubry et al. (2022).

1. Create the tissue benchmark pantoms using ```PRESTUS/examples/createPhantom.m```; inspect the resulting images in ```/data/simnibs/m2m_sub-001/final_tissues.nii.gz```.
2. Inspect the configuration files: ```PRESTUS_2D_demo/data/configs/default_config.yaml``` and ```config_setup1.yaml```
3. Install SimNIBS
4. Run the simulation script: ```PRESTUS_2D_demo/code/simulations```
5. Inspect the outputs

## References

Aubry, J.-F. et al. Benchmark problems for transcranial ultrasound simulation: Intercomparison of compressional wave modelsa). J. Acoust. Soc. Am. 152, 1003–1019 (2022). 