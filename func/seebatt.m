function seebatt_val = seebatt(v)
%==========================================================================
% seebatt: Battin's auxiliary continued-fraction helper function.
%
% Inputs:
%   v - Non-dimensional input
%
% Outputs:
%   seebatt_val - Auxiliary function value
%==========================================================================
    c = [ ...
                 0.2,     9.0/35.0,    16.0/63.0,    25.0/99.0,   36.0/143.0, ...
          49.0/195.0,   64.0/255.0,   81.0/323.0,  100.0/399.0,  121.0/483.0, ...
         144.0/575.0,  169.0/675.0,  196.0/783.0,  225.0/899.0, 256.0/1023.0, ...
        289.0/1155.0, 324.0/1295.0, 361.0/1443.0, 400.0/1599.0, 441.0/1763.0, ...
        484.0/1935.0];
    tol = 1e-8;

    sqrt1pv = sqrt(1.0 + v);
    eta     = v / (1.0 + sqrt1pv)^2;

    % Forward pass
    delOld  = 1.0;
    termOld = c(1);
    sum1    = termOld;
    for i = 2:numel(c)
        if abs(termOld) <= tol
            break;
        end
        del    = 1.0 / (1.0 + c(i) * eta * delOld);
        term   = termOld * (del - 1.0);
        sum1   = sum1 + term;
        delOld = del;
        termOld= term;
    end

    % New coefficients for backward fraction
    c2 = [ ...
               9.0/7.0,    16.0/63.0,    25.0/99.0,   36.0/143.0,   49.0/195.0, ...
            64.0/255.0,   81.0/323.0,  100.0/399.0,  121.0/483.0,  144.0/575.0, ...
           169.0/675.0,  196.0/783.0,  225.0/899.0, 256.0/1023.0, 289.0/1155.0, ...
          324.0/1295.0, 361.0/1443.0, 400.0/1599.0, 441.0/1763.0, 484.0/1935.0 ];
    ktr = numel(c2);

    term2 = 1.0 + c2(ktr) * eta;
    for i = 1:(ktr-2)
        sum2  = c2(ktr - i) * eta / term2;
        term2 = 1.0 + sum2;
    end

    seebatt_val = 8.0 * (1.0 + sqrt1pv) / ...
                  ( 3.0 + (1.0 / (5.0 + eta + (9.0/7.0) * eta / term2)) );
end