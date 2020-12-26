function [Fh] = hyd_forces_friswell(model,d_phi,q,Tr,nr)

% viscosity - visc
% x disp - x
% y disp - y
% x vel - dx
% y vel - dy
% speed rot - om
% bearing radius - R
% bearing length - L
% radial clearance - C
% bearing diameter - D

Node_Def = model.node;
Bearing_Def = model.bearing;

% determine the number of degrees of freedom and initialise matrices
[no_node,~] = size(Node_Def);
ndof = 4*no_node;
[nbearing,~] = size(Bearing_Def);

fh = zeros(ndof,1);
vec_disp  = Tr*q(1:nr,1);
vec_vel = Tr*q(nr+1:end,1);

for ii = 1:nbearing

    nnode = Bearing_Def(ii,2);
    dofx = 4*nnode - 3;
    dofy = 4*nnode - 2;
    
    D    = Bearing_Def(ii,4);   % bearing diameter (m)
    L    = Bearing_Def(ii,5);   % bearing length (m)
    C    = Bearing_Def(ii,6);   % bearing radial clearance (m)
    visc = Bearing_Def(ii,7);   % oil viscosity (Ns/m^2)

    R = D/2;
    
    u  = vec_disp(dofx,1);
    du = vec_vel(dofx,1);
    
    v  = vec_disp(dofy,1);
    dv = vec_vel(dofy,1);
    
    an = v*d_phi + 2*du;
    ad = u*d_phi - 2*dv;
    
    if isnan(an/ad)
        a = 0;
    else
        a = atan(an/ad) - (pi/2)*sign(an/ad) - (pi/2)*sign(an);
    end
    
    quo = (C^2-u^2-v^2)^0.5;
    quo_2 = (C^2-u^2-v^2);

    S = (C*(u*cos(a) + v*sin(a)))/(C^2 - (u*cos(a) + v*sin(a))^2);

    G = (C*pi)/quo + ((C*2)/quo)*atan((v*cos(a) - u*sin(a))/quo);

    V = (2*C^2 + (v*cos(a) - u*sin(a))*C*G)/quo_2;

    C_Fh = -(visc*d_phi*(R*L)*(R^2/(C^2))*(L^2/(D^2)))*((C*(ad^2 + an^2)^0.5)/(d_phi*quo_2));

    
    Fhx = C_Fh*(3*(u/C)*V - sin(a)*G - 2*cos(a)*S);
    Fhy = C_Fh*(3*(v/C)*V + cos(a)*G - 2*sin(a)*S); 
    
    fh(dofx,1) = Fhx;
    fh(dofy,1) = Fhy;
    
end

Fh = Tr.'*fh;

end
