clear all; close all; clc;

% get root path (script must be run)
currentFile = mfilename('fullpath');
[pathstr,~,~] = fileparts(currentFile);
cd(fullfile(pathstr,'..'))
rootpath = pwd;

addpath(fullfile(rootpath, 'code'));

% you need to specify the path to your own simnibs installation (sorry!)
% pn.simnibs = fullfile('/home', 'neuromod', 'julkos', '.conda', 'envs', 'simnibs_env', 'bin');

pn.tuSIM = fullfile(rootpath, 'tools', 'PRESTUS'); addpath(pn.tuSIM);
pn.tuSIM_fun = fullfile(pn.tuSIM, 'functions'); addpath(genpath(pn.tuSIM_fun));
pn.tuSIM_ext = fullfile(pn.tuSIM, 'external'); addpath(genpath(pn.tuSIM_ext));
% k-Wave and FEX-minimize were previously in toolboxes/ (renamed to external/ in PRESTUS v0.6.0)
% Point to whichever location has the actual files
if exist(fullfile(pn.tuSIM_ext, 'k-wave', 'k-Wave'), 'dir')
    pn.kwave = fullfile(pn.tuSIM_ext, 'k-wave', 'k-Wave');
else
    pn.kwave = fullfile(pn.tuSIM, 'toolboxes', 'k-wave', 'k-Wave');
end
if exist(fullfile(pn.tuSIM_ext, 'FEX-minimize'), 'dir') && ~isempty(dir(fullfile(pn.tuSIM_ext, 'FEX-minimize', '*.m')))
    pn.minimize = fullfile(pn.tuSIM_ext, 'FEX-minimize');
else
    pn.minimize = fullfile(pn.tuSIM, 'toolboxes', 'FEX-minimize');
end
addpath(pn.kwave); addpath(pn.minimize);
pn.configs = fullfile(rootpath, 'data', 'configs');
pn.data_path = fullfile(rootpath, 'data', 'bids');
pn.data_seg = fullfile(rootpath, 'data', 'simnibs');
pn.nifti = (fullfile(rootpath, 'tools', 'nifti_toolbox')); addpath(pn.nifti);

%% test calibration?

test_calibration = 0;

%% define variables to iterate across

% We will only use one setup, and test a single intensity here. But this
% type of loop could be used to iterate across parameter setups in
% practice.

transducer_list = {['setup1']};     % name of config file
all_subjects = [002];               % subjects (here benchmarks)
intensities = 30;                   % acoustic free-water intensity [W/cm2]

%% iterate across requested setups & subjects

for subject_id = all_subjects
    for i_transducer = 1:length(transducer_list)
        for i_intensity = 1:length(intensities)
            transducer_name = transducer_list{i_transducer};
            desired_intensity = intensities(i_intensity);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% load parameters and adjust paths if necessary %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            cd(fullfile(rootpath, 'data', 'configs'))
            parameters = load_parameters(['config_',transducer_name,'.yaml']);

            % parameters.startup.simnibs_bin_path = pn.simnibs;
            pn.data_sims = fullfile(rootpath, 'data', 'tussim', [transducer_name]);
                if ~exist(pn.data_sims); mkdir(pn.data_sims); end
            parameters.hpc.ld_library_path = "/opt/gcc/7.2.0/lib64";
            parameters.path.anat = pn.data_seg; % use simnibs folder
            parameters.path.seg = pn.data_seg;
            parameters.path.sim = pn.data_sims;
            parameters.startup.paths_to_add = {pn.kwave, pn.minimize};
            pn.outputs_folder = fullfile(parameters.path.sim, sprintf('sub-%03d', subject_id));
            if ~exist(pn.outputs_folder); mkdir(pn.outputs_folder); end

            % Here, we are not performing any segmentation of real 3D
            % images, but rely on precomputed benchmark phantoms. If you
            % want to specify existing SimNIBS segmentations, you could use
            % the following.

            % parameters.path.t1_pattern = fullfile(sprintf('m2m_sub-%03d', subject_id), "T1.nii.gz");
            % parameters.path.t2_pattern = fullfile(sprintf('m2m_sub-%03d', subject_id), "T2_reg.nii.gz");

            if test_calibration == 1

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %% run free-water simulations %%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                parameters.simulation.medium = 'water'; % indicate that we only want the simulation in the water medium for now
                parameters.simulation.interactive = 0;
                parameters.io.overwrite_files = 'always';
                parameters.modules.run_heating_sims = 0;
                parameters.simulation.code_type = 'matlab_cpu';
                parameters.io.save_matrices = 1; % we want to load the output below

                single_subject_pipeline(subject_id, parameters);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %% plot free-water results %%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                opt_res = load(fullfile(pn.outputs_folder, sprintf('sub-%03d_water_results%s.mat',...
                    subject_id, parameters.io.output_affix)));

                opt_res_params = opt_res.acoustic_info.parameters;

                p_max = gather(opt_res.sensor_data.p_max_all);
                pred_axial_pressure_opt = squeeze(p_max(opt_res_params.transducer.trans_pos(1),:));
                axial_pressure = pred_axial_pressure_opt.^2/...
                    (2*opt_res_params.medium_properties.water.sound_speed*opt_res_params.medium_properties.water.density).* 1e-4;

                h = figure('Position', [10 10 900 500]);
                hold on
                xlabel('Axial Position [mm]');
                ylabel('Intensity [W/cm^2]');
                pos_x_axis = (1:opt_res_params.grid.default_dims(2)).*opt_res_params.grid.resolution_mm; % x-axis [mm]
                pos_x_trans = (opt_res_params.transducer.trans_pos(2)-1)*opt_res_params.grid.resolution_mm; % x-axis position of transducer [mm]
                pos_x_sim_res = pos_x_axis-pos_x_trans; % axial position for the simulated results, relative to transducer position [mm]
                plot(pos_x_sim_res, axial_pressure);
                hold off
                xline(opt_res_params.transducer.focal_distance_ep, '--');
                yline(desired_intensity, '--');
                plotname = fullfile(pn.outputs_folder, 'simulation_analytic.png');
                saveas(h, plotname, 'png');
                close(h);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %% introduce a simple free-water amplitude scaling %%
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                % Assumption: the "real" profile linearly scales to a peak of the desired intensity

                % axial_pressure | profile measured in simulation grid
                %                pos_x_axis - raw simulation axis, 1: transducer bowl
                %                pos_x_sim_res - axis without transducer position

                parameters.correctEPdistance = 0; % do not correct for exit plan distance

                correctionFactor = (desired_intensity./max(axial_pressure));
                profile_empirical.dist_from_tran = pos_x_sim_res;
                profile_empirical.profile_focus = axial_pressure.*correctionFactor;
                profile_empirical.focus_wrt_exit_plane = 64; % not really the exit plane here...

                cd(fullfile(rootpath, 'data','configs'));

                parameters.calibration = yaml.loadFile('calibration_config.yaml');
                parameters.calibration.path_output = fullfile(rootpath, 'data','calibration');
                    mkdir(parameters.calibration.path_output)
                parameters.calibration.path_output_profiles = ...
                    fullfile(parameters.calibration.path_output,'PRESTUS_virtual_parameters');
                    mkdir(parameters.calibration.path_output_profiles)

                [opt_source_amp, opt_source_phase_deg, opt_source_phase_rad] = ...
                    calibration_transducer(profile_empirical,...
                    transducer_name, ...
                    desired_intensity, ...
                    parameters, ...
                    subject_id);

            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% run phantom simulation %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%

            cd(fullfile(rootpath, 'data','configs'));

            parameters = load_parameters(['config_',transducer_name,'.yaml']);

            parameters.hpc.ld_library_path = "/opt/gcc/7.2.0/lib64";
            parameters.path.anat = pn.data_seg;
            parameters.path.seg = pn.data_seg;
            parameters.path.sim = pn.data_sims;
            parameters.startup.paths_to_add = {pn.kwave, pn.minimize};

            parameters.simulation.medium = 'phantom'; % use default grid in combo with (final) tissue mask

            parameters.io.overwrite_files = 'always';
            parameters.io.overwrite_simnibs = 0;

            % generate a video of evolving heating? [by default deactivated]
            parameters.io.save_heatingvideo = 0;

            if test_calibration == 1
                parameters.transducer.annular.elem_amp = opt_source_amp; % use calibrated input intensity
                parameters.transducer.annular.elem_phase_deg = opt_source_phase_deg;
                parameters.transducer.annular.elem_phase_rad = opt_source_phase_rad;
            else
                parameters.transducer.annular.elem_amp = 83202; % use precomputed value
                parameters.transducer.annular.elem_phase_deg = 210.6;
                parameters.transducer.annular.elem_phase_rad = 3.7;
            end

            parameters.transducer.trans_pos = [35, parameters.grid.pml_size+1];
            parameters.transducer.focus_pos = [35, parameters.grid.pml_size+64];

            % post-stim modeling as break

            parameters.simulation.code_type = 'matlab_cpu';

            % Run interactive?
            parameters.simulation.interactive = 1;

            single_subject_pipeline(subject_id, parameters);

        end
    end
end
