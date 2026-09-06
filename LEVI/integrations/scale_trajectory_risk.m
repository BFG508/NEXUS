% ======================================================================
%  scale_trajectory_risk.m — Stochastic trajectory perturbation analysis
% ======================================================================
%  Reads ASTRA transfer trajectories computed by LEVI, then applies
%  SCALE-style random perturbations (engine failures, solar wind,
%  navigation errors) to evaluate mission risk.
%
%  Usage:
%      Run from LEVI root:  run('integrations/scale_trajectory_risk.m')
% ======================================================================

script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
addpath(fullfile(project_dir, 'func'));
rng(42, 'twister'); % Reproducible compatibility Monte Carlo

% --- Read computed transfers (from LEVI-ASTRA integration) ---
transfers_path = fullfile(script_dir, 'astra_transfers.csv');
if ~isfile(transfers_path)
    % If no transfers exist, generate synthetic test data
    fprintf('[LEVI-SCALE] No transfer data found. Generating synthetic test.\n');
    departures = {'Planet b', 'Planet c', 'Planet d'};
    arrivals = {'Planet c', 'Planet d', 'Planet e'};
    dv_values = [3.5, 5.2, 2.1];
    tof_values = [180, 320, 90];
else
    data = readtable(transfers_path);
    departures = data.departure;
    arrivals = data.arrival;
    dv_values = data.delta_v_km_s;
    tof_values = data.tof_days;
    fprintf('[LEVI-SCALE] Loaded %d transfer trajectories.\n', height(data));
end

% --- SCALE-style dice rolls for perturbation ---
% Simulates the unpredictability that SCALE's entropy engine provides
N_MONTE_CARLO = 1000;

fprintf('\n  Trajectory Risk Analysis (N=%d Monte Carlo runs):\n', N_MONTE_CARLO);
fprintf('  %-20s %-20s %8s %8s %8s %8s\n', ...
    'DEPARTURE', 'ARRIVAL', 'ΔV_nom', 'ΔV_95%', 'P(fail)', 'RISK');
fprintf('  %s\n', repmat('-', 1, 80));

results = {};
for i = 1:length(dv_values)
    nominal_dv = dv_values(i);
    nominal_tof = tof_values(i);

    % Monte Carlo perturbation
    dv_samples = zeros(N_MONTE_CARLO, 1);
    failures = 0;

    for j = 1:N_MONTE_CARLO
        % Engine performance variance (±5% nominal, heavy-tail)
        engine_factor = 1.0 + 0.05 * randn();

        % Solar wind perturbation (dice roll: 2d6 scaled)
        solar_wind = (randi(6) + randi(6) - 7) * 0.01;  % [-5%, +5%]

        % Navigation error (small Gaussian)
        nav_error = 0.02 * randn();

        % Catastrophic event (1d20 = 1 → engine failure)
        catastrophe = randi(20);
        if catastrophe == 1
            engine_factor = engine_factor * 1.5;  % 50% ΔV penalty
            failures = failures + 1;
        end

        dv_actual = nominal_dv * (engine_factor + solar_wind + nav_error);
        dv_samples(j) = max(0, dv_actual);
    end

    dv_95 = quantile(dv_samples, 0.95);
    p_fail = failures / N_MONTE_CARLO;

    if p_fail < 0.03 && dv_95 < nominal_dv * 1.15
        risk = 'LOW';
    elseif p_fail < 0.08 || dv_95 < nominal_dv * 1.3
        risk = 'MODERATE';
    else
        risk = 'HIGH';
    end

    dep = departures{min(i, length(departures))};
    arr = arrivals{min(i, length(arrivals))};

    fprintf('  %-20s %-20s %8.3f %8.3f %7.1f%% %8s\n', ...
            dep, arr, nominal_dv, dv_95, p_fail*100, risk);

    results{i} = struct('departure', dep, 'arrival', arr, ...
                        'nominal_dv', round(nominal_dv, 3), ...
                        'dv_95pct', round(dv_95, 3), ...
                        'failure_probability', round(p_fail, 4), ...
                        'risk_level', risk);
end

% --- Save report ---
output_path = fullfile(script_dir, 'scale_risk_report.json');
fid = fopen(output_path, 'w');
fprintf(fid, '[\n');
for i = 1:length(results)
    r = results{i};
    fprintf(fid, '  {"departure": "%s", "arrival": "%s", "nominal_dv": %.3f, "dv_95pct": %.3f, "failure_probability": %.4f, "risk_level": "%s"}', ...
            r.departure, r.arrival, r.nominal_dv, r.dv_95pct, r.failure_probability, r.risk_level);
    if i < length(results), fprintf(fid, ','); end
    fprintf(fid, '\n');
end
fprintf(fid, ']\n');
fclose(fid);
fprintf('[LEVI-SCALE] Risk report saved to: %s\n', output_path);
