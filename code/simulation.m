% PRESTUS 2D Demo — main simulation script
%
% Run this script from the MATLAB command line or the PRESTUS GUI.
% Interactive mode (parameters.simulation.interactive = 1) shows figures
% and confirmation dialogs; set to 0 for unattended batch runs.
%
% To launch the PRESTUS GUI pre-loaded with the demo config, run these two
% lines (PRESTUS must be on the path, e.g. after running this script once):
%   params = load_parameters(fullfile(rootpath, 'data', 'configs', 'config_setup1.yaml'));
%   prestus_gui(params)
%
% Prerequisites:
%   - Git submodule tools/PRESTUS is initialised (git submodule update --init)
%   - k-Wave and FEX-minimize are present inside tools/PRESTUS/external/
%   - Benchmark phantom data is present in data/simnibs/

clear all; close all; clc;

%% ── paths ───────────────────────────────────────────────────────────────

% Derive project root from script location so the script is portable
currentFile = mfilename('fullpath');
[code_dir, ~, ~] = fileparts(currentFile);
rootpath = fileparts(code_dir);          % one level up from code/

addpath(code_dir);
pn = demo_setup_paths(rootpath);

%% ── experiment variables ────────────────────────────────────────────────

setup_list = {'setup1'};  % config file stems (config_<name>.yaml)
all_subjects    = [002];       % subject / benchmark IDs
intensities     = [30];        % free-water target intensity [W/cm2]

% Set to 1 to run free-water calibration before the phantom simulation.
% When 0 the precomputed values below are used instead.
run_calibration = 0;

% Interactive mode: 1 shows figures and pause dialogs, 0 for batch / GUI
interactive = 1;

% Launch GUI or start via direct submission?
gui_launch = 1;

%% ── main loop ───────────────────────────────────────────────────────────

for subject_id = all_subjects
    for i_transducer = 1:length(setup_list)
        for i_intensity = 1:length(intensities)

            transducer_name   = setup_list{i_transducer};
            desired_intensity = intensities(i_intensity);

            %% load parameters

            parameters = load_parameters( ...
                fullfile(pn.configs, ['config_', transducer_name, '.yaml']));

            %% patch runtime paths

            pn.sim = fullfile(rootpath, 'data', 'tussim', transducer_name);
            if ~exist(pn.sim, 'dir'); mkdir(pn.sim); end

            parameters.path.anat  = pn.data_seg;
            parameters.path.seg   = pn.data_seg;
            parameters.path.sim   = pn.sim;
            parameters.startup.paths_to_add = {pn.kwave, pn.minimize};

            %% optional calibration

            if run_calibration
                [opt_source_amp, opt_source_phase_deg, opt_source_phase_rad] = ...
                    demo_calibrate(pn, parameters, subject_id, ...
                                   desired_intensity, transducer_name);
            end

            %% phantom simulation

            % Reload parameters so calibration run cannot contaminate state
            parameters = load_parameters( ...
                fullfile(pn.configs, ['config_', transducer_name, '.yaml']));

            parameters.path.anat  = pn.data_seg;
            parameters.path.seg   = pn.data_seg;
            parameters.path.sim   = pn.sim;
            parameters.startup.paths_to_add = {pn.kwave, pn.minimize};

            parameters.simulation.medium      = 'phantom';
            parameters.simulation.code_type   = 'matlab_cpu';
            parameters.simulation.interactive = interactive;

            parameters.io.overwrite_files   = 'always';
            parameters.io.overwrite_simnibs = 0;
            parameters.io.save_heatingvideo = 0;

            % Transducer position: override here if not set in the config
            parameters.transducer.trans_pos = [35, parameters.grid.pml_size + 1];
            parameters.transducer.focus_pos = [35, parameters.grid.pml_size + 64];

            if run_calibration
                parameters.transducer.annular.elem_amp       = opt_source_amp;
                parameters.transducer.annular.elem_phase_deg = opt_source_phase_deg;
                parameters.transducer.annular.elem_phase_rad = opt_source_phase_rad;
            else
                % Precomputed calibration values for setup1 at 30 W/cm2
                parameters.transducer.annular.elem_amp       = 83202;
                parameters.transducer.annular.elem_phase_deg = 210.6;
                parameters.transducer.annular.elem_phase_rad = 3.7;
            end

            parameters.subject_id = subject_id;
            parameters.platform   = 'matlab';

            % To launch the PRESTUS GUI pre-loaded with the demo config,
            if gui_launch == 1
                prestus_gui(parameters);
            else
                prestus_pipeline_start(parameters);
            end

        end
    end
end
