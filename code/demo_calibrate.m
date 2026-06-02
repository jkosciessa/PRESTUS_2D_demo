function [opt_source_amp, opt_source_phase_deg, opt_source_phase_rad] = ...
    demo_calibrate(pn, parameters, subject_id, desired_intensity, transducer_name)
% Run a free-water simulation and calibrate transducer amplitude/phase to
% match the desired free-water intensity.
%
% Inputs:
%   pn               - path struct from setup_demo_paths
%   parameters       - PRESTUS parameter struct (already loaded and patched)
%   subject_id       - subject / benchmark ID
%   desired_intensity - target free-water intensity [W/cm2]
%   transducer_name  - name of the transducer config (e.g. 'setup1')

    %% run free-water simulation

    parameters.simulation.medium        = 'water';
    parameters.simulation.interactive   = 0;
    parameters.io.overwrite_files       = 'always';
    parameters.io.save_matrices         = 1;
    parameters.modules.run_heating_sims = 0;
    parameters.subject_id               = subject_id;
    parameters.platform                 = 'matlab';

    prestus_pipeline_start(parameters);

    %% load results and compute axial intensity profile

    outputs_folder = fullfile(parameters.path.sim, sprintf('sub-%03d', subject_id));
    cache_dir = fullfile(outputs_folder, 'cache');
    if ~exist(cache_dir, 'dir')
        % fall back to flat output dir (older PRESTUS versions)
        cache_dir = outputs_folder;
    end

    result_file = fullfile(cache_dir, sprintf('sub-%03d_water_results%s.mat', ...
        subject_id, parameters.io.output_affix));
    opt_res        = load(result_file);
    opt_res_params = opt_res.acoustic_info.parameters;

    p_max = gather(opt_res.sensor_data.p_max_all);

    if ndims(p_max) == 2
        pred_axial = squeeze(p_max(opt_res_params.transducer.trans_pos(1), :));
        long_dim   = 2;
    else
        pred_axial = squeeze(p_max(opt_res_params.transducer.trans_pos(1), ...
                                   opt_res_params.transducer.trans_pos(2), :));
        long_dim   = 3;
    end

    axial_pressure = pred_axial .^ 2 ./ ...
        (2 * opt_res_params.medium_properties.water.sound_speed * ...
             opt_res_params.medium_properties.water.density) .* 1e-4;

    pos_x_axis   = (1:size(p_max, long_dim)) .* opt_res_params.grid.resolution_mm;
    pos_x_trans  = opt_res_params.transducer.trans_pos(long_dim) * opt_res_params.grid.resolution_mm;
    pos_x_sim_res = pos_x_axis - pos_x_trans;

    %% save free-water profile figure

    h = figure('Position', [10 10 900 500], 'Visible', 'off');
    hold on;
    xlabel('Axial Position [mm]');
    ylabel('Intensity [W/cm^2]');
    plot(pos_x_sim_res, axial_pressure);
    xline(opt_res_params.transducer.focal_distance_ep, '--');
    yline(desired_intensity, '--');
    hold off;
    saveas(h, fullfile(outputs_folder, 'calibration_water_profile.png'), 'png');
    close(h);

    %% build empirical profile and run calibration

    correctionFactor = desired_intensity / max(axial_pressure);

    profile_empirical.axial_distance_bowl = pos_x_sim_res;
    profile_empirical.axial_intensity     = axial_pressure .* correctionFactor;

    parameters.calibration = yaml.loadFile(fullfile(pn.configs, 'config_calibration.yaml'));
    parameters.calibration.path_output = pn.calibration;
        if ~exist(parameters.calibration.path_output, 'dir'); mkdir(parameters.calibration.path_output); end
    parameters.calibration.path_output_profiles = ...
        fullfile(parameters.calibration.path_output, 'PRESTUS_virtual_parameters');
        if ~exist(parameters.calibration.path_output_profiles, 'dir')
            mkdir(parameters.calibration.path_output_profiles)
        end

    [opt_source_amp, opt_source_phase_deg, opt_source_phase_rad] = ...
        calibration_pipeline_start(profile_empirical, ...
            transducer_name, ...
            desired_intensity, ...
            opt_res_params.transducer.focal_distance_ep, ...
            parameters, ...
            subject_id);
end
