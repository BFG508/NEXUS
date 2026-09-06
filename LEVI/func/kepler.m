function [r_f, v_f, errFlag] = kepler(r0, v0, t, mu)
%==========================================================================
% kepler: Universal-variable Keplerian propagator. Propagates an initial
%         state (r0,v0) by time t under two-body dynamics.
%
% Inputs:
%   r0 - Initial position vector [3xN] (km)
%   v0 - Initial velocity vector [3xN] (km/s)
%   t  - Propagation time (s) (scalar or [1xN])
%   mu - Gravitational parameter (km^3/s^2)
%
% Outputs:
%   r_f    - Final position vector [3xN] (km)
%   v_f    - Final velocity vector [3xN] (km/s)
%   errFlag- 'ok' or error description
%==========================================================================
    errFlag = 'ok';
    if nargin < 4
        errFlag = 'insufficient inputs';
        r_f = r0; v_f = v0; return;
    end

    if size(r0,1) ~= 3
        if size(r0,2) == 3, r0 = r0.'; else, error('r0 must be 3xN'); end
    end
    if size(v0,1) ~= 3
        if size(v0,2) == 3, v0 = v0.'; else, error('v0 must be 3xN'); end
    end
    
    N = size(r0, 2);
    if isscalar(t), t = repmat(t, 1, N); end
    
    r_f = r0; 
    v_f = v0;
    
    active_t = abs(t) >= 1e-12;
    if ~any(active_t)
        return;
    end

    tol = 1e-8;
    maxIter = 50;

    r0m  = sqrt(sum(r0.^2, 1)); % vecnorm(r0, 2, 1) fallback for older versions
    v0m  = sqrt(sum(v0.^2, 1));
    vr0  = sum(r0 .* v0, 1) ./ r0m;
    alpha = 2 ./ r0m - v0m.^2 ./ mu;

    % Initial guess for chi
    chi = zeros(1, N);
    
    idx_ell = alpha > 1e-8;
    if any(idx_ell)
        chi(idx_ell) = sqrt(mu) .* abs(alpha(idx_ell)) .* t(idx_ell);
    end
    
    idx_hyp = alpha < -1e-8;
    if any(idx_hyp)
        a_hyp = 1 ./ alpha(idx_hyp);
        inside = -2 * mu .* alpha(idx_hyp) .* t(idx_hyp) ./ ...
                 (vr0(idx_hyp) + sign(t(idx_hyp)) .* sqrt(-mu ./ a_hyp) .* (1 - r0m(idx_hyp) .* alpha(idx_hyp)));
        inside = max(inside, 1e-12);
        chi(idx_hyp) = sign(t(idx_hyp)) .* sqrt(-a_hyp) .* log(inside);
    end
    
    idx_par = ~(idx_ell | idx_hyp);
    if any(idx_par)
        chi(idx_par) = sqrt(mu) .* t(idx_par) ./ max(1.0, r0m(idx_par));
    end

    chi_old = zeros(1, N); 
    it = 0;
    
    active = active_t;
    
    while any(active) && it < maxIter
        it = it + 1;
        chi_old(active) = chi(active);

        z = alpha(active) .* chi(active).^2;
        [C, S] = findc2c3(z);

        rmag = chi(active).^2 .* C + vr0(active)/sqrt(mu) .* chi(active) .* (1 - z.*S) + r0m(active) .* (1 - z.*C);
        F    = chi(active).^3 .* S + vr0(active)/sqrt(mu) .* chi(active).^2 .* C + r0m(active) .* chi(active) .* (1 - z.*S) - sqrt(mu).*t(active);
        dF   = rmag;  % derivative is the current range

        chi(active) = chi(active) - F ./ dF;
        active(active) = abs(chi(active) - chi_old(active)) > tol;
    end

    if it >= maxIter
        errFlag = 'Kepler propagation did not converge for some inputs';
    end

    z = alpha .* chi.^2;
    [C, S] = findc2c3(z);

    f = 1 - (chi.^2 ./ r0m) .* C;
    g = t - (chi.^3 ./ sqrt(mu)) .* S;

    % Update only those where t is non-zero
    r_f(:, active_t) = f(active_t) .* r0(:, active_t) + g(active_t) .* v0(:, active_t);
    rfm = sqrt(sum(r_f.^2, 1));

    fdot = (sqrt(mu) ./ (rfm .* r0m)) .* (z.*S - 1) .* chi;
    gdot = 1 - (chi.^2 ./ rfm) .* C;

    v_f(:, active_t) = fdot(active_t) .* r0(:, active_t) + gdot(active_t) .* v0(:, active_t);

    % Consistency check
    check = abs(f .* gdot - fdot .* g - 1);
    if any(check(active_t) > 1e-2)
        errFlag = 'f*gdot - fdot*g deviation detected';
    end
end