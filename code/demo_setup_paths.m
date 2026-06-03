function pn = demo_setup_paths(rootpath)
% Initialize PRESTUS 2D demo toolbox paths and add them to the MATLAB path.
%
% Input:
%   rootpath - root directory of the PRESTUS_2D_demo project

% Normalize /project/ alias on macOS
if ismac
    rootpath = strrep(rootpath, '/project/', '/Volumes/');
end

pn.prestus     = fullfile(rootpath, 'tools', 'PRESTUS');
pn.prestus_fun = fullfile(pn.prestus, 'functions');
pn.prestus_ext = fullfile(pn.prestus, 'external');
pn.kwave       = fullfile(pn.prestus_ext, 'k-wave', 'k-Wave');
pn.minimize    = fullfile(pn.prestus_ext, 'FEX-minimize');
pn.configs     = fullfile(rootpath, 'data', 'configs');
pn.data_seg    = fullfile(rootpath, 'data', 'simnibs');
pn.calibration = fullfile(rootpath, 'data', 'calibration');
pn.code        = fullfile(rootpath, 'code');

addpath(genpath(pn.prestus_fun));
addpath(genpath(pn.prestus_ext));
addpath(pn.kwave);
addpath(pn.minimize);
addpath(pn.code);
