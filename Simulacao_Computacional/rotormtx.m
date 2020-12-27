function [M0,C0,C1,K0,K1,Kt] = rotormtx(model)
%
%  function rotormtx.m
%
%     [M0,C0,C1,K0,K1] = rotormtx(model)
%
% calculates the mass, stiffness and other matrices for the shaft
% and discs
%
%
% This function is part of a MATLAB Toolbox to accompany the book
% 'Dynamics of Rotating Machinery' by MI Friswell, JET Penny, SD Garvey
% & AW Lees, published by Cambridge University Press, 2010
%

Node_Def = model.node;
Shaft_Def = model.shaft;
Disc_Def = model.disc;

% determine the number of degrees of freedom and initialise matrices

[nnode,ncol_node] = size(Node_Def);
ndof = 4*nnode;
if ncol_node == 1
   Node_Def = [(1:nnode)' Node_Def];
end

M0 = zeros(ndof,ndof);
K0 = zeros(ndof,ndof);
K1 = zeros(ndof,ndof);
Kt = zeros(ndof,ndof);
C0 = zeros(ndof,ndof);
C1 = zeros(ndof,ndof);

[nshaft,ncol_shaft] = size(Shaft_Def);
[ndisc,ncol_disc] = size(Disc_Def);


% add shaft elements into matrices

for i = 1:nshaft
   Shaft_Type = round(Shaft_Def(i,1));
   
   if (Shaft_Type>0.5) && (Shaft_Type<8.5)    % circular shaft
       
      n1 = Shaft_Def(i,2);
      n2 = Shaft_Def(i,3);
      dof = [4*n1-3:4*n1 4*n2-3:4*n2];
      Le = Node_Def(n2,2) - Node_Def(n1,2);
      outer_diameter = Shaft_Def(i,4);
      inner_diameter = Shaft_Def(i,5);
      rho = Shaft_Def(i,6);
      E = Shaft_Def(i,7);
      if ncol_shaft < 8
         G = 0;
      else
         G = Shaft_Def(i,8);
      end   
      if ncol_shaft < 9
         damping_factor = 0;  % proportional damping
      else
         damping_factor = Shaft_Def(i,9);
      end   
      if ncol_shaft < 10
         Axial_Force = 0;  % Axial Force
      else
         Axial_Force = Shaft_Def(i,10);
      end   
      if ncol_shaft < 11
         Torque = 0;  % Axial Torque
      else
         Torque = Shaft_Def(i,11);
      end   
      [M0e,C1e,K0e,K1e,Kte] = shftelem(Shaft_Type,Le,outer_diameter,inner_diameter,E,G,rho,Axial_Force,Torque);
      M0(dof,dof) = M0(dof,dof) + M0e;
      C0(dof,dof) = C0(dof,dof) + damping_factor*K0e;
      C1(dof,dof) = C1(dof,dof) + C1e;
      K0(dof,dof) = K0(dof,dof) + K0e;
      K1(dof,dof) = K1(dof,dof) + damping_factor*K1e;
      Kt(dof,dof) = Kt(dof,dof) + Kte;
      
   elseif (Shaft_Type>20.5) && (Shaft_Type<28.5)    % tapered circular shaft, no damping
      
      n1 = Shaft_Def(i,2);
      n2 = Shaft_Def(i,3);
      dof = [4*n1-3:4*n1 4*n2-3:4*n2];
      Le = Node_Def(n2,2) - Node_Def(n1,2);
      out_dia_1 = Shaft_Def(i,4);
      out_dia_2 = Shaft_Def(i,5);
      inn_dia_1 = Shaft_Def(i,6);
      inn_dia_2 = Shaft_Def(i,7);
      rho = Shaft_Def(i,8);
      E = Shaft_Def(i,9);
      if ncol_shaft < 10
         G = 0;
      else
         G = Shaft_Def(i,10);
      end   
      if ncol_shaft < 11
         Axial_Force = 0;  % Axial Force
      else
         Axial_Force = Shaft_Def(i,11);
      end   
      [M0e,C1e,K0e,~] = taper(Shaft_Type,Le,out_dia_1,out_dia_2,inn_dia_1,inn_dia_2,E,G,rho,Axial_Force);
      M0(dof,dof) = M0(dof,dof) + M0e;
      C1(dof,dof) = C1(dof,dof) + C1e;
      K0(dof,dof) = K0(dof,dof) + K0e;
             
   else
      error_msg = ['>>>>  error in shaft element type - shaft element number ' num2str(i) ' ignored'];
      disp(error_msg)
   end
end


% add contributions from the discs

if ndisc == 0, return, end

for i = 1:ndisc
   Disk_Type = round(Disc_Def(i,1));
   if Disk_Type == 1 || Disk_Type == 3     
      n1 = Disc_Def(i,2);
      rho = Disc_Def(i,3);
      thickness = Disc_Def(i,4);
      outer_diameter = Disc_Def(i,5);
      if ncol_disc == 6
         inner_diameter = Disc_Def(i,6);  
      else
         inner_diameter = 0;  
      end   
      Mdisc = 0.25*rho*pi*thickness*(outer_diameter^2-inner_diameter^2);
      Id = 0.015625*rho*pi*thickness*(outer_diameter^4-inner_diameter^4) + Mdisc*(thickness^2)/12;
      Ip = 0.03125*rho*pi*thickness*(outer_diameter^4-inner_diameter^4);
   end
   if Disk_Type == 2 || Disk_Type == 4
      n1 = Disc_Def(i,2);
      Mdisc = Disc_Def(i,3);
      Id = Disc_Def(i,4);
      if Disk_Type == 2, Ip = Disc_Def(i,5); end
   end
   if Disk_Type == 1 || Disk_Type == 2   
      dof = (4*n1-3):4*n1;
      M0(dof,dof) = M0(dof,dof) + diag( [Mdisc Mdisc Id Id] );
      dof1 = 4*n1 - 1;
      C1(dof1,dof1+1) = C1(dof1,dof1+1) + Ip;
      C1(dof1+1,dof1) = C1(dof1+1,dof1) - Ip;
      Kt(dof1+1,dof1) = Kt(dof1+1,dof1) - Ip;
   elseif Disk_Type == 3 || Disk_Type == 4
      dof = (4*n1-3):4*n1;
      M0(dof,dof) = M0(dof,dof) + diag( [Mdisc Mdisc Id Id] );
   else
      error_msg = ['>>>>  error in disc type - disc number ' num2str(i) ' ignored'];
      disp(error_msg)
   end
end
