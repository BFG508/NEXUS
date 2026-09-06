function tbi = computeTBI(nmax, a0, a, mu)
%==========================================================================
% computeTBI: Computes lower-bound seed values for multi-revolution Lambert
%             branches. Returns (psi, estimated minimum time of flight) pairs
%             for n = 1..nmax, to initialize multi-rev solvers.
%
% Inputs:
%   nmax - Maximum number of revolutions to compute (positive integer)
%   a0   - Initial orbit semi-major axis (km)
%   a    - Final   orbit semi-major axis (km)
%   mu   - Gravitational parameter (km^3/s^2)
%
% Outputs:
%   tbi  - [nmax x 2] array where:
%          tbi(n,1) = seed psi value for n revolutions (-)
%          tbi(n,2) = estimated lower-bound time of flight for n rev (s)
%==========================================================================

    %----------------------------- Validation ------------------------------
    if nargin < 4
        error('computeTBI:insufficientInputs', 'Not enough input arguments.');
    end

    if ~isscalar(nmax) || nmax <= 0 || floor(nmax) ~= nmax
        error('computeTBI:badNmax', 'nmax must be a positive integer.');
    end
    if ~isscalar(a0) || ~isscalar(a) || a0 <= 0 || a <= 0
        error('computeTBI:badA', 'a0 and a must be positive scalars (km).');
    end
    if ~isscalar(mu) || mu <= 0
        error('computeTBI:badMu', 'mu must be a positive scalar (km^3/s^2).');
    end

    %--------------------------- Output matrix -----------------------------
    % [nmax x 2]: column 1 = psi seed, column 2 = TOF lower-bound estimate
    tbi = zeros(nmax, 2);

    %--------------------------- Pre-computations --------------------------
    % Average semi-major axis between initial and final orbits (heuristic)
    a_avg = (a0 + a) / 2;
    if a_avg <= 0
        error('computeTBI:badAavg', 'Average semi-major axis must be positive.');
    end

    % Mean orbital period from Kepler's third law: T = 2*pi*sqrt(a^3/mu)
    T_mean = 2 * pi * sqrt(a_avg^3 / mu);

    %----------------------- Loop over revolutions -------------------------
    for n = 1:nmax
        % Seed for the universal-variable parameter psi at the n-rev branch.
        % Note: psi = 4*pi^2*n^2 is a heuristic upper-limit/seed, not the
        % exact geometric minimum; it is intended to bracket/initialize.
        psi = 4 * pi^2 * n^2;

        % Lower-bound TOF estimate (heuristic): n full revs + half rev,
        % then halved due to transfer geometry considerations.
        tof_min_est = (n + 0.5) * T_mean / 2;

        % Store results
        tbi(n, 1) = psi;
        tbi(n, 2) = tof_min_est;
    end

    %----------------------------- Sanity check ----------------------------
    % Ensure TOF estimates are monotonically increasing with n
    if nmax > 1
        dT = diff(tbi(:,2));
        if any(dT <= 0)
            warning('computeTBI:nonMonotonicTOF', ...
                'Estimated TOF is not strictly increasing with n.');
        end
    end
end