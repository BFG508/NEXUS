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

function testCircularLambertTransfers(testCase)
project_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project_dir, 'func'));
mu = 398600.4418;
radius = 7000;
speed = sqrt(mu/radius);
r1 = [radius; 0; 0];
v1 = [0; speed; 0];
for angle = [pi/6, pi/3, pi/2, 2*pi/3, 5*pi/6, 17*pi/18]
    r2 = radius * [cos(angle); sin(angle); 0];
    v2 = speed * [-sin(angle); cos(angle); 0];
    tof = angle * sqrt(radius^3/mu);
    [u1, u2, error] = lambertUniVar(r1, r2, v1, 'S', 'L', 0, tof, [], mu);
    verifyEqual(testCase, error, 'ok');
    verifyLessThan(testCase, norm(u1-v1), 1e-5);
    verifyLessThan(testCase, norm(u2-v2), 1e-5);
    [g1, g2, ~, ~, deltaV, flag, a, e] = lambertGauss(r1, v1, r2, v2, tof, 'S', mu);
    verifyEqual(testCase, flag, 'ok');
    verifyLessThan(testCase, norm(g1-v1), 1e-5);
    verifyLessThan(testCase, norm(g2-v2), 1e-5);
    verifyLessThan(testCase, deltaV, 2e-5);
    verifyLessThan(testCase, abs(a-radius), 1e-2);
    verifyLessThan(testCase, e, 1e-4);
    [arrival, ~, status] = kepler(r1, g1, tof, mu);
    verifyEqual(testCase, status, 'ok');
    verifyLessThan(testCase, norm(arrival-r2), 1e-2);
end
end

function testGaussRecoversEccentricTransfer(testCase)
project_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(project_dir, 'func'));
mu = 398600.4418;
r1 = [7000; 0; 0];
v1 = [0; 0.9*sqrt(mu/7000); 0];
for tof = [300, 600, 1000]
    [r2, v2, status] = kepler(r1, v1, tof, mu);
    verifyEqual(testCase, status, 'ok');
    [g1, g2, ~, ~, deltaV, flag] = lambertGauss(r1, v1, r2, v2, tof, 'S', mu);
    verifyEqual(testCase, flag, 'ok');
    verifyLessThan(testCase, norm(g1-v1), 1e-5);
    verifyLessThan(testCase, norm(g2-v2), 1e-5);
    verifyLessThan(testCase, deltaV, 2e-5);
end
end
