function [c2, c3] = findc2c3(psi)
%==========================================================================
% findc2c3: Computes the Stumpff functions C(psi) and S(psi) used in the
%           universal-variable formulation.
%
% Inputs:
%   psi - Universal variable parameter (non-dimensional), scalar or array
%
% Outputs:
%   c2  - Stumpff C(psi), same size as psi
%   c3  - Stumpff S(psi), same size as psi
%==========================================================================
    c2 = zeros(size(psi));
    c3 = zeros(size(psi));

    % Elliptic (psi > 1e-6)
    idx_ell = psi > 1e-6;
    if any(idx_ell, 'all')
        p_ell = psi(idx_ell);
        spsi = sqrt(p_ell);
        c2(idx_ell) = (1 - cos(spsi)) ./ p_ell;
        c3(idx_ell) = (spsi - sin(spsi)) ./ (spsi.^3);
    end

    % Hyperbolic (psi < -1e-6)
    idx_hyp = psi < -1e-6;
    if any(idx_hyp, 'all')
        p_hyp = psi(idx_hyp);
        spsi = sqrt(-p_hyp);
        c2(idx_hyp) = (1 - cosh(spsi)) ./ p_hyp;
        c3(idx_hyp) = (sinh(spsi) - spsi) ./ (spsi.^3);
    end

    % Near-parabolic (abs(psi) <= 1e-6)
    idx_par = abs(psi) <= 1e-6;
    if any(idx_par, 'all')
        p_par = psi(idx_par);
        c2_par = 1/2 * ones(size(p_par));
        c3_par = 1/6 * ones(size(p_par));
        
        idx_taylor = abs(p_par) > 1e-12;
        if any(idx_taylor, 'all')
            p_taylor = p_par(idx_taylor);
            psi2 = p_taylor.^2; 
            psi3 = p_taylor.^3; 
            psi4 = p_taylor.^4;
            c2_par(idx_taylor) = 1/2 - p_taylor/24 + psi2/720 - psi3/40320 + psi4/3628800;
            c3_par(idx_taylor) = 1/6 - p_taylor/120 + psi2/5040 - psi3/362880 + psi4/39916800;
        end
        c2(idx_par) = c2_par;
        c3(idx_par) = c3_par;
    end
end
