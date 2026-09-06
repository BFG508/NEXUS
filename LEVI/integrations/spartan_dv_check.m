% ======================================================================
%  spartan_dv_check.m — Validate SPARTAN fleet ΔV budgets
% ======================================================================
%  Reads SPARTAN's fleet init file and cross-references each asset's
%  remaining ΔV against the minimum required for a standard orbital
%  transfer (Hohmann approximation). Assets with insufficient ΔV are
%  flagged as STRANDED.
%
%  Usage:
%      Run from LEVI root:  run('integrations/spartan_dv_check.m')
% ======================================================================

script_dir = fileparts(mfilename('fullpath'));
project_dir = fileparts(script_dir);
addpath(fullfile(project_dir, 'func'));

% --- Read SPARTAN fleet ---
spartan_path = fullfile(project_dir, '..', 'SPARTAN', 'spartan_snapshot.txt');
if ~isfile(spartan_path)
    spartan_path = fullfile(project_dir, '..', 'SPARTAN', 'spartan_init.txt');
end
if ~isfile(spartan_path)
    error('[LEVI-SPARTAN] Fleet snapshot/bootstrap not found: %s', spartan_path);
end

fid = fopen(spartan_path, 'r');
assets = {};
idx = 0;
while ~feof(fid)
    line = fgetl(fid);
    if length(line) < 28, continue; end
    idx = idx + 1;
    assets{idx}.type = strtrim(line(1:10));
    assets{idx}.id = strtrim(line(11:20));
    assets{idx}.integrity = str2double(line(21:23));
    assets{idx}.delta_v = str2double(line(24:28));
end
fclose(fid);

fprintf('[LEVI-SPARTAN] Loaded %d fleet assets.\n', length(assets));

% --- ΔV analysis ---
% Standard LEO-to-GEO Hohmann: ~3.9 km/s ≈ 3900 units
% Emergency escape: ~1.0 km/s ≈ 1000 units
MINIMUM_DV_TRANSFER = 3000;
MINIMUM_DV_ESCAPE = 1000;

operational = 0;
stranded = 0;
critical = 0;
report = {};

for i = 1:length(assets)
    a = assets{i};
    if a.delta_v >= MINIMUM_DV_TRANSFER
        status = 'OPERATIONAL';
        operational = operational + 1;
    elseif a.delta_v >= MINIMUM_DV_ESCAPE
        status = 'LIMITED (escape only)';
        critical = critical + 1;
    else
        status = 'STRANDED';
        stranded = stranded + 1;
    end
    report{i} = struct('id', a.id, 'type', a.type, ...
                       'delta_v', a.delta_v, 'integrity', a.integrity, ...
                       'status', status);
end

% --- Output report ---
fprintf('\n  Fleet ΔV Budget Analysis:\n');
fprintf('  %-12s %-12s %8s %10s %s\n', 'ID', 'TYPE', 'ΔV', 'HULL', 'STATUS');
fprintf('  %s\n', repmat('-', 1, 60));
for i = 1:length(report)
    r = report{i};
    fprintf('  %-12s %-12s %8d %9d%% %s\n', ...
            r.id, r.type, r.delta_v, r.integrity, r.status);
end

fprintf('\n  Summary: %d operational, %d limited, %d stranded (of %d total)\n', ...
        operational, critical, stranded, length(assets));

% --- Save JSON report ---
output_path = fullfile(script_dir, 'spartan_dv_report.json');
fid = fopen(output_path, 'w');
fprintf(fid, '[\n');
for i = 1:length(report)
    r = report{i};
    fprintf(fid, '  {"id": "%s", "type": "%s", "delta_v": %d, "integrity": %d, "status": "%s"}', ...
            r.id, r.type, r.delta_v, r.integrity, r.status);
    if i < length(report), fprintf(fid, ','); end
    fprintf(fid, '\n');
end
fprintf(fid, ']\n');
fclose(fid);
fprintf('[LEVI-SPARTAN] Report saved to: %s\n', output_path);
