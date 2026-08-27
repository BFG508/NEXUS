function yp = zonalEquationMotion(y, J2, J3, Re, mu, doJ2, doJ3)
%==========================================================================
% zonalEquationMotion: Two-body equations of motion with optional J2 and J3
%                      perturbations. Returns the time derivative of the state.
%
% Inputs:
%   y    - State vector [position(3); velocity(3)]
%   J2   - J2 zonal harmonic coefficient (-)
%   J3   - J3 zonal harmonic coefficient (-)
%   Re   - Equatorial radius of the central body (km)
%   mu   - Gravitational parameter of the central body (km^3/s^2)
%   doJ2 - Boolean flag to include J2 perturbations (true/false)
%   doJ3 - Boolean flag to include J3 perturbations (true/false)
%
% Outputs:
%   yp   - Time derivative of the state vector [6x1]
%==========================================================================

    % Output initialization
    yp = zeros(6,1);

    % Kinematics: r' = v
    yp(1:3) = y(4:6);

    % Position vector and norm
    rv = y(1:3);
    r  = norm(rv);
    if r <= 0 || ~isfinite(r)
        error('eq_mov_J2:badState','Invalid position norm.');
    end

    % Two-body acceleration
    acc = -mu * rv / r^3;

    % Common scalars if any zonal term is requested
    if doJ2 || doJ3
        z = rv(3);
        s = z / r;                 % z/r
        r2 = r*r;                  
        r5 = r2*r2*r;
        r7 = r5*r2;
    end

    % J2 contribution
    if doJ2
        fJ2 = (3/2) * J2 * mu * Re^2 / r5;
        aJ2 = fJ2 * [ ...
            rv(1) * (5*s^2 - 1); ...
            rv(2) * (5*s^2 - 1); ...
            rv(3) * (5*s^2 - 3)  ...
        ];
        acc = acc + aJ2;
    end

    % J3 contribution
    if doJ3
        fJ3 = (5/2) * J3 * mu * Re^3 / r7;
        aJ3 = fJ3 * [ ...
            rv(1) * (7*s^3 - 3*s); ...
            rv(2) * (7*s^3 - 3*s); ...
            rv(3) * (6*s^2 - 7*s^4 - 3/5) ...
        ];
        acc = acc + aJ3;
    end

    % Dynamics: v' = acc
    yp(4:6) = acc;
end