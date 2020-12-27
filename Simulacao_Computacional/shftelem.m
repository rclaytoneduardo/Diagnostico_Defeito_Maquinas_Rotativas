function [M0e,C1e,K0e,K1e,Kte] = shftelem(Shaft_Type,L,outer_diameter,inner_diameter,E,G,rho,AxialForce,Torque);
%
%  function shftelem.m
%
%     [M0e,C1e,K0e,K1e] = shftelem(Shaft_Type,L,outer_diameter,inner_diameter,E,G,rho,AxialForce);
%
%  This function generates the element matrices for a circular shaft
%  element.
%
%  Both Euler and	Timoshenko beam theory included
%
%    K0e  is the returned stiffness matrix
%    C1e  is the returned gyroscopic matrix
%    M0e  is the returned mass matrix
%    K1e  is the returned speed dependent contribution to the 
%         stiffness matrix due to the internal damping
%
%    Shaft_Type       determines which effects are modelled 
%    L                is the length of the element
%    outer_diameter   is the outer diameter of the shaft
%    inner_diameter   is the inner diameter of the shaft
%    E                is the Young's modulus
%    G                is the shear modulus
%    rho              is the mass density
%    AxialForce       is the axial load on the shaft element
%
% The shaft type determines which effects are modelled, as below
%
%     Shaft_Type        Shear   Rotary Inertia   Gyroscopic
%        1 (Euler)                                   X
%        2                X           X              X
%        3                X           X
%        4                X                          X
%        5                            X              X
%        6                X
%        7                            X
%        8
%
%
% This function is part of a MATLAB Toolbox to accompany the book
% 'Dynamics of Rotating Machinery' by MI Friswell, JET Penny, SD Garvey
% & AW Lees, published by Cambridge University Press, 2010
%

% determine effects to include

if nargin < 8, AxialForce = 0; end   % no axial force

include_shear_effects = 1;
if (Shaft_Type==1) || (Shaft_Type==5) || (Shaft_Type==7) || (Shaft_Type==8)
   include_shear_effects = 0; 
end
if (G==0), include_shear_effects = 0; end
include_rotary_inertia = 1;
if (Shaft_Type==1) || (Shaft_Type==4) || (Shaft_Type==6) || (Shaft_Type==8)
   include_rotary_inertia = 0; 
end
include_gyroscopic = 1;
if (Shaft_Type==3) || (Shaft_Type==6) || (Shaft_Type==7) || (Shaft_Type==8)
   include_gyroscopic = 0; 
end

%  define intermediate constants
inertia = 0.015625*pi*(outer_diameter^4-inner_diameter^4);
A = 0.25*pi*(outer_diameter^2-inner_diameter^2);
if (include_shear_effects~=0)
   Poisson = 0.5*(E/G) - 1;
   r = inner_diameter/outer_diameter;
   r2 = r*r; r12 = (1+r2)^2;
   Kappa = 6*r12*(1+Poisson)/(r12*(7+6*Poisson)+r2*(20+12*Poisson));  % see Cowper, J. Applied Mechanics, Vol. 33, pp. 335-340, 1966
   shear_coeff = 12*E*inertia/(G*Kappa*A*L*L);
else
   shear_coeff = 0.0;
end

% stiffness element
phi = shear_coeff;
if (include_shear_effects==0), phi = 0; end
K0e = [12     0           0         6*L  -12     0           0         6*L;
        0    12        -6*L           0    0   -12        -6*L           0;
        0  -6*L (4+phi)*L*L           0    0   6*L (2-phi)*L*L           0;
      6*L     0           0 (4+phi)*L*L -6*L     0           0 (2-phi)*L*L;
      -12     0           0        -6*L   12     0           0        -6*L;
        0   -12         6*L           0    0    12         6*L           0;
        0  -6*L (2-phi)*L*L           0    0   6*L (4+phi)*L*L           0;
      6*L     0           0 (2-phi)*L*L -6*L     0           0 (4+phi)*L*L];
K0e = E*inertia*K0e/( (1+phi)*L^3 );

% element mass matrix
phi = shear_coeff; 
if (include_shear_effects==0), phi = 0; end
m1 = 312 + 588*phi + 280*phi^2;
m2 = (44 + 77*phi + 35*phi^2)*L;
m3 = 108 + 252*phi + 140*phi^2;
m4 = -(26 + 63*phi + 35*phi^2)*L;
m5 = (8 + 14*phi +7*phi*phi)*L^2;
m6 = -(6 + 14*phi +7*phi^2)*L^2;
M0e = [ m1    0    0   m2   m3    0    0   m4;
         0   m1  -m2    0    0   m3  -m4    0;
         0  -m2   m5    0    0   m4   m6    0;
        m2    0    0   m5  -m4    0    0   m6;
        m3    0    0  -m4   m1    0    0  -m2; 
         0   m3   m4    0    0   m1   m2    0;
         0  -m4   m6    0    0   m2   m5    0;
        m4    0    0   m6  -m2    0    0   m5];
M0e = rho*A*L*M0e/(840*(1+phi)^2);

% include the rotary inertia effects in the mass matrix
if (include_rotary_inertia~=0)
   phi = shear_coeff;
   if (include_shear_effects==0), phi = 0; end
   m7 = 36;
   m8 = (3 - 15*phi)*L;
   m9 = (4 + 5*phi +10*phi^2)*L^2;
   m10 = (-1 - 5*phi + 5*phi^2)*L^2;
   Ms =  [ m7    0    0   m8  -m7    0    0   m8;
            0   m7  -m8    0    0  -m7  -m8    0;
            0  -m8   m9    0    0   m8  m10    0;
           m8    0    0   m9  -m8    0    0  m10;
          -m7    0    0  -m8   m7    0    0  -m8;
            0  -m7   m8    0    0   m7   m8    0;
            0  -m8  m10    0    0   m8   m9    0;
           m8    0    0  m10  -m8    0    0   m9];
   Ms = rho*inertia*Ms/(30*L*(1+phi)^2);
   M0e = M0e + Ms;
end

% element gyroscopic matrix
if (include_gyroscopic==0)
   C1e = zeros(8,8);
else
   phi = shear_coeff;
   if (include_shear_effects==0), phi = 0; end
   g1 = 36;
   g2 = (3-15*phi)*L;
   g3 = (4 + 5*phi + 10*phi^2)*L^2;
   g4 = (-1 - 5*phi + 5*phi^2)*L^2;
   C1e = [  0  -g1   g2    0    0   g1   g2    0;
           g1    0    0   g2  -g1    0    0   g2;   
          -g2    0    0  -g3   g2    0    0  -g4;
            0  -g2   g3    0    0   g2   g4    0;
            0   g1  -g2    0    0  -g1  -g2    0;
          -g1    0    0  -g2   g1    0    0  -g2;
          -g2    0    0  -g4   g2    0    0  -g3;
            0  -g2   g4    0    0   g2   g3    0];
   C1e = - rho*inertia*C1e/(15*L*(1+phi)^2);
end

% element stiffness matrix due to an axial load
if AxialForce ~= 0
   phi = shear_coeff; 
   if (include_shear_effects==0), phi = 0; end
   k1 = 72 + 120*phi + 60*phi^2;
   k2 = 6*L;
   k3 = (8 + 10*phi + 5*phi^2)*L^2;
   k4 = (-2 - 10*phi - 5*phi^2)*L^2;
   KFe = [ k1    0    0   k2  -k1    0    0   k2;
            0   k1  -k2    0    0  -k1  -k2    0;
            0  -k2   k3    0    0   k2   k4    0;
           k2    0    0   k3  -k2    0    0   k4;
          -k1    0    0  -k2   k1    0    0  -k2; 
            0  -k1   k2    0    0   k1   k2    0;
            0  -k2   k4    0    0   k2   k3    0;
           k2    0    0   k4  -k2    0    0   k3];
   KFe = AxialForce*KFe/(60*L*(1+phi)^2);
   K0e = K0e + KFe;
end

% element stiffness matrix due to an axial torque
% note this is based on an Euler-Bernoulli element formulation
if Torque ~= 0
   KTe = [  0    0    1    0    0    0   -1    0;
            0    0    0    1    0    0    0   -1;
            1    0    0 -L/2   -1    0    0  L/2;
            0    1  L/2    0    0   -1 -L/2    0;
            0    0   -1    0    0    0    1    0; 
            0    0    0   -1    0    0    0    1;
           -1    0    0 -L/2    1    0    0  L/2;
            0   -1  L/2    0    0    1 -L/2    0];
   KTe = Torque*KTe/L;
  % KTe = 0.5*(KTe + KTe.'); % to make symmetric
  % KTe = 0.5*(KTe - KTe.'); % to make asymmetric
   K0e = K0e + KTe;
end




% Skew-symmetric speed dependent contribution to element stiffness matrix
% from the internal damping. Note that the damping is assumed
% proportional to the element stiffness matrix.
phi = shear_coeff;
if (include_shear_effects==0), phi = 0; end
K1e = [ 0    12         -6*L            0    0   -12         -6*L            0;
      -12     0            0         -6*L   12     0            0         -6*L;
      6*L     0            0  (4+phi)*L*L -6*L     0            0  (2-phi)*L*L;
        0   6*L -(4+phi)*L*L            0    0  -6*L -(2-phi)*L*L            0;
        0   -12          6*L            0    0    12          6*L            0;
       12     0            0          6*L  -12     0            0          6*L;
      6*L     0            0  (2-phi)*L*L -6*L     0            0  (4+phi)*L*L;
        0   6*L -(2-phi)*L*L            0    0  -6*L -(4+phi)*L*L            0];
K1e = E*inertia*K1e/( (1+phi)*L^3 );

Kte = [[ 0,  36,   -3*L, 0, 0,  -36,   -3*L, 0]
       [ 0,   0,      0, 0, 0,    0,      0, 0]
       [ 0,   0,      0, 0, 0,    0,      0, 0]
       [ 0, 3*L, -4*L^2, 0, 0, -3*L,    L^2, 0]
       [ 0, -36,    3*L, 0, 0,   36,    3*L, 0]
       [ 0,   0,      0, 0, 0,    0,      0, 0]
       [ 0,   0,      0, 0, 0,    0,      0, 0]
       [ 0, 3*L,    L^2, 0, 0, -3*L, -4*L^2, 0]];
   
Kte = inertia*rho*Kte/(15*L);

