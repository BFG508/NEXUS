% ======================================================================
%  beam_comm_window.m — Calculate communication windows for BEAM arrays
% ======================================================================
%  Propagates satellite positions using Keplerian motion and calculates
%  the time windows during which each asset falls within BEAM's phased
%  array beamwidth cone.
%
%  Usage:
%      Run from LEVI root:  run('integrations/beam_comm_window.m')
% ======================================================================

script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
addpath(fullfile(project_dir, 'func'));

% --- BEAM array parameters (10-element λ/2 array at 1 GHz) ---
freq = 1e9;
c = 3e8;
lambda = c / freq;
d_spacing = lambda / 2;
N_elements = 10;
beamwidth_rad = 0.886 * lambda / (N_elements * d_spacing);
beamwidth_deg = rad2deg(beamwidth_rad);

fprintf('[LEVI-BEAM] Array beamwidth: %.2f degrees\n', beamwidth_deg);

% --- Read BEAM steering schedule ---
schedule_path = fullfile(project_dir, '..', 'BEAM', 'integrations', 'steering_schedule.json');
if ~isfile(schedule_path)
    error('[LEVI-BEAM] Steering schedule not found: %s\nRun BEAM beam_steering first.', schedule_path);
end

raw = fileread(schedule_path);
schedule = jsondecode(raw);

fprintf('[LEVI-BEAM] Loaded %d asset positions.\n', length(schedule));

% --- Simulate orbital propagation and comm windows ---
mu_earth = 398600.4418;  % km³/s²
orbit_alt_km = 500;      % LEO altitude
r_orbit = 6371 + orbit_alt_km;
T_orbit = 2 * pi * sqrt(r_orbit^3 / mu_earth);
omega = 2 * pi / T_orbit;

fprintf('[LEVI-BEAM] Orbital period: %.1f min at %d km altitude.\n', T_orbit/60, orbit_alt_km);

dt = 10;  % time step (seconds)
t_sim = 0:dt:T_orbit;

results = struct('asset_id', {}, 'window_start_s', {}, 'window_end_s', {}, ...
                 'window_duration_s', {}, 'passes', {});

for i = 1:length(schedule)
    target_angle = schedule(i).target_angle_deg;
    half_bw = beamwidth_deg / 2;

    % Find time windows when satellite is within beamwidth
    in_window = false;
    window_start = 0;
    passes = 0;
    total_window = 0;

    for j = 1:length(t_sim)
        sat_angle = mod(rad2deg(omega * t_sim(j)), 360);
        angular_diff = abs(sat_angle - target_angle);
        angular_diff = min(angular_diff, 360 - angular_diff);

        if angular_diff <= half_bw
            if ~in_window
                in_window = true;
                window_start = t_sim(j);
                passes = passes + 1;
            end
        else
            if in_window
                in_window = false;
                total_window = total_window + (t_sim(j) - window_start);
            end
        end
    end

    idx = length(results) + 1;
    results(idx).asset_id = schedule(i).asset_id;
    results(idx).window_start_s = window_start;
    results(idx).window_end_s = window_start + total_window;
    results(idx).window_duration_s = round(total_window, 1);
    results(idx).passes = passes;
end

% --- Output ---
fprintf('\n  Communication Window Analysis:\n');
fprintf('  %-12s %10s %8s\n', 'ASSET', 'WINDOW(s)', 'PASSES');
fprintf('  %s\n', repmat('-', 1, 35));
for i = 1:length(results)
    fprintf('  %-12s %10.1f %8d\n', results(i).asset_id, ...
            results(i).window_duration_s, results(i).passes);
end

output_path = fullfile(script_dir, 'beam_comm_windows.json');
fid = fopen(output_path, 'w');
fprintf(fid, '%s', jsonencode(results));
fclose(fid);
fprintf('[LEVI-BEAM] Report saved to: %s\n', output_path);
