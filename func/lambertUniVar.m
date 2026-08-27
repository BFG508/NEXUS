function [v1dv, v2dv, error, flag, loops] = lambertUniVar(r1, r2, v1, dm, df, nrev, tof, tbi, mu)
%==========================================================================
% lambertUniVar: Solves Lambert's problem using the universal-variable
%                formulation. Supports multi-revolution solutions and
%                low-/high-energy branches.
%
% Inputs:
%   r1   - Initial position vector ijk [3x1] (km)
%   r2   - Final   position vector ijk [3x1] (km)
%   v1   - Initial velocity vector ijk [3x1] (km/s)  (used in the 180° fallback)
%   dm   - Direction of motion: 'S' = short, 'L' = long
%   df   - Flight branch: 'L' = low energy, 'H' = high energy
%   nrev - Number of revolutions: 0,1,2,... (integer)
%   tof  - Time of flight (s)
%   tbi  - Lower-time seeds for multi-rev branches: [psi, tof] per revolution
%   mu   - Gravitational parameter (km^3/s^2)
%
% Outputs:
%   v1dv  - Transfer velocity at r1 [3x1] (km/s)
%   v2dv  - Transfer velocity at r2 [3x1] (km/s)
%   error - Error flag: 'ok', 'g did not converge', 'negative y', 'impossible180'
%   flag  - Consistency flag: 'ok' or 'error computing f and g'
%   loops - Number of Newton iterations performed
%==========================================================================

    %----------------------------- Parameters ------------------------------
    tol             = 1e-5;     % Convergence tolerance on time of flight
    maxIter         = 20;       % Max Newton iterations
    maxYNegAttempts = 10;       % Max attempts to fix negative y

    %----------------------------- Init ------------------------------------
    loops = 0;
    error = 'ok';
    flag  = 'Did not enter the loop';

    % Ensure column vectors
    if size(r1,2) > size(r1,1), r1 = r1.'; end
    if size(r2,2) > size(r2,1), r2 = r2.'; end
    if size(v1,2) > size(v1,1), v1 = v1.'; end

    v1dv = zeros(3,1);
    v2dv = zeros(3,1);

    % Normalize branch flags
    if isstring(dm), dm = char(dm); end
    if isstring(df), df = char(df); end

    %--------------------------- Input checks ------------------------------
    if nargin < 9
        builtin('error','Not enough input arguments.');
    end
    if numel(r1)~=3 || numel(r2)~=3 || numel(v1)~=3
        builtin('error','Vectors r1, r2, and v1 must have 3 elements.');
    end

    %------------------------- Geometry precompute -------------------------
    magr1 = norm(r1);
    magr2 = norm(r2);

    cosDeltaNu = dot(r1, r2) / (magr1 * magr2);
    cosDeltaNu = max(-1, min(1, cosDeltaNu));

    % A parameter (sign by short/long way)
    if strcmpi(dm,'L')   % long-way (>180°)
        A = -sqrt(magr1 * magr2 * (1.0 + cosDeltaNu));
    else           % short-way (<180°)
        A =  sqrt(magr1 * magr2 * (1.0 + cosDeltaNu));
    end

    %------------------------- Bracketing for psi --------------------------
    if nrev == 0
        lower = -16.0 * pi^2;            % allow hyperbolic/parabolic
        upper =  4.0 * pi^2;
    else
        lower = 4.0 * (nrev    )^2 * pi^2;
        upper = 4.0 * (nrev + 1)^2 * pi^2;
        if strcmpi(df,'H')
            upper = tbi(nrev, 1);
        else
            lower = tbi(nrev, 1);
        end
    end

    %--------------------------- Initial psi -------------------------------
    if nrev == 0
        psiOld = (log(tof) - 9.61202327) / 0.10918231; % empirical seed
        if psiOld > upper, psiOld = upper - pi; end
    else
        psiOld = lower + 0.5*(upper - lower);
    end

    %--------------------------- First eval --------------------------------
    [c2New, c3New] = findc2c3(psiOld);

    if abs(c2New) > tol
        y    = magr1 + magr2 + (A * (psiOld * c3New - 1.0) / sqrt(c2New));
        xOld = sqrt(y / c2New);
    else
        y    = magr1 + magr2;
        xOld = 0.0;
    end

    xOldCubed = xOld^3;
    dtOld     = (xOldCubed * c3New + A * sqrt(y)) / sqrt(mu);

    %----------------------- Main Newton iteration -------------------------
    if abs(A) > 0.2   % simple guard (A ~ 0 near 180°)
        yNegCount = 1;
        dtNew     = -10.0;

        while (abs(dtNew - tof) >= tol) && (loops < maxIter) && (yNegCount <= maxYNegAttempts)

            % y update
            if abs(c2New) > tol
                y = magr1 + magr2 + (A * (psiOld * c3New - 1.0) / sqrt(c2New));
            else
                y = magr1 + magr2;
            end

            % Fix negative y if needed
            if (A > 0.0) && (y < 0.0)
                yNegCount = 1;
                while (y < 0.0) && (yNegCount < maxYNegAttempts)
                    psiNew = 0.8 * (1.0 / c3New) * (1.0 - (magr1 + magr2) * sqrt(c2New) / A);
                    [c2New, c3New] = findc2c3(psiNew);
                    psiOld = psiNew;
                    lower  = psiOld;

                    if abs(c2New) > tol
                        y = magr1 + magr2 + (A * (psiOld * c3New - 1.0) / sqrt(c2New));
                    else
                        y = magr1 + magr2;
                    end
                    yNegCount = yNegCount + 1;
                end
            end

            loops = loops + 1;

            if yNegCount < maxYNegAttempts
                % Recompute x and new time
                if abs(c2New) > tol
                    xOld = sqrt(y / c2New);
                else
                    xOld = 0.0;
                end

                xCubed = xOld^3;
                dtNew  = (xCubed * c3New + A * sqrt(y)) / sqrt(mu);

                % c2', c3' wrt psi
                if abs(psiOld) > 1e-5
                    c2dot = 0.5/psiOld * (1.0 - psiOld * c3New - 2.0 * c2New);
                    c3dot = 0.5/psiOld * (c2New - 3.0 * c3New);
                else
                    % series expansion near parabolic case
                    c2dot = -1.0/factorial(4) + 2.0*psiOld/factorial(6) ...
                            - 3.0*psiOld^2/factorial(8) + 4.0*psiOld^3/factorial(10) ...
                            - 5.0*psiOld^4/factorial(12);
                    c3dot = -1.0/factorial(5) + 2.0*psiOld/factorial(7) ...
                            - 3.0*psiOld^2/factorial(9) + 4.0*psiOld^3/factorial(11) ...
                            - 5.0*psiOld^4/factorial(13);
                end

                % d t / d psi (Newton step)
                dtdpsi = ( xCubed * (c3dot - 3.0 * c3New * c2dot / (2.0 * c2New)) ...
                          + 0.125 * A * (3.0 * c3New * sqrt(y) / c2New + A / xOld) ) / sqrt(mu);

                psiNew = psiOld - (dtNew - tof) / dtdpsi;

                % Keep psi within [lower, upper] using bisection if needed
                if psiNew > upper || psiNew < lower
                    if strcmpi(df,'L') || (nrev == 0)
                        if dtOld < tof, lower = psiOld; else, upper = psiOld; end
                    else
                        if dtOld < tof, upper = psiOld; else, lower = psiOld; end
                    end
                    psiNew = 0.5*(upper + lower);
                end

                [c2New, c3New] = findc2c3(psiNew);
                psiOld = psiNew;
                dtOld  = dtNew;

                % Avoid premature "converged at first step"
                if (abs(dtNew - tof) < tol) && (loops == 1)
                    dtNew = tof - 1.0;
                end
            end

            yNegCount = 1; % reset
        end

        %-------------------- Finalization / velocities ---------------------
        if (loops >= maxIter) || (yNegCount >= maxYNegAttempts)
            error = 'g did not converge';
            if yNegCount >= maxYNegAttempts, error = 'Negative y'; end
        else
            f    = 1.0 - y / magr1;
            gdot = 1.0 - y / magr2;
            g    = A * sqrt(y / mu);
            fdot = sqrt(mu * y) * (-magr2 - magr1 + y) / (magr1 * magr2 * A);

            v1dv = (r2 - f*r1)   / g;
            v2dv = (gdot*r2 - r1)/ g;

            % Check f*gdot - fdot*g ≈ 1
            fgCheck = f * gdot - fdot * g;
            if fgCheck > 0.99 && fgCheck < 1.01
                flag = 'ok';
            else
                flag = 'Error computing f and g';
            end
        end

    else
        %--------------------- 180° singular transfer ----------------------
        error = 'Impossible 180° singular transfer';

        % 3D Hohmann-like fallback for half-period transfer
        aTx    = (mu * (tof / pi)^2)^(1.0/3.0);
        v1tMag = sqrt(2.0 * mu / magr1 - mu / aTx);
        v2tMag = sqrt(2.0 * mu / magr2 - mu / aTx);

        w     = cross(r1, v1);   wHat = w / norm(w);
        v1dir = cross(r1, wHat); v2dir = cross(r2, wHat);
        v1Hat = v1dir / norm(v1dir);
        v2Hat = v2dir / norm(v2dir);

        v1dv = -v1tMag * v1Hat;
        v2dv = -v2tMag * v2Hat;
    end
end