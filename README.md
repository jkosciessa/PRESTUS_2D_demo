# **PRESTUS 2D benchmark example**

This directory contains simulations for 2D phantoms using [the development version of PRESTUS](https://github.com/Donders-Institute/PRESTUS/tree/development) (currently tracking v0.6.2-pre).

## Overview

This demo replicates a variant of the benchmarking setup from Aubry et al. (2022) using PRESTUS. It uses precomputed 2D tissue phantoms rather than real 3D MRI segmentations, so no SimNIBS installation is required. The main simulation script runs on CPU in MATLAB and produces acoustic and thermal simulation outputs for a single-element transducer focused through a layered phantom.

## Prerequisites

- MATLAB (tested with R2022b+)
- [k-Wave Toolbox](http://www.k-wave.org/) — place in `tools/PRESTUS/external/k-wave/`
- [FEX-minimize](https://www.mathworks.com/matlabcentral/fileexchange/24298) — place in `tools/PRESTUS/external/FEX-minimize/`

SimNIBS is **not** required for this demo.

## Installation

Clone with submodules (HTTPS):

```bash
git clone --recurse-submodules https://github.com/jkosciessa/PRESTUS_2D_demo.git
```

or via SSH:

```bash
git clone --recurse-submodules git@github.com:jkosciessa/PRESTUS_2D_demo.git
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init
```

## Workflow

1. Clone the repository including submodules (see above)
2. Place k-Wave and FEX-minimize inside `tools/PRESTUS/external/` (see Prerequisites)
3. Create the tissue benchmark phantoms:
   ```matlab
   run('tools/PRESTUS/examples/createPhantom.m')
   ```
4. Inspect configuration files if desired:
   - `data/configs/config_default.yaml` — default PRESTUS parameters
   - `data/configs/config_setup1.yaml` — setup-specific overrides
5. Run the simulation:
   ```matlab
   run('code/simulation.m')
   ```
   By default (`run_calibration = 0`) precomputed calibration values are used, so the simulation runs out of the box.
6. Inspect outputs in `data/tussim/setup1/sub-002/`

## Key script variables

| Variable | Default | Description |
|---|---|---|
| `run_calibration` | `0` | Run free-water calibration before phantom sim; `0` uses precomputed values |
| `interactive` | `1` | Show figures and pause dialogs; set `0` for unattended runs |
| `gui_launch` | `0` | Launch PRESTUS GUI instead of running directly |
| `intensities` | `[30]` | Free-water target intensity [W/cm²] |

## References

Aubry, J.-F. et al. Benchmark problems for transcranial ultrasound simulation: Intercomparison of compressional wave models. *J. Acoust. Soc. Am.* 152, 1003–1019 (2022).
