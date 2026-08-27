function [v1, v2, deltaV1, deltaV2, deltaV, flag, a, e] = lambertGauss(r1, v1_ini, r2, v2_fin, flightTime, dm, mu)
%==========================================================================
% lambertGauss: Solves Lambert's problem using Gauss' method for an
%               elliptic transfer between two position vectors.
%
% Inputs:
%   r1         - Initial position vector [3x1] (km)
%   v1_ini     - Actual initial velocity vector [3x1] (km/s)
%   r2         - Final position vector [3x1] (km)
%   v2_fin     - Actual final velocity vector [3x1] (km/s)
%   flightTime - Time of flight (s)
%   dm         - Direction of motion: 'S' short-way (< 180°), 'L' long-way (> 180°)
%   mu         - Gravitational parameter (km^3/s^2)
%
% Outputs:
%   v1      - Transfer velocity at r1 [3x1] (km/s)
%   v2      - Transfer velocity at r2 [3x1] (km/s)
%   deltaV1 - Required ΔV at departure (km/s)
%   deltaV2 - Required ΔV at arrival (km/s)
%   deltaV  - Total ΔV = deltaV1 + deltaV2 (km/s)
%   flag    - Status string: 'ok' or error description
%   a       - Semi-major axis of the transfer orbit (km)  (NaN if invalid)
%   e       - Eccentricity of the transfer orbit (-)      (NaN if invalid)
%==========================================================================

    %------------------------------ Config ---------------------------------
    tol             = 1e-10;      % Convergence tolerance for fixed-point iteration on y
    maxIter          = 100;       % Safety limit for iterations
    verify_fg_tol    = 1e-2;      % Tolerance for f*gdot - fdot*g ≈ 1 check
    small            = 1e-12;     % Small number for zero-guards

    %--------------------------- Input checks ------------------------------
    if nargin < 7
        error('lambertGauss: Not enough input arguments.');
    end

    % Ensure column vectors
    if size(r1,2) > size(r1,1), r1 = r1.'; end
    if size(r2,2) > size(r2,1), r2 = r2.'; end
    if size(v1_ini,2) > size(v1_ini,1), v1_ini = v1_ini.'; end
    if size(v2_fin,2) > size(v2_fin,1), v2_fin = v2_fin.'; end

    if numel(r1)~=3 || numel(r2)~=3 || numel(v1_ini)~=3 || numel(v2_fin)~=3
        error('lambertGauss: r1, r2, v1_ini, v2_fin must be 3x1 vectors.');
    end
    if ~(isscalar(mu) && mu>0)
        error('lambertGauss: mu must be a positive scalar.');
    end
    if ~(isscalar(flightTime) && flightTime>0)
        error('lambertGauss: flightTime must be a positive scalar.');
    end
    if ~ischar(dm) || ~ismember(upper(dm), {'S','L'})
        error('lambertGauss: dm must be ''S'' (short-way) or ''L'' (long-way).');
    end
    dm = upper(dm);

    %-------------------------- Initialization -----------------------------
    v1 = zeros(3,1);
    v2 = zeros(3,1);
    deltaV1 = NaN; deltaV2 = NaN; deltaV = NaN;
    a = NaN; e = NaN;

    %----------------------- Geometric precompute ---------------------------
    mag_r1 = norm(r1);
    mag_r2 = norm(r2);
    cos_deltanu = max(-1, min(1, dot(r1, r2) / (mag_r1 * mag_r2)));

    % Choose sign of sinΔν by short/long way
    if dm == 'S'
        sin_deltanu =  sqrt(max(0, 1.0 - cos_deltanu^2));
    else
        sin_deltanu = -sqrt(max(0, 1.0 - cos_deltanu^2));
    end

    deltanu = atan2(sin_deltanu, cos_deltanu);
    cos_half_deltanu = cos(0.5*deltanu);
    if abs(cos_half_deltanu) < 1e-12
        flag = 'Singular case: Δν ≈ 180° not supported by Gauss method';
        return;
    end

    sqrt_r1r2 = sqrt(mag_r1*mag_r2);

    %------------------ Gauss parameters (l, m for elliptic) ----------------
    l = (mag_r1 + mag_r2)/(4*sqrt_r1r2*cos_half_deltanu) - 0.5;

    denom_cubed = (2*sqrt_r1r2*cos_half_deltanu)^3;
    if abs(denom_cubed) < small
        flag = 'Invalid geometry: Denominator near zero';
        return;
    end
    m = (mu * flightTime^2) / denom_cubed;

    %---------------- Fixed-point solve for y (Moulton-like) ----------------
    y = 1.0;
    y_prev = Inf;
    iter = 0;

    while abs(y - y_prev) > tol && iter < maxIter
        x1 = m / (y^2) - l;

        % Series for x2 = 4/3*(1 + 6/5 x1 + 6*8/(5*7) x1^2 + 6*8*10/(5*7*9) x1^3 + 6*8*10*12/(5*7*9*11) x1^4)
        x1p = [x1, x1^2, x1^3, x1^4];
        coeff = [6/5, 6*8/(5*7), 6*8*10/(5*7*9), 6*8*10*12/(5*7*9*11)];
        x2 = (4/3) * (1 + sum(coeff .* x1p));

        y_prev = y;
        y = 1 + x2*(l + x1);
        iter = iter + 1;
    end

    if iter >= maxIter
        flag = 'No convergence solving Gauss equation for y';
        return;
    end

    %---------------------- Orbital parameters (p,a,e) ----------------------
    % From Gauss relations
    cos_deltaE2 = 1 - 2*x1;                         % cos(ΔE/2)
    sin2_term = max(0, 1.0 - cos_deltaE2^2);        % to avoid tiny negatives
    if dm=='S'
        sindeltaE2 = sqrt(sin2_term);
    else
        sindeltaE2 = -sqrt(sin2_term);
    end

    % Semi-latus rectum
    p = (y^2 * mag_r1^2 * mag_r2^2 * sin_deltanu^2) / (mu * flightTime^2);
    if ~(isfinite(p) && p>0)
        flag = 'Invalid transfer: p <= 0';
        return;
    end

    % Semi-major axis (elliptic)
    num_a = mag_r1 + mag_r2 - 2*sqrt_r1r2*cos_half_deltanu*cos_deltaE2;
    den_a = 2 * (sindeltaE2^2);
    if abs(den_a) < small
        flag = 'Invalid transfer: Denominator for a near zero';
        return;
    end
    a = num_a / den_a;

    if ~(isfinite(a) && a>0)
        flag = 'Invalid transfer: a <= 0 (Non-elliptic or degenerate)';
        return;
    end

    e = sqrt(max(0, 1 - p/a));  % clamp for small negative round-off
    if ~(isfinite(e) && e>=0 && e<1)
        flag = 'Invalid transfer: Eccentricity not in [0,1)';
        return;
    end

    %--------------------- f, g and time-derivatives ------------------------
    f    = 1.0 - (mag_r2/p) * (1.0 - cos_deltanu);
    g    = (mag_r1*mag_r2*sin_deltanu) / sqrt(mu*p);
    if abs(g) < small
        flag = 'Singular case: g ≈ 0 (Cannot form velocities)';
        return;
    end

    tan_half_deltanu = sin(0.5*deltanu) / cos_half_deltanu;
    fdot = sqrt(mu/p) * tan_half_deltanu * ((1.0 - cos_deltanu)/p - 1/mag_r2 - 1/mag_r1);
    gdot = 1.0 - (mag_r1/p) * (1.0 - cos_deltanu);

    % Consistency check f*gdot - fdot*g ≈ 1
    fg_rel = f*gdot - fdot*g;
    if abs(fg_rel - 1.0) > verify_fg_tol
        flag = sprintf('f*gdot - fdot*g = %.6f (expected ≈ 1)', fg_rel);
        % We still proceed, but mark the warning in flag.
    else
        flag = 'ok';
    end

    %---------------------- Transfer velocities v1, v2 ----------------------
    v1 = (r2 - f*r1) / g;
    v2 = (gdot*r2 - r1) / g;

    %---------------------------- ΔV accounting -----------------------------
    deltaV1 = norm(v1_ini - v1);
    deltaV2 = norm(v2 - v2_fin);
    deltaV  = deltaV1 + deltaV2;

    %---------------------- Final physical sanity checks --------------------
    if strcmp(flag,'ok')
        if e < 0 || e >= 1 || a <= 0 || p <= 0
            flag = 'Invalid orbital parameters after solution';
        end
    end
end