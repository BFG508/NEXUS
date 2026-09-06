function kbatt_val = kbatt(v)
%==========================================================================
% kbatt: Battin's continued-fraction helper function K(v).
%
% Inputs:
%   v - Non-dimensional input
%
% Outputs:
%   kbatt_val - Value of K(v)
%==========================================================================
    d = [ ...
               1.0/3.0,      4.0/27.0,       8.0/27.0,        2.0/9.0,      22.0/81.0, ...
           208.0/891.0,  340.0/1287.0,   418.0/1755.0,   598.0/2295.0,   700.0/2907.0, ...
          928.0/3591.0, 1054.0/4347.0,  1330.0/5175.0,  1480.0/6075.0,  1804.0/7047.0, ...
         1978.0/8091.0, 2350.0/9207.0, 2548.0/10395.0, 2968.0/11655.0, 3190.0/12987.0, ...
        3658.0/14391.0 ];
    tol = 1e-8;
    ktr = numel(d);

    % Forward pass
    sum1    = d(1);
    delOld  = 1.0;
    termOld = d(1);
    for i = 2:ktr
        if abs(termOld) <= tol
            break; 
        end
        del    = 1.0 / (1.0 + d(i) * v * delOld);
        term   = termOld * (del - 1.0);
        sum1   = sum1 + term;
        delOld = del;
        termOld= term;
    end

    % Backward continued fraction
    term2 = 1.0 + d(ktr) * v;
    for i = 1:(ktr-2)
        sum2  = d(ktr - i) * v / term2;
        term2 = 1.0 + sum2;
    end
    kbatt_val = d(1) / term2;
end