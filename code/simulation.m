clear all; close all; clc;

% get root path (script must be run)
currentFile = mfilename('fullpath');
[pathstr,~,~] = fileparts(currentFile); 
cd(fullfile(pathstr,'..'))
rootpath = pwd;

addpath(fullfile(rootpath, 'code'));

% you need to specify the path to your own simnibs installation (sorry!)
pn.simnibs = fullfile('/home', 'neuromod', 'julkos', '.conda', 'envs', 'simnibs_env', 'bin');

pn.tuSIM = fullfile(rootpath, 'tools', 'PRESTUS'); addpath(pn.tuSIM);
pn.tuSIM_fun = fullfile(pn.tuSIM, 'functions'); addpath(pn.tuSIM_fun);
pn.tuSIM_tools = fullfile(pn.tuSIM, 'toolboxes'); addpath(genpath(pn.tuSIM_tools));
pn.kwave = fullfile(pn.tuSIM_tools, 'k-wave', 'k-Wave'); addpath(pn.kwave);
pn.minimize = fullfile(pn.tuSIM_tools, 'FEX-minimize'); addpath(pn.minimize);
pn.configs = fullfile(rootpath, 'data', 'configs');
pn.data_path = fullfile(rootpath, 'data', 'bids');
pn.data_seg = fullfile(rootpath, 'data', 'simnibs');
pn.nifti = (fullfile(rootpath, 'tools', 'nifti_toolbox')); addpath(pn.nifti);

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
            
            cd(fullfile(rootpath, 'data')) % needs to contain a folder called "configs" in this setup
            parameters = load_parameters(['config_',transducer_name,'.yaml']);

            parameters.simnibs_bin_path = pn.simnibs;
            pn.data_sims = fullfile(rootpath, 'data', 'tussim', [transducer_name]);
                if ~exist(pn.data_sims); mkdir(pn.data_sims); end
            parameters.ld_library_path ="/opt/gcc/7.2.0/lib64";
            parameters.data_path = pn.data_seg; % use simnibs folder
            parameters.seg_path = pn.data_seg;
            parameters.sim_path = pn.data_sims;
            parameters.paths_to_add = {pn.kwave, pn.minimize};
            pn.outputs_folder = fullfile(parameters.sim_path,sprintf('sub-%03d', subject_id));
            if ~exist(pn.outputs_folder); mkdir(pn.outputs_folder); end

            % Here, we are not performing any segmentation of real 3D
            % images, but rely on precomputed benchmark pahntoms. If you
            % want to specify existing SimNIBS segmentations, you could use
            % the following.

            % parameters.t1_path_template = fullfile(sprintf('m2m_sub-%03d', subject_id), "T1.nii.gz");
            % parameters.t2_path_template = fullfile(sprintf('m2m_sub-%03d', subject_id), "T2_reg.nii.gz");

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% run free-water simulations %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            parameters.simulation_medium = 'water'; % indicate that we only want the simulation in the water medium for now
            parameters.interactive = 0;
            parameters.overwrite_files = 'always';
            parameters.run_heating_sims = 0;
            
            single_subject_pipeline(subject_id, parameters);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% plot free-water results %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            og_res = load(fullfile(pn.outputs_folder, sprintf('sub-%03d_water_results%s.mat',...
            subject_id, parameters.results_filename_affix)),'sensor_data','parameters');

            p_max = gather(og_res.sensor_data.p_max_all);
            pred_axial_pressure_opt = squeeze(p_max(og_res.parameters.transducer.pos_grid(1),:));
            axial_pressure = pred_axial_pressure_opt.^2/...
                (2*parameters.medium.water.sound_speed*parameters.medium.water.density).* 1e-4;

            pos_x_axis = (1:parameters.default_grid_dims(2)).*parameters.grid_step_mm; % x-axis [mm]
            pos_x_trans = (og_res.parameters.transducer.pos_grid(2)-1)*parameters.grid_step_mm; % x-axis position of transducer [mm]
            pos_x_sim_res = pos_x_axis-pos_x_trans; % axial position for the simulated results, relative to transducer position [mm]

            h = figure('Position', [10 10 900 500]);
            hold on
            xlabel('Axial Position [mm]');
            ylabel('Intensity [W/cm^2]');
            plot(pos_x_sim_res, axial_pressure);
            hold off
            xline(og_res.parameters.expected_focal_distance_mm, '--');
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
            real_profile(:,1) = pos_x_sim_res; %pos_x_axis;
            real_profile(:,2) = axial_pressure.*correctionFactor;

            [opt_source_amp, opt_phases] = transducer_calibration(...
                pn, ...
                parameters, ...
                transducer_name, ...
                subject_id, ...
                desired_intensity, ...
                real_profile);

            %% plot the optimized results

            opt_res = load(fullfile(pn.outputs_folder, ...
                sprintf('sub-%03d_water_results%s.mat',subject_id, '_optimized')),...
                'sensor_data','parameters');

            p_max = gather(opt_res.sensor_data.p_max_all);
            pred_axial_pressure_opt = squeeze(p_max(opt_res.parameters.transducer.pos_grid(1),:));
            axial_pressure_opt = pred_axial_pressure_opt.^2/...
                (2*parameters.medium.water.sound_speed*parameters.medium.water.density).* 1e-4;

            h = figure('Position', [10 10 400 200]);
            hold on
            xlabel('Axial Position [mm]');
            ylabel('Intensity [W/cm^2]');
            plot(pos_x_sim_res, axial_pressure, 'LineWidth',2);
            plot(pos_x_sim_res, axial_pressure_opt, 'LineWidth',2);
            hold off
            xline(opt_res.parameters.expected_focal_distance_mm, '--');
            yline(desired_intensity, '--');
            xlim([0 120])
            set(gca, 'FontSize', 15)
            plotname = fullfile(pn.outputs_folder, 'simulation_analytic');
            saveas(h, plotname, 'epsc');
            close(h);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% run soft-tissue simulation %%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            parameters = load_parameters(['config_',transducer_name,'.yaml']);

            parameters.ld_library_path ="/opt/gcc/7.2.0/lib64";
            parameters.data_path = pn.data_seg;
            parameters.seg_path = pn.data_seg;
            parameters.sim_path = pn.data_sims;
            parameters.paths_to_add = {pn.kwave, pn.minimize};

            parameters.simulation_medium = 'phantom'; % use default grid in combo with (final) tissue mask
            parameters.interactive = 0;
            parameters.overwrite_files = 'always';
            parameters.overwrite_simnibs = 0;

            % generate a video of evolving heating? [by default deactivated]
            parameters.heatingvideo = 0;

            parameters.transducer.source_amp = opt_source_amp; % use calibrated input intensity

            parameters.transducer.pos_t1_grid = [3, 35];
            parameters.focus_pos_t1_grid = [64, 35];

            parameters.run_source_setup = 1;
            parameters.run_acoustic_sims = 1;
            parameters.run_heating_sims = 1;

            % post-stim modeling as appended duration

            parameters.thermal.n_trials = 400; % 80 s
            parameters.thermal.duty_cycle = 0.1;
            parameters.thermal.stim_duration = 0.2; 
            parameters.thermal.sim_time_steps = 0.02;
            parameters.thermal.post_stim_dur = 400; % [s]
            parameters.thermal.post_time_steps = 5; % coarser time steps
            parameters.thermal.pri_duration = 0.2;
            parameters.thermal.equal_steps = 1;
            parameters.thermal.cem43_iso = 0;

            % post-stim modeling as break

            % parameters.thermal.n_trials = 4000;
            % parameters.thermal.duty_cycle = 0.1;
            % parameters.thermal.stim_duration = 0.2; 
            % parameters.thermal.sim_time_steps = 0.02;
            % parameters.thermal.post_stim_dur = 0;
            % parameters.thermal.post_time_steps = 0;
            % parameters.start_break_trials = 401; % identical time steps
            % parameters.stop_break_trials = 4000;
            % parameters.thermal.pri_duration = 0.2;
            % parameters.thermal.equal_steps = 1;
            % parameters.thermal.cem43_iso = 0;
            
            single_subject_pipeline(subject_id, parameters);

        end
    end
end
