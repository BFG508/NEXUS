function tests = test_smoke
tests = functiontests(localfunctions);
end

function testCircularKeplerPropagation(testCase)
project_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project_dir, 'func'));
mu = 398600.4418;
r0 = [7000; 0; 0];
v0 = [0; sqrt(mu/7000); 0];
[r1, v1, err] = kepler(r0, v0, 600, mu);
verifyEqual(testCase, err, 'ok');
verifyLessThan(testCase, abs(norm(r1) - norm(r0)), 1e-3);
verifyLessThan(testCase, abs(norm(v1) - norm(v0)), 1e-6);
end

function testStumpffOrigin(testCase)
project_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project_dir, 'func'));
[c2, c3] = findc2c3(0);
verifyEqual(testCase, c2, 0.5, 'AbsTol', 1e-14);
verifyEqual(testCase, c3, 1/6, 'AbsTol', 1e-14);
end
