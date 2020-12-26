function [time,response,speed, angle] = runup(model,alpha,tspan,nr)
%
%  function  runup.m
%
%   [time, response, speed] = runup(model, alpha, tspan)
%
% Calculates the response during a runup using time integration 
%
%    time         is time vector
%
%    response     is the response output and is a 2 dimensional array
%                 The indices are DoFs and frequency
%
%    speed        gives the instantaneous rotor speed during runup
%
%    alpha        [a2 a1 a0], rotor speed = a2*t^2 + a1*t + a0
%
%    tspan        the time span vector for ode45
%
%    nr           is the number of degrees of freedom in the reduced model
%
%    Force_Def    gives the force definition. Unbalance only.
%
% This function is part of a MATLAB Toolbox to accompany the book
% 'Dynamics of Rotating Machinery' by MI Friswell, JET Penny, SD Garvey
% & AW Lees, published by Cambridge University Press, 2010
%
global tview


if nargin < 4 % no model reduction
    nr = 0;
end

Node_Def = model.node;
Grav_Def = model.gforce;
Unb_Def = model.unbforce;
Mis_Def = model.misforce;
Bearing_Def = model.bearing;
Crack_Def = model.crackforce;
Shaft_Def = model.shaft;
Disc_Def = model.disc;


% obtain model of rotor
[M0,C0,C1,K0,~,Kt0] = rotormtx(model);
[nnode,~] = size(Node_Def);
ndof = 4*nnode;
dof = 1:ndof;

if Bearing_Def(1,1) > 6.5
    Mb = zeros(ndof);
    Cb = zeros(ndof);
    Kb = zeros(ndof);
    zero_dof = [];
else
    [Mb,Cb,Kb,zero_dof] = bearmtx(model,0.0);
    % sort out zeroed DoF and determine bearing model
    dof(zero_dof) = [];
end

% calculate machine model
M = M0 + Mb;
K = K0 + Kb;
C = C0 + Cb;

% Gravitational force
g = Grav_Def(1,1);
vec_g = zeros(ndof,1);
vec_g(2:4:end,1) = g;
grav_force = M*vec_g;

% Unbalance force
[nforce,~] = size(Unb_Def);
ubdof = zeros(nforce,2);
ubforce = zeros(nforce,1);
ubphase = zeros(nforce,1);
for iforce = 1:nforce 
    node = Unb_Def(iforce,1);
    unbal_mag = Unb_Def(iforce,2);
    unbal_phase = Unb_Def(iforce,3);
    force_dof = [4*node-3; 4*node-2];
    ubdof(iforce,:) = force_dof;
    ubforce(iforce) = unbal_mag;
    ubphase(iforce) = unbal_phase;
end

% Misalignment force
misdof = zeros(1,2);
misforce = zeros(1,2);
node = 1;
[nshaft,~] = size(Shaft_Def);
[ndisc,~] = size(Disc_Def);
coupling_L = 0.05; coupling_Kb = 217; % coupling EagleBurgmann; L=0.05m; 217Nm/rad
Iyshaft=0;
Iydisc=0;
F_ma = zeros(1,2);
F_mp = zeros(1,2);
for i = 1:nshaft
    n1 = Shaft_Def(i,2);
    n2 = Shaft_Def(i,3);
    outer_diameter = Shaft_Def(i,4);
    inner_diameter = Shaft_Def(i,5);
    rho = Shaft_Def(i,6);
    Le = Node_Def(n2,2) - Node_Def(n1,2);
    S = 0.25*pi*(outer_diameter^2-inner_diameter^2);
    Meshaft=S*Le*rho;
    Iyeshaft=0.5*Meshaft*0.25*(outer_diameter^2+inner_diameter^2);
    Iyshaft=Iyshaft+Iyeshaft;
end
for i = 1:ndisc 
    rho = Disc_Def(i,3);
    thickness = Disc_Def(i,4);
    outer_diameter = Disc_Def(i,5);
    inner_diameter = Disc_Def(i,6);  
    Mdisc = 0.25*rho*pi*thickness*(outer_diameter^2-inner_diameter^2);
    Iyedisc = 0.5*Mdisc*0.25*(outer_diameter^2+inner_diameter^2);
    Iydisc = Iydisc+Iyedisc;
end
Tq=(Iydisc+Iyshaft)*alpha(1);
if Mis_Def(1,1)== 1 % misalignment angular
    misal_mag = Mis_Def(1,2);
    FX2 = Tq*sin(misal_mag*2*pi/360)/coupling_L;
    FY2 = coupling_Kb*misal_mag*2*pi/360/coupling_L;
    F_ma=[FX2 FY2];
end
if Mis_Def(1,1)== 2 % misalignment parallel
    dX1 = Mis_Def(1,2);
    dX2 = Mis_Def(1,3);
    dY1 = Mis_Def(1,4);
    dY2 = Mis_Def(1,5);
    teta1 = asin(dX1/coupling_L);
    teta2 = asin(dX2/coupling_L);
    phi1 = asin(dY1/coupling_L);
    phi2 = asin(dY2/coupling_L);
    MX1 = Tq*sin(teta1)+coupling_Kb*phi1;
    MX2 = Tq*sin(teta2)+coupling_Kb*phi2;
    MY1 = Tq*sin(phi1)+coupling_Kb*teta1;
    MY2 = Tq*sin(phi2)+coupling_Kb*teta2;
    FX1 = (-MY1-MY2)/coupling_L;
    FY1 = (MX1+MX2)/coupling_L;
    F_mp=[-FX1 -FY1];
end
misdof(1,:) = [4*node-3; 4*node-2];
misforce(1,:) = F_ma+F_mp;

ubforce(zero_dof) = [];  % remove force from zeroed dof 

% Crack force
[ncrack,~] = size(Crack_Def);
for icrack = 1:ncrack
    n1    = Crack_Def(icrack,1);
    n2    = Crack_Def(icrack,2);
    a_bar = Crack_Def(icrack,3);
    outer_diameter = Shaft_Def(n1,4);
    inner_diameter = Shaft_Def(n1,5);
    R = outer_diameter/2;
    E = Shaft_Def(n1,7);
    G = Shaft_Def(n1,8);
    Le = Node_Def(n2,2) - Node_Def(n1,2);
    inertia = 0.015625*pi*(outer_diameter^4-inner_diameter^4);
    r = inner_diameter/outer_diameter;
    r2 = r*r; r12 = (1+r2)^2;
    Poisson = E/(2*G) - 1;
    Kappa = 6*r12*(1+Poisson)/(r12*(7+6*Poisson)+r2*(20+12*Poisson));
    A = 0.25*pi*(outer_diameter^2-inner_diameter^2);
    a = 12*E*inertia/(G*Kappa*A*Le*Le);
    
    [Kc] = crack_ele_papa(E,inertia,a,R,a_bar,Poisson,Le);
        
    [K_uce] = uncrakedmtx(a,Le,E,inertia);
    K_c = Kc;
    K_uc = K_uce;  
end

% Rub force
Rub_Def = model.rubforce;
node = Rub_Def(1,1);        
rubdof(1,:) = [4*node-3; 4*node-2];


%% reduce the model
[ndofz,~] = size(M);
nr = round(nr);
if nr > 0 && nr < ndofz     % model reduction based on undamped modes
    [eigvec,eigval] = eig(K,M);
    [~,isort] = sort(diag(eigval));
    eigvec = eigvec(:,isort);
    Tr = eigvec(:,1:nr);
else
    Tr = eye(ndofz,ndofz);
    nr = ndofz;
end



%%
Mr = Tr.'*M*Tr;
Cr = Tr.'*C*Tr;
C1r = Tr.'*C1*Tr;
Kr = Tr.'*K*Tr;
gr_force = Tr.'*grav_force;
Ktr = Tr.'*Kt0*Tr;

iMr = Mr\eye(size(Mr));


A = [zeros(nr,nr) eye(nr,nr); -iMr*Kr -iMr*Cr];
A1 = [zeros(nr,nr) zeros(nr,nr); zeros(nr,nr) -iMr*C1r];
A2 = [zeros(nr,nr) zeros(nr,nr); -iMr*Ktr zeros(nr,nr)];
B = zeros(2*nr,1);

Tr_unb = Tr([ ubdof(:,1) ; ubdof(:,2) ],:);
Tr_mis = Tr([ misdof(:,1) ; misdof(:,2) ],:);
Tr_rub = Tr([ rubdof(:,1) ; rubdof(:,2) ],:);

tview=0.2; fprintf('\nTime progress:      ')
%Initial condition 
qdot_0 = zeros(2*nr,1);
options = odeset('abstol',1e-6,'reltol',1e-6);
[~,q] = ode15s(@deriv,0:1e-4:1,qdot_0,options,A,A1,A2,[0 alpha(2) 0],K_c,K_uc,nr,iMr,ubforce,ubphase,Tr_unb,misforce,Tr_mis,Tr_rub, B,model,Tr,gr_force,ndof,Crack_Def);
qdot_0 = q(end,:)';


tview=0.2;
[time,q] = ode15s(@deriv,tspan,qdot_0,options,A,A1,A2,alpha,K_c,K_uc,nr,iMr,ubforce,ubphase,Tr_unb,misforce,Tr_mis,Tr_rub,B,model,Tr,gr_force,ndof,Crack_Def);

time = time.';
npts = length(time);
response = zeros(ndof,npts);
response(dof,:) = Tr*q(:,1:nr).';

speed = alpha(1)*time + alpha(2)*ones(size(time));
angle = alpha(3)*ones(size(time))+alpha(2).*time+0.5*alpha(1).*time.*time;

return


function [qdot] = deriv(t,q,A,A1,A2,alpha,K_c,K_uc,nr,iMr,ubforce,ubphase,Tr_unb,misforce,Tr_mis,Tr_rub,B,model,Tr,gr_force,ndof,Crack_Def)
global tview
% time progress conter
if tview<t
    if tview>=10
        fprintf('\b\b\b\b\b\b%3.1fs ',tview)
    else
        fprintf('\b\b\b\b\b%3.1fs ',tview)
    end
    tview=tview+0.2;
end

phi = 0.5*alpha(1)*t*t + alpha(2)*t + alpha(3);
d_phi = alpha(1)*t + alpha(2);
dd_phi = alpha(1);

%------------------------------------------------------------------------
unb = [ ubforce.*(cos(phi+ubphase)*d_phi^2 + dd_phi*sin(phi+ubphase)) ;
        ubforce.*(sin(phi+ubphase)*d_phi^2 - dd_phi*cos(phi+ubphase)) ];
fr_unb = Tr_unb.'*unb;

%------------------------------------------------------------------------
mis = [ misforce(1)*(sin(phi)+sin(2*phi)+sin(3*phi)+sin(4*phi));
        misforce(2)*(cos(phi)+cos(2*phi)+cos(3*phi)+cos(4*phi)) ];
fr_mis = Tr_mis.'*mis;
        
%------------------------------------------------------------------------
% Crack Force
K_crack = zeros(ndof);
n1 = Crack_Def(1,1);
n2 = Crack_Def(1,2);
crack_dof = [4*n1-3:4*n1 4*n2-3:4*n2];
[K_c_fixed] = crack_fixed_coordinates(K_c,phi);
K_crack(crack_dof,crack_dof) = K_crack(crack_dof,crack_dof) + K_c_fixed - K_uc;
K_crack_r = Tr.'*K_crack*Tr;
f_breathing = 0.5*(1-cos(phi));
fr_c = f_breathing*K_crack_r*q(1:nr);
%------------------------------------------------------------------------
% Rub force
Rub_Def = model.rubforce;
node = Rub_Def(1,1);        
delta_rub = Rub_Def(1,2);
Ks=Rub_Def(1,3);
fc=Rub_Def(1,4);
rubdof(1,:) = [4*node-3; 4*node-2];
qresp= Tr*q(1:nr,1);
e = qresp(4*node-3,1);

if e > delta_rub
    rubforce = [-Ks*(e-delta_rub);
                -fc*Ks*(e-delta_rub)];
else
    rubforce = [0;0];
end
fr_rub = Tr_rub.'*rubforce;

%------------------------------------------------------------------------
% Hydrodynamic Force
[fr_hyd] = hyd_forces_friswell(model,d_phi,q,Tr,nr);



%------------------------------------------------------------------------
% state space
B(nr+1:end) = iMr*(fr_unb + fr_mis + fr_rub - fr_c + fr_hyd + gr_force);
qdot = (A + A1*d_phi + A2*dd_phi)*q + B;


