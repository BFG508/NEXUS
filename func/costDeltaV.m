function [J, nrev_best] = costDeltaV(tvec, r0_base, v0_ini_base, r_base, v_fin_base, a0, af, T_media, tf, mu)
%==========================================================================
% costDeltaV: Objective function that computes total delta-V for given
%             maneuver times, scanning a small range of revolution counts.
%
% Inputs:
%   tvec        - [t1, t2] (s)
%   r0_base     - Baseline initial position [3x1] (km)
%   v0_ini_base - Baseline initial velocity [3x1] (km/s)
%   r_base      - Baseline final position   [3x1] (km)
%   v_fin_base  - Baseline final velocity   [3x1] (km/s)
%   a0, af      - Initial/final semi-major axis (km)
%   T_media     - Mean orbital period (s)
%   tf          - Total mission time (s)
%   mu          - Gravitational parameter (km^3/s^2)
%
% Outputs:
%   J           - Objective value (total delta-V in km/s, or penalty)
%   nrev_best   - Best revolution count (>=0), or -1 if invalid
%==========================================================================

    % Extract times
    t1 = tvec(1);
    t2 = tvec(2);

    % Penalties
    highPenalty   = 1e5;
    mediumPenalty = 1e3;

    % Basic feasibility
    if t2 <= t1 || t1 < 0 || t2 > tf
        J = highPenalty; nrev_best = -1; return;
    end

    tof = t2 - t1;
    if tof <= 0
        J = highPenalty; nrev_best = -1; return;
    end

    % Propagate to maneuver epochs (Keplerian)
    try
        [r0_new, v0_new, ~] = kepler(r0_base, v0_ini_base, t1,  mu);
        [r_new,  v_new,  ~] = kepler(r_base,   v_fin_base,  -(tf - t2), mu);
    catch
        J = highPenalty; nrev_best = -1; return;
    end

    % Estimated revolution window from TOF
    n_est = tof / T_media;
    n_min = max(0, floor(n_est - 0.5));
    n_max = ceil(n_est + 0.5);
    n_max = min(n_max, 5);  % cap for efficiency

    % Scan short/long way per revolution count
    dv_best   = inf;
    nrev_best = -1;

    for nrev = n_min:n_max
        try
            if nrev > 0
                tbi = computeTBI(nrev, a0, af, mu);  % seeds for multi-rev
            else
                tbi = [];
            end

            % Short-way
            [v0_S, v_S, errS, flagS] = lambertUniVar( ...
                r0_new, r_new, v0_new, 'S', 'L', nrev, tof, tbi, mu);
            if strcmp(errS,'ok') && strcmp(flagS,'ok')
                dV_S = norm(v0_S - v0_new) + norm(v_new - v_S);
            else
                dV_S = inf;
            end

            % Long-way
            [v0_L, v_L, errL, flagL] = lambertUniVar( ...
                r0_new, r_new, v0_new, 'L', 'L', nrev, tof, tbi, mu);
            if strcmp(errL,'ok') && strcmp(flagL,'ok')
                dV_L = norm(v0_L - v0_new) + norm(v_new - v_L);
            else
                dV_L = inf;
            end

            % Pick better branch
            if isfinite(dV_S) || isfinite(dV_L)
                dV_curr = min(dV_S, dV_L);
                if dV_curr > 0 && isfinite(dV_curr) && dV_curr < dv_best
                    dv_best   = dV_curr;
                    nrev_best = nrev;
                end
            end
        catch
            % Skip on any solver error
            continue;
        end
    end

    % Final objective
    if isfinite(dv_best) && dv_best > 0
        J = dv_best;
    else
        J = mediumPenalty;
        nrev_best = -1;
    end
end