% LEVI reproducible command-line smoke demonstration.
project_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(project_dir, 'func'));

mu = 398600.4418;             % km^3/s^2, Earth
r0 = [7000; 0; 0];            % km
v0 = [0; sqrt(mu/7000); 0];   % km/s, circular reference orbit
propagation_time = 600;        % s

[r1, v1, err] = kepler(r0, v0, propagation_time, mu);
if ~strcmp(err, 'ok')
    error('LEVI demo propagation failed: %s', err);
end

fprintf('LEVI two-body demo\n');
fprintf('  Initial radius: %.3f km\n', norm(r0));
fprintf('  Final radius:   %.3f km\n', norm(r1));
fprintf('  Final speed:    %.6f km/s\n', norm(v1));
fprintf('  Status:         %s\n', err);
