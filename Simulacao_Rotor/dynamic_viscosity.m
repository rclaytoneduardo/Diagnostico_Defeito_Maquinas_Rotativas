function [Bearing_nu] = dynamic_viscosity(Bearing_Tc)

% [Bearing_nu] = dynamic_viscosity(Bearing_Tc)
%
% Calculates the dynamic viscosity  which is temperature dependent
%
% Bearing_Tc    is the oil temperature in degrees Celsius 
%
% This function follows the calculations of the book:
% Applied Tribology: bearing design and lubrication
% by Khonsari and Booser (2008)

% A and B are coefficients for Oil ISO VG 68
A = 9.098591005711736;
B = 3.542395107199138;

Tk = Bearing_Tc+273.1;

v = 10^(10^(A-B*log10(Tk))) - 0.7;
rho15_6C = 0.876;
rho = rho15_6C*(1-0.00063*(Bearing_Tc-15.6));

Bearing_nu = 1e-3*v*rho;

end