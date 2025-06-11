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

1. Clone repository (with submodules; see above)
2. Create tissue benchmark pantoms using ```./tools/PRESTUS/examples/createPhantom.m```
3. [Optional] Inspect benchmark images: ```./data/simnibs/m2m_sub-<XXX>/final_tissues.nii.gz```.
4. [Optional] Inspect configuration files: ```./data/configs/default_config.yaml``` and ```./data/configs/config_setup1.yaml```
5. Install SimNIBS (and specify ```parameters.simnibs_bin_path``` in config/script)
6. Run simulation script: ```./code/simulations```
7. Inspect outputs

## References

Aubry, J.-F. et al. Benchmark problems for transcranial ultrasound simulation: Intercomparison of compressional wave modelsa). J. Acoust. Soc. Am. 152, 1003–1019 (2022). 