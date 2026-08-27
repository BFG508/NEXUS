function [v1dv, v2dv] = lambhodograph(r1, r2, p, e, dnu, mu)
%==========================================================================
% lambhodograph: Computes transfer velocities at r1 and r2 using the orbital
%                hodograph representation for a conic with given p and e.
%
% Inputs:
%   r1  - Initial position vector [3x1] (km)
%   r2  - Final position vector [3x1] (km)
%   p   - Semi-latus rectum of the transfer orbit (km)
%   e   - Eccentricity of the transfer orbit (-)
%   dnu - True-anomaly change from r1 to r2 (rad)
%   mu   - Gravitational parameter of the central body (km^3/s^2)
%
% Outputs:
%   v1dv - Transfer velocity at r1 [3x1] (km/s)
%   v2dv - Transfer velocity at r2 [3x1] (km/s)
%==========================================================================
    % Ensure column vectors
    if size(r1,2) > size(r1,1), r1 = r1.'; end
    if size(r2,2) > size(r2,1), r2 = r2.'; end

    r1mag = norm(r1);
    r2mag = norm(r2);

    if p <= 0
        error('lambhodograph: p must be positive');
    end
    if e < 0
        error('lambhodograph: e must be non-negative');
    end

    % Orbital plane normal (direction of motion given by right-hand rule)
    h = cross(r1, r2);
    if norm(h) < 1e-12
        % Degenerate geometry: build a surrogate normal using z-axis
        zhat = [0;0;1];
        h = cross(r1, zhat);
        if norm(h) < 1e-12, h = cross(r2, zhat); end
    end
    hhat = h / norm(h);

    % Radial and transverse unit vectors
    er1 = r1 / r1mag;
    er2 = r2 / r2mag;
    et1 = cross(hhat, er1);
    et2 = cross(hhat, er2);

    % Circular limit: e ~ 0 ⇒ purely transverse speed
    if e < 1e-10
        vscale = sqrt(mu / p);
        v1dv = vscale * et1;
        v2dv = vscale * et2;
        return;
    end

    % Compute cos(nu1), cos(nu2) from geometry p, e, r
    cos1 = max(-1,min(1,(p/r1mag - 1)/e));
    cos2 = max(-1,min(1,(p/r2mag - 1)/e));

    % Choose sin signs so that (nu2 - nu1) ≈ dnu (wrapped to [0,2π))
    s1 = sqrt(max(0,1 - cos1^2));
    s2 = sqrt(max(0,1 - cos2^2));

    candidates = [ +s1, +s2;
                   +s1, -s2;
                   -s1, +s2;
                   -s1, -s2 ];
    bestIdx = 1; bestErr = inf;
    for k = 1:4
        nu1 = atan2(candidates(k,1), cos1);
        nu2 = atan2(candidates(k,2), cos2);
        d = wrapTo2Pi(nu2 - nu1);
        err = abs(d - wrapTo2Pi(dnu));
        if err < bestErr
            bestErr = err;
            bestIdx = k;
        end
    end
    sin1 = candidates(bestIdx,1);
    sin2 = candidates(bestIdx,2);

    % Polar components and vectors
    vscale = sqrt(mu / p);
    vr1 = vscale * e * sin1;
    vth1 = vscale * (1 + e*cos1);
    vr2 = vscale * e * sin2;
    vth2 = vscale * (1 + e*cos2);

    v1dv = vr1 * er1 + vth1 * et1;
    v2dv = vr2 * er2 + vth2 * et2;
end