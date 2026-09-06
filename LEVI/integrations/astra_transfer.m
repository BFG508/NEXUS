% ======================================================================
%  astra_transfer.m — Compute interplanetary transfers for ASTRA systems
% ======================================================================
%  Reads ASTRA's exported planetary orbital elements and uses LEVI's
%  Lambert solver to compute optimal transfer trajectories between
%  adjacent planets in the generated system.
%
%  Usage:
%      Run from LEVI root:  run('integrations/astra_transfer.m')
% ======================================================================

script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
addpath(fullfile(project_dir, 'func'));

% --- Read ASTRA orbital elements ---
csv_path = fullfile(script_dir, 'astra_orbits.csv');
if ~isfile(csv_path)
    error('[LEVI-ASTRA] Orbital-elements file not found: %s\nRun ASTRA with --export first.', csv_path);
end

data = readtable(csv_path);
fprintf('[LEVI-ASTRA] Loaded %d planetary orbits.\n', height(data));

if height(data) < 2
    fprintf('[LEVI-ASTRA] Need at least 2 planets for a transfer.\n');
    return;
end

% --- Compute transfers between consecutive planet pairs ---
results = struct('departure', {}, 'arrival', {}, 'delta_v_km_s', {}, ...
                 'tof_days', {}, 'nrev', {});

mu = data.mu_km3_s2(1);

for i = 1:(height(data)-1)
    a1 = data.semimajor_axis_km(i);
    e1 = data.eccentricity(i);
    a2 = data.semimajor_axis_km(i+1);
    e2 = data.eccentricity(i+1);

    % Approximate circular orbit positions (periapsis alignment)
    r1 = a1 * (1 - e1);  % periapsis
    r2 = a2 * (1 - e2);

    % State vectors (2D circular approximation for Lambert input)
    r0 = [r1; 0; 0];
    rf = [0; r2; 0];  % 90° phase offset

    % Circular velocities
    v0 = [0; sqrt(mu/r1); 0];
    vf = [-sqrt(mu/r2); 0; 0];

    % Hohmann TOF estimate
    a_transfer = (r1 + r2) / 2;
    T_transfer = pi * sqrt(a_transfer^3 / mu);

    % Scan TOF window around Hohmann estimate
    tof_test = linspace(0.7*T_transfer, 1.5*T_transfer, 20);
    best_dv = inf;
    best_tof = T_transfer;
    best_nrev = 0;

    for j = 1:length(tof_test)
        tof = tof_test(j);
        try
            [v0_L, vf_L, err, flag] = lambertUniVar(r0, rf, v0, 'S', 'L', 0, tof, [], mu);
            if strcmp(err, 'ok') && strcmp(flag, 'ok')
                dv = norm(v0_L - v0) + norm(vf - vf_L);
                if dv < best_dv
                    best_dv = dv;
                    best_tof = tof;
                end
            end
        catch
            continue;
        end
    end

    if isfinite(best_dv)
        idx = length(results) + 1;
        results(idx).departure = data.planet_name{i};
        results(idx).arrival = data.planet_name{i+1};
        results(idx).delta_v_km_s = round(best_dv, 4);
        results(idx).tof_days = round(best_tof / 86400, 2);
        results(idx).nrev = best_nrev;

        fprintf('  %s → %s : ΔV = %.3f km/s, TOF = %.1f days\n', ...
            data.planet_name{i}, data.planet_name{i+1}, best_dv, best_tof/86400);
    end
end

% --- Save results ---
output_path = fullfile(script_dir, 'astra_transfers.csv');
if ~isempty(results)
    T = struct2table(results);
    writetable(T, output_path);
    fprintf('[LEVI-ASTRA] %d transfer trajectories saved to: %s\n', length(results), output_path);
else
    fprintf('[LEVI-ASTRA] No valid transfers computed.\n');
end
