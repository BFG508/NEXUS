function [v1t, v2t, errFlag] = lambertb(r1, r2, v1, dm, de, nrev, dtsec, mu)
%==========================================================================
% lambertb: Solves Lambert's problem using Battin's method with support for
%           multi-revolution and low/high-energy branches.
%
% Inputs:
%   r1    - Initial position vector ijk [3x1] (km)
%   r2    - Final   position vector ijk [3x1] (km)
%   v1    - Initial velocity vector ijk [3x1] (km/s) [if available]
%   dm    - Direction of motion: 'L' = long (>180°), 'S' = short (<180°)
%   de    - Energy branch: 'L' = low energy, 'H' = high energy (only if nrev >= 1)
%   nrev  - Number of revolutions: 0, 1, 2, ... (integer)
%   dtsec - Time of flight between r1 and r2 (s)
%   mu    - Gravitational parameter (km^3/s^2)
%
% Outputs:
%   v1t    - Transfer velocity at r1 [3x1] (km/s)
%   v2t    - Transfer velocity at r2 [3x1] (km/s)
%   errFlag- Error flag: 'ok', 'no convergence', 'parameter error', 'invalid orbital parameters'
%==========================================================================

    %------------------------------ Settings -------------------------------
    tolStd  = 1e-8;        % Convergence tolerance
    maxIterStd  = 30;      % Max iterations for standard branch
    maxIterHigh = 20;      % Max iterations for high-energy branch

    %------------------------------ Init -----------------------------------
    errFlag = 'ok';
    y = 0.0;

    % Default outputs (in case of hard failure)
    v1t = [1000; 1000; 1000];
    v2t = [1000; 1000; 1000];

    % Ensure column vectors
    if size(r1,2) > size(r1,1), r1 = r1.'; end
    if size(r2,2) > size(r2,1), r2 = r2.'; end
    if size(v1,2) > size(v1,1), v1 = v1.'; end

    %--------------------------- Input checks ------------------------------
    if nargin < 8
        builtin('error','Not enough input arguments.');
    end
    if numel(r1) ~= 3 || numel(r2) ~= 3 || numel(v1) ~= 3
        errFlag = 'Parameter error';
        return;
    end

    %------------------------ Geometry (Battin) ----------------------------
    r1mag = norm(r1);
    r2mag = norm(r2);

    cosDeltaNu = dot(r1, r2) / (r1mag * r2mag);
    cosDeltaNu = max(-1, min(1, cosDeltaNu));

    rcrossr     = cross(r1, r2);
    sinDeltaNu  = norm(rcrossr) / (r1mag * r2mag);
    if dm == 'S'               % short-way
        % keep positive
    else                       % long-way
        sinDeltaNu = -sinDeltaNu;
    end

    dnu = atan2(sinDeltaNu, cosDeltaNu);
    if dnu < 0.0, dnu = 2.0*pi + dnu; end

    chord = sqrt(r1mag^2 + r2mag^2 - 2.0 * r1mag * r2mag * cosDeltaNu);
    s     = 0.5 * (r1mag + r2mag + chord);

    rRatio = r2mag / r1mag;
    eps    = rRatio - 1.0;

    lam = (sqrt(r1mag * r2mag) / s) * cos(0.5*dnu);
    L   = ((1.0 - lam) / (1.0 + lam))^2;
    m   = 8.0 * mu * dtsec^2 / ( s^3 * (1.0 + lam)^6 );

    %------------------------ Initial estimate -----------------------------
    if nrev > 0
        xn = 1.0 + 4.0*L;    % multi-rev seed
    else
        xn = L;              % 0-rev: L (elliptic); 0 also covers parabolic/hyperbolic
    end

    %------------------------ High-energy branch ---------------------------
    if (de == 'H') && (nrev > 0)
        xn    = 1e-20;           % re-seed for high energy
        x     = 10.0;
        loops = 1;

        while (abs(xn - x) >= tolStd) && (loops <= maxIterHigh)
            x = xn;

            temp  = 1.0 / (2.0 * (L - x^2));
            rtX   = sqrt(x);
            temp2 = (nrev * pi * 0.5 + atan(rtX)) / rtX;

            h1 = temp * (L + x) * (1.0 + 2.0*x + L);
            h2 = temp * m * rtX * ( (L - x^2) * temp2 - (L + x) );

            b = 0.25 * 27.0 * h2 / ((rtX * (1.0 + h1))^3);

            if b < 0.0
                f = 2.0 * cos((1.0/3.0) * acos(sqrt(b + 1.0)));
            else
                A = (sqrt(b) + sqrt(b + 1.0))^(1.0/3.0);
                f = A + 1.0/A;
            end

            y = (2.0/3.0) * rtX * (1.0 + h1) * (sqrt(b + 1.0)/f + 1.0);

            sqrtTerm = sqrt( (m/(y^2) - (1.0 + L))^2 - 4.0*L );
            xn = 0.5 * ( (m/(y^2) - (1.0 + L)) - sqrtTerm );

            if isnan(y)
                xn = 1.0;
            end
            loops = loops + 1;
        end

        x = xn;

        a = s * (1.0 + lam)^2 * (1.0 + x) * (L + x) / (8.0 * x);
        p = (2.0 * r1mag * r2mag * (1.0 + x) * sin(0.5*dnu)^2) ...
            / ( s * (1 + lam)^2 * (L + x) );

        if a > 0 && p > 0
            ecc = sqrt(1.0 - p/a);
        else
            errFlag = 'Invalid orbital parameters';
            return;
        end

        [v1t, v2t] = lambhodograph(r1, v1, r2, p, ecc, dnu, dtsec);

    else
        %---------------------- Standard branch ----------------------------
        loops = 1;
        x = 10.0;

        while (abs(xn - x) >= tolStd) && (loops <= maxIterStd)
            x = xn;

            if nrev > 0
                % Multi-rev expressions
                temp  = 1.0 / ((1.0 + 2.0*x + L) * (4.0*x^2));
                temp1 = (nrev * pi * 0.5 + atan(sqrt(x))) / sqrt(x);

                h1 = temp * (L + x)^2 * ( 3.0*(1.0 + x)^2 * temp1 - (3.0 + 5.0*x) );
                h2 = temp * m * ( (x^2 - x*(1.0 + L) - 3.0*L) * temp1 + (3.0*L + x) );

            else
                % 0-rev branch via Seebatt
                sx    = seebatt(x);
                denom = 1.0 / ((1.0 + 2.0*x + L) * (4.0*x + sx*(3.0 + x)));

                h1 = (L + x)^2 * (1.0 + 3.0*x + sx) * denom;
                h2 = m * (x - L + sx) * denom;
            end

            b  = 0.25 * 27.0 * h2 / ((1.0 + h1)^3);
            u  = 0.5 * b / (1.0 + sqrt(1.0 + b));
            k2 = kbatt(u);

            y = ((1.0 + h1) / 3.0) * ( 2.0 + sqrt(1.0 + b) / (1.0 + 2.0*u*k2^2) );

            sqrtTerm = sqrt( ((1.0 - L) * 0.5)^2 + m/(y^2) );
            xn = sqrtTerm - 0.5*(1.0 + L);

            if isnan(y)
                y = 75.0; xn = 1.0;
            end

            loops = loops + 1;
        end

        if loops < maxIterStd
            % Thompson focal parameter
            p = (2.0 * r1mag * r2mag * y^2 * (1.0 + x)^2 * sin(0.5*dnu)^2) ...
                / ( m * s * (1 + lam)^2 );

            % Eccentricity (Battin form)
            sinHalf2 = sin(0.5*dnu)^2;
            numE = eps^2 + 4.0*(r2mag/r1mag)*sinHalf2 * ((L - x)/(L + x))^2;
            denE = eps^2 + 4.0*(r2mag/r1mag)*sinHalf2;

            if denE > 0
                ecc = sqrt(numE / denE);
            else
                errFlag = 'Invalid orbital parameters';
                return;
            end

            [v1t, v2t] = lambhodograph(r1, r2, p, ecc, dnu, mu);
        else
            errFlag = 'No convergence';
        end
    end
end
