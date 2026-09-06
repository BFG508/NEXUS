% ======================================================================
% gaia_mission_planner.m — Plan simplified missions to GAIA targets.
% Accepts either ASTRA's compatibility payload or GAIA's processed dataset.
% ======================================================================
script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
addpath(fullfile(project_dir, 'func'));

gaia_path = fullfile(project_dir, '..', 'GAIA', 'data', 'raw', 'astra_payload.csv');
if ~isfile(gaia_path)
    gaia_path = fullfile(project_dir, '..', 'GAIA', 'data', 'processed', 'clean_exoplanets.csv');
end
if ~isfile(gaia_path)
    error('[LEVI-GAIA] No GAIA payload/processed dataset found.');
end

data = readtable(gaia_path);
vars = data.Properties.VariableNames;
if ismember('pl_name', vars)
    planet_names = string(data.pl_name);
    temperatures = data.pl_eqt;
    radii = data.pl_rade;
    if ismember('sy_dist', vars), distances_pc = data.sy_dist; else, distances_pc = nan(height(data),1); end
elseif ismember('planet_name', vars)
    planet_names = string(data.planet_name);
    temperatures = data.equilibrium_temp_k;
    radii = data.planet_radius_earth;
    if ismember('distance_parsecs', vars), distances_pc = data.distance_parsecs; else, distances_pc = nan(height(data),1); end
else
    error('[LEVI-GAIA] Unsupported GAIA schema in %s', gaia_path);
end

mask = isfinite(temperatures) & isfinite(radii) & temperatures >= 250 & temperatures <= 350;
planet_names = planet_names(mask);
temperatures = temperatures(mask);
radii = radii(mask);
distances_pc = distances_pc(mask);
fprintf('[LEVI-GAIA] %d candidate(s) in 250–350 K equilibrium-temperature range.\n', numel(temperatures));
if isempty(temperatures), return; end

cruise_speed_c = 0.1;
c_km_s = 299792.458;
cruise_speed_km_s = cruise_speed_c * c_km_s;
dv_escape_km_s = 16.6;

missions = cell(numel(temperatures),1);
for i = 1:numel(temperatures)
    name = char(planet_names(i));
    if isfinite(distances_pc(i)) && distances_pc(i) > 0
        dist_pc = distances_pc(i);
        distance_source = 'catalog';
    else
        % Compatibility fallback only when a payload has no distance field.
        dist_pc = 10 + mod(sum(double(name)), 990);
        distance_source = 'synthetic_proxy';
    end
    dist_ly = dist_pc * 3.26156;
    travel_time_yr = (dist_ly * 9.461e12 / cruise_speed_km_s) / (365.25 * 86400);
    if travel_time_yr < 100
        status = 'FEASIBLE';
    elseif travel_time_yr < 1000
        status = 'CHALLENGING';
    else
        status = 'GENERATIONAL';
    end
    missions{i} = struct('planet', name, 'temp_k', temperatures(i), ...
        'radius_earth', radii(i), 'distance_ly', dist_ly, ...
        'distance_source', distance_source, 'travel_time_yr', travel_time_yr, ...
        'delta_v_km_s', dv_escape_km_s, 'status', status);
end

output_path = fullfile(script_dir, 'gaia_mission_plans.json');
fid = fopen(output_path, 'w');
fprintf(fid, '[\n');
for i = 1:numel(missions)
    m = missions{i};
    fprintf(fid, '  {"planet":"%s","temp_k":%.3f,"radius_earth":%.4f,"distance_ly":%.3f,"distance_source":"%s","travel_time_yr":%.3f,"delta_v_km_s":%.3f,"status":"%s"}', ...
        m.planet, m.temp_k, m.radius_earth, m.distance_ly, m.distance_source, m.travel_time_yr, m.delta_v_km_s, m.status);
    if i < numel(missions), fprintf(fid, ','); end
    fprintf(fid, '\n');
end
fprintf(fid, ']\n');
fclose(fid);
fprintf('[LEVI-GAIA] Mission plans saved to: %s\n', output_path);
