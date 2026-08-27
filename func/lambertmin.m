function [v0, a_min, e_min, t_min] = lambertmin(r0, r, mu)
%==========================================================================
% lambertmin: Minimum-energy Lambert transfer between two position vectors.
%              Computes the initial velocity, minimum semi-major axis,
%              minimum eccentricity, and minimum time of flight for the
%              classical (two-body) minimum-energy solution.
%
% Inputs:
%   r0  - Initial position vector [3xN] (km)
%   r   - Final   position vector [3xN] (km)
%   mu  - Gravitational parameter of the central body (km^3/s^2)
%
% Outputs:
%   v0    - Initial velocity vector for the minimum-energy transfer [3xN] (km/s)
%   a_min - Minimum semi-major axis [1xN] (km)
%   e_min - Minimum eccentricity [1xN] (-)
%   t_min - Minimum time of flight [1xN] (s)
%==========================================================================

    if size(r0,1) ~= 3
        if size(r0,2) == 3, r0 = r0.'; else, error('lambertmin:badInput', 'r0 must be 3xN'); end
    end
    if size(r,1) ~= 3
        if size(r,2) == 3, r  = r.';  else, error('lambertmin:badInput', 'r must be 3xN');  end
    end
    
    N = size(r0, 2);
    if size(r, 2) ~= N
        error('lambertmin:badInput', 'r0 and r must have the same number of columns');
    end

    if ~isfinite(mu) || mu <= 0
        error('lambertmin:badMu', 'Gravitational parameter mu must be positive and finite.');
    end

    % Magnitudes
    r0_mag = sqrt(sum(r0.^2, 1));
    r_mag  = sqrt(sum(r.^2, 1));
    
    if any(r0_mag < 1e-12 | r_mag < 1e-12)
        error('lambertmin:zeroRadius', 'Position magnitudes must be non-zero.');
    end

    % Geometry
    cos_dnu = sum(r0 .* r, 1) ./ (r0_mag .* r_mag);
    cos_dnu = max(-1, min(1, cos_dnu)); % clamp
    dnu     = acos(cos_dnu);

    if any(abs(sin(dnu)) < 1e-12)
        error('lambertmin:singularity', 'Transfer angle too close to 0 or pi; minimum-energy velocity undefined.');
    end

    % Chord and semiperimeter
    c = sqrt(r0_mag.^2 + r_mag.^2 - 2.*r0_mag.*r_mag.*cos_dnu);
    if any(c < 1e-12)
        error('lambertmin:degenerateChord', 'Chord length is ~0; geometry is degenerate.');
    end
    s = (r0_mag + r_mag + c) / 2;

    % Minimum-energy orbital parameters
    a_min = s / 2;
    p_min = (r0_mag .* r_mag ./ c) .* (1 - cos_dnu);

    % Eccentricity (clip for numerical safety)
    e2 = 1 - 2.*p_min ./ s;
    e2(e2 < 0 & e2 > -1e-12) = 0;
    if any(e2 < 0)
        error('lambertmin:complexEcc', 'Computed eccentricity would be complex (check geometry/units).');
    end
    e_min = sqrt(e2);

    % Minimum time of flight (alpha = pi)
    sin_beta_e = sqrt(max(0, (s - c) ./ s));
    beta_e     = 2 * asin(sin_beta_e);
    alpha_e    = pi;
    t_min      = sqrt(a_min.^3 / mu) .* (alpha_e - (beta_e - sin(beta_e)));

    % Initial velocity
    denom = r0_mag .* r_mag .* sin(dnu);
    if any(abs(denom) < 1e-12)
        error('lambertmin:singularity', 'Transfer angle leads to zero denominator in velocity calculation.');
    end
    
    term1  = sqrt(mu .* p_min) ./ denom;
    factor = 1 - (r_mag ./ p_min) .* (1 - cos_dnu);
    
    % Compute v0 vectorized
    v0 = bsxfun(@times, term1, r - bsxfun(@times, factor, r0));
end