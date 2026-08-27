function optimResults = optimizationSimplex(r0_base, r_base, v0_ini_base, v_fin_base, a0, af, tf, initial_guesses, T_mean, mu)
%==========================================================================
% optimizationSimplex: Nelder–Mead (simplex) timing optimization to
%   minimize total delta-V for a two-burn Lambert transfer. Scans multiple
%   initial guesses and considers different revolution counts.
%
% Inputs:
%   r0_base         - Baseline initial position [3x1] (km)
%   r_base          - Baseline final position   [3x1] (km)
%   v0_ini_base     - Baseline initial velocity [3x1] (km/s)
%   v_fin_base      - Baseline final velocity   [3x1] (km/s)
%   a0              - Initial semi-major axis (km)
%   af              - Final   semi-major axis (km)
%   tf              - Total mission time (s)
%   initial_guesses - Matrix of initial guesses [N x 2] (s): [t1, t2]
%   T_mean          - Mean orbital period (s)
%   mu              - Gravitational parameter (km^3/s^2)
%
% Outputs:
%   optim_results - [M x 4] valid solutions:
%                   [ t1 (s), t2 (s), total delta-V (km/s), optimal nrev ]
%==========================================================================

    %---------------------------- Input checks -----------------------------
    if nargin < 10
        error('optimizationSimplex: Not enough input arguments');
    end
    if numel(r0_base)~=3 || numel(r_base)~=3 || numel(v0_ini_base)~=3 || numel(v_fin_base)~=3
        error('Position and velocity vectors must have 3 elements');
    end
    if size(initial_guesses,2) ~= 2
        error('initial_guesses must be an N x 2 matrix [t1, t2]');
    end
    if a0 <= 0 || af <= 0 || tf <= 0 || T_mean <= 0 || mu <= 0
        error('Physical parameters must be positive');
    end

    % Ensure column vectors
    if size(r0_base,2) > size(r0_base,1), r0_base = r0_base.'; end
    if size(r_base,   2) > size(r_base,   1), r_base    = r_base.';    end
    if size(v0_ini_base,2)>size(v0_ini_base,1), v0_ini_base = v0_ini_base.'; end
    if size(v_fin_base, 2)>size(v_fin_base,  1), v_fin_base  = v_fin_base.';  end

    %------------------------- Optimization options ------------------------
    max_fun_evals = 1e4;
    tol_x          = 1e-6;
    tol_fun        = 1e-6;
    penalty_medium = 1e3;

    % Objective function (returns [J, nrev_best])
    fun_obj = @(tvec) costDeltaV(tvec, r0_base, v0_ini_base, r_base, ...
                                 v_fin_base, a0, af, T_mean, tf, mu);

    %---------------------------- Diagnostics ------------------------------
    fprintf('=== SIMPLEX OPTIMIZATION STARTED ===\n');
    fprintf('Initial guesses: %d\n', size(initial_guesses,1));
    fprintf('Total mission time:     %.2f s (%.2f min)\n', tf, tf/60);
    fprintf('Mean orbital period:    %.2f s (%.2f min)\n', T_mean, T_mean/60);
    fprintf('Tolerances: TolX = %.0e, TolFun = %.0e\n', tol_x, tol_fun);
    fprintf('====================================\n\n');

    %------------------------------- Loop ----------------------------------
    optimResults = [];
    n_guesses = size(initial_guesses, 1);

    for i = 1:n_guesses
        fprintf('Processing initial guess %d/%d: [%.1f, %.1f] s\n', ...
                i, n_guesses, initial_guesses(i,1), initial_guesses(i,2));

        x0 = initial_guesses(i, :);

        % Quick validity check for the guess
        if x0(2) <= x0(1) || x0(1) < 0 || x0(2) > tf
            fprintf('  Warning: invalid initial guess — skipping\n\n');
            continue;
        end

        options = optimset('MaxFunEvals', max_fun_evals, ...
                           'TolX', tol_x, ...
                           'TolFun', tol_fun, ...
                           'Display', 'off', ...
                           'MaxIter', 500);

        try
            [x_opt, fval] = fminsearch(@(t) fun_obj(t), x0, options);

            % Re-evaluate to retrieve best nrev
            [~, nrev_check] = fun_obj(x_opt);

            % Validation criteria
            valid = fval > 0 && fval < penalty_medium && ...
                    x_opt(2) > x_opt(1) && x_opt(1) > 0 && x_opt(2) < tf && ...
                    nrev_check >= 0;

            if valid
                optimResults(end+1, :) = [x_opt(1), x_opt(2), fval, nrev_check];
                fprintf('  ✓ Valid solution:\n');
                fprintf('    t1 = %.2f s, t2 = %.2f s\n', x_opt(1), x_opt(2));
                fprintf('    Delta-V = %.4f km/s, nrev = %d\n\n', fval, nrev_check);
            else
                fprintf('  ✗ Rejected by validation\n');
                if fval >= penalty_medium
                    fprintf('    Reason: Non-convergence (fval = %.0e)\n', fval);
                elseif x_opt(2) <= x_opt(1)
                    fprintf('    Reason: Times not ordered\n');
                elseif x_opt(1) <= 0 || x_opt(2) >= tf
                    fprintf('    Reason: Times out of bounds\n');
                elseif nrev_check < 0
                    fprintf('    Reason: Invalid revolution count\n');
                end
                fprintf('\n');
            end

        catch ME
            fprintf('  ✗ Optimization error: %s\n\n', ME.message);
        end
    end

    %----------------------------- Results ---------------------------------
    if isempty(optimResults)
        warning('optimizationSimplex: No valid solutions found');
        fprintf('SUGGESTIONS:\n');
        fprintf('- Check initial guesses\n');
        fprintf('- Relax optimization tolerances\n');
        fprintf('- Revisit orbital parameters\n');
        return;
    end

    % Sort by total delta-V ascending
    [~, idx] = sort(optimResults(:,3));
    optimResults = optimResults(idx, :);

    fprintf('=== OPTIMIZATION RESULTS ===\n');
    fprintf('Valid solutions: %d\n', size(optimResults,1));
    fprintf('Best solution:\n');
    fprintf('  t1 = %.2f s (%.2f min)\n', optimResults(1,1), optimResults(1,1)/60);
    fprintf('  t2 = %.2f s (%.2f min)\n', optimResults(1,2), optimResults(1,2)/60);
    fprintf('  Transfer time = %.2f s (%.2f min)\n', ...
            optimResults(1,2)-optimResults(1,1), (optimResults(1,2)-optimResults(1,1))/60);
    fprintf('  Total delta-V = %.4f km/s\n', optimResults(1,3));
    fprintf('  Revolutions   = %d\n', optimResults(1,4));

    if size(optimResults,1) > 1
        fprintf('\nDelta-V range: %.4f – %.4f km/s\n', ...
                min(optimResults(:,3)), max(optimResults(:,3)));
        fprintf('Improvement vs. worst: %.2f%%\n', ...
                100*(max(optimResults(:,3)) - min(optimResults(:,3)))/max(optimResults(:,3)));
    end
    fprintf('=============================\n');
end
