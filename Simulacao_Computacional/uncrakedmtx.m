function [K_uce] = uncrakedmtx(a,Le,E,inertia)

K_uce = [12     0           0         6*Le  -12     0           0         6*Le;
        0    12        -6*Le           0    0   -12        -6*Le           0;
        0  -6*Le (4+a)*Le*Le           0    0   6*Le (2-a)*Le*Le           0;
      6*Le     0           0 (4+a)*Le*Le -6*Le     0           0 (2-a)*Le*Le;
      -12     0           0        -6*Le   12     0           0        -6*Le;
        0   -12         6*Le           0    0    12         6*Le           0;
        0  -6*Le (2-a)*Le*Le           0    0   6*Le (4+a)*Le*Le           0;
      6*Le     0           0 (2-a)*Le*Le -6*Le     0           0 (4+a)*Le*Le];
K_uce = E*inertia*K_uce/( (1+a)*Le^3 );

end