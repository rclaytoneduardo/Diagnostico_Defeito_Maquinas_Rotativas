function [Mb,Cb,Kb,zero_dof,eccentricity] = bearmtx(model,Rotor_Spd)
%
%  function bearmtx.m
%
%     [Mb,Cb,Kb,zero_dof,eccentricity] = bearmtx(model,Rotor_Spd)
%
% calculates the mass, stiffness and damping matrices for the bearings
%
% zero_dof      indicates the degrees of freedom that should be constrained
%               for stiff bearings (bearing types 1 and 2)
%
% eccentricity  returns the eccentricity for fluid bearings and is
%               zero for other bearings
%
% Rotor_Spd     is a single rotational speed of the rotor (rad/s)
%
%
% This function is part of a MATLAB Toolbox to accompany the book
% 'Dynamics of Rotating Machinery' by MI Friswell, JET Penny, SD Garvey
% & AW Lees, published by Cambridge University Press, 2010
%

Node_Def = model.node;
Bearing_Def = model.bearing;

% determine the number of degrees of freedom and initialise matrices

[no_node,ncol_node] = size(Node_Def);
ndof = 4*no_node;
[nbearing,ncol_bearing] = size(Bearing_Def);
Mb = zeros(ndof,ndof);
Cb = zeros(ndof,ndof);
Kb = zeros(ndof,ndof);
zero_dof = [];

eccentricity = zeros(nbearing,1);

% for each bearing, decide on bearing type and include

for i = 1:nbearing
   
   Bearing_Type = round(Bearing_Def(i,1));
   if ( Bearing_Type < 1 | Bearing_Type > 8 ) & Bearing_Type ~= 20
      disp(['>>>> Error - bearing type ' num2str(Bearing_Type) ' not implemented'])
   end
   Kb1 = zeros(4,4);
   Cb1 = zeros(4,4);
   Mb1 = zeros(4,4);
   
   if Bearing_Type == 1       % short, stiff bearing - pinned boundary condition
      n1 = Bearing_Def(i,2);
      zero_dof = [zero_dof 4*n1-3 4*n1-2];
   end   
   
   if Bearing_Type == 2       % long, stiff bearing - clamped boundary condition
      n1 = Bearing_Def(i,2);
      zero_dof = [zero_dof 4*n1-3:4*n1];
   end   

   if Bearing_Type == 3       % constant stiffness and damping, diagonal, no rotations
      if ncol_bearing < 6, disp('>>>> Error - too few columns in bearing definition matrix for bearing type 3'), end
      Kb1 = diag( [Bearing_Def(i,3) Bearing_Def(i,4) 0 0] );
      Cb1 = diag( [Bearing_Def(i,5) Bearing_Def(i,6) 0 0] );
   end
   
   if Bearing_Type == 4       % constant stiffness and damping, diagonal
      if ncol_bearing < 10, disp('>>>> Error - too few columns in bearing definition matrix for bearing type 4'), end
      Kb1 = diag( [Bearing_Def(i,3) Bearing_Def(i,4) Bearing_Def(i,5) Bearing_Def(i,6)] );
      Cb1 = diag( [Bearing_Def(i,7) Bearing_Def(i,8) Bearing_Def(i,9) Bearing_Def(i,10)] );
   end
   
   if Bearing_Type == 5       % constant stiffness and damping, no rotations
      if ncol_bearing < 10, disp('>>>> Error - too few columns in bearing definition matrix for bearing type 5'), end
      Kb1(1:2,1:2) = [Bearing_Def(i,3:4); Bearing_Def(i,5:6)];
      Cb1(1:2,1:2) = [Bearing_Def(i,7:8); Bearing_Def(i,9:10)];
   end
   
   if Bearing_Type == 6       % constant stiffness and damping, full 4x4 matrices required
      if ncol_bearing < 34, disp('>>>> Error - too few columns in bearing definition matrix for bearing type 6'), end
      Kb1 = [Bearing_Def(i,3:6); Bearing_Def(i,7:10); Bearing_Def(i,11:14); Bearing_Def(i,15:18)];
      Cb1 = [Bearing_Def(i,19:22); Bearing_Def(i,23:26); Bearing_Def(i,27:30); Bearing_Def(i,31:34)];
   end
   
   if Bearing_Type == 7       % fluid film bearings - based on short width bearing theory
      if ncol_bearing < 7, disp('>>>> Error - too few columns in bearing definition matrix for bearing type 7'), end
      if Rotor_Spd == 0, disp('>>>> Error - bearing type 7 - fluid bearing model undefined at zero speed'), end
      F   = Bearing_Def(i,3);   % static load (N)
      D   = Bearing_Def(i,4);   % bearing diameter (m)
      L   = Bearing_Def(i,5);   % bearing length (m)
      c   = Bearing_Def(i,6);   % bearing radial clearance (m)
      eta = Bearing_Def(i,7);   % oil viscosity (Ns/m^2)
      % Find roots of quartic in n^2  (n is eccentricity ratio)
      H = ( 8*c^2*F/(D*Rotor_Spd*eta*L^3) )^2;
      n2all = sort( roots([1 -4 (6-(16-pi^2)/H) -(4+pi^2/H) 1]) );
      nroot = 0; n2 = []; % test roots - eccentricity should be between 0 and 1
      for ir=1:4,
         nn = n2all(ir);
         if nn>0 & nn<1 & isreal(nn)
            nroot = nroot + 1;
            n2 = [n2; nn];
         end
      end
      if nroot == 0
         n2 = 0.5;
         disp('Error in calculating fluid bearing coefficents - no solutions for eccentricity')
      end
      if nroot >= 2
         n2 = min(n2);
         disp('Error in calculating fluid bearing coefficents - multiple solutions for eccentricity')
      end
      % Compute damping and stiffness matrices
      a = zeros(2,2); b = zeros(2,2);
      n = sqrt(n2); 
      eccentricity(i) = n;
      q1 = (1-n2); q2 = (1+n2); q3 = (1+2*n2); p2 = pi^2;
      de = (p2*q1+16*n2)^1.5;
      a(1,1) = 4*(p2*(2-n2)+16*n2)/de;
      a(2,2) = 4*(p2*q1*q3+32*n2*q2)/(q1*de);
      a(1,2) = pi*(p2*q1^2-16*n^4)/(n*sqrt(q1)*de);
      a(2,1) = -pi*(p2*q1*q3+32*n2*q2)/(n*sqrt(q1)*de);
      b(1,1) = 2*pi*sqrt(q1)*(p2*q3-16*n2)/(n*de);
      b(2,2) = 2*pi*(p2*q1^2+48*n2)/(n*sqrt(q1)*de);
      b(1,2) = -8*(p2*q3-16*n2)/de;
      b(2,1) = b(1,2);
      Kb1 = zeros(4,4); Cb1 = zeros(4,4);
      Kb1(1:2,1:2) = (F/c)*a;
      Cb1(1:2,1:2) = (F/(c*Rotor_Spd))*b;
   end

   if Bearing_Type == 8       % seal
      if ncol_bearing < 8, disp('>>>> Error - too few columns in bearing definition matrix for bearing type 8'), end
      P    = Bearing_Def(i,3);   % pressure difference across seal
      R    = Bearing_Def(i,4);   % seal radius
      L    = Bearing_Def(i,5);   % seal length
      c    = Bearing_Def(i,6);   % seal radial clearance
      V    = Bearing_Def(i,7);   % seal average axial stream velocity
      fric = Bearing_Def(i,8);   % seal friction coefficient
      
      T = L/V;
      sigma = fric*L/c;
      epsilon = pi*sigma*R*P/(6*fric*(1.5+2*sigma));
      mu_0 = 9*sigma/(1.5+2*sigma);
      mu_1 = ( (3+2*sigma)^2*(1.5+2*sigma) - 9*sigma ) / (1.5+2*sigma)^2;
      mu_2 = ( 19*sigma + 18*sigma^2 + 8*sigma^3 ) / (1.5+2*sigma)^3;
      Kb1 = epsilon*(mu_0-mu_2*T^2*Rotor_Spd^2/4)*eye(2,2) + epsilon*(mu_1*T*Rotor_Spd/2)*[0 -1; 1 0];
      Cb1 = epsilon*mu_1*T*eye(2,2) + epsilon*(mu_2*T^2*Rotor_Spd)*[0 -1; 1 0];
      Mb1(1:2,1:2) = epsilon*mu_2*T^2*eye(2,2);
   end
  
   nnode = Bearing_Def(i,2);
   dof = (4*nnode-3):4*nnode;
   Kb(dof,dof) = Kb(dof,dof) + Kb1;
   Cb(dof,dof) = Cb(dof,dof) + Cb1; 
   Mb(dof,dof) = Mb(dof,dof) + Mb1; 
   
end
