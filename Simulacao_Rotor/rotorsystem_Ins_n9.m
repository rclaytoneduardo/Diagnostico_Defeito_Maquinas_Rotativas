% Rotor-bearing system simulation

clear
close all
clc 

fail='Ins';
ndata=0;
for disk_node = 9
numsim=500;

a0=1.02*0.68; b0=1.02*0.82; r0 = a0 + (b0-a0).*rand(numsim,1); % unb mass
a1=0.95; b1=1.05; r1 = a1 + (b1-a1).*rand(numsim,1); % damping_factor variance
a2=0.95; b2=1.05; r2 = a2 + (b2-a2).*rand(numsim,1); % disk_thick variance
a3=0.95; b3=1.05; r3 = a3 + (b3-a3).*rand(numsim,1); % Bearing_c variance

for i=1:numsim
i
% set the material parameters
E = 2.11e11;
Poisson = 0.3;
G = E/(2*(1+Poisson));
rho = 7800;
rho_disk = 2697;
damping_factor = 10e-5*r1(i); % beta

% set the geometric parameters
shaft_od = 0.01583; %medido 0.015835
shaft_id = 0;
shaft_length = 0.91;
disk_od = 0.15;
disk_m = 0.654; %massa medida em balança 0.572/0.654
disk_thick = disk_m/(rho_disk*pi/4*(disk_od^2-shaft_od^2))*r2(i);
%disk_thick = 12e-3; %12e-3

glove_od = 32e-3;
glove_thick = 206e-3/(rho*pi/4*(glove_od^2-shaft_od^2));

% mass parameters
disk_mass = 0.25*rho_disk*pi*disk_thick*(disk_od^2-shaft_od^2);
disk_weight = disk_mass*9.81;
shaft_mass = 0.25*rho*pi*shaft_length*(shaft_od^2-shaft_id);
shaft_weight = shaft_mass*9.81;
glove_mass = 0.25*rho*pi*glove_thick*(glove_od^2-shaft_od^2);
glove_weight = glove_mass*9.81;

% nodes from convergence analysis
nb_ele = 20;
nb_nodes = nb_ele+1;

% building nodes
model.node = [(1:nb_nodes).' 1e-3*[0 52.5 105 137.5 170 222.5 275 327.5 380 417.5 455 492.5 530 582.5 635 687.5 740 772.5 805 857.5 910]'];

% building shaft model
model.shaft = [2*ones(nb_ele,1) (1:nb_ele)' (2:(nb_ele+1))' ones(nb_ele,1)*[shaft_od shaft_id rho E G damping_factor] ];

% building disk model
%disk_node = 9;
gloveL_node = 5;
gloveR_node = 17;
model.disc =  [1 disk_node    rho_disk    disk_thick        disk_od    shaft_od;
               1 gloveL_node  rho         glove_thick       glove_od   shaft_od;
               1 gloveR_node  rho         glove_thick       glove_od   shaft_od];

% building bearing model
Bearing_posL = 3;
Bearing_posR = 19;
 
Bearing_FR = shaft_weight/2+ disk_weight*(model.node(disk_node,2)-model.node(Bearing_posL,2))/(model.node(Bearing_posR,2)-model.node(Bearing_posL,2))+...
                glove_weight*(model.node(gloveL_node,2)-model.node(Bearing_posL,2))/(model.node(Bearing_posR,2)-model.node(Bearing_posL,2))+...
                glove_weight*(model.node(gloveR_node,2)-model.node(Bearing_posL,2))/(model.node(Bearing_posR,2)-model.node(Bearing_posL,2));      % Static force at Right Bearing
Bearing_FL = shaft_weight + disk_weight + 2*glove_weight - Bearing_FR;                   % Static force at Left Bearing
%Bearing_Tc = 23;      % Oil operation temperature at the bearing (ºC) 23
Bearing_Tc = 90;
Bearing_L = 0.0065; % para L/D < 0.5, real = 0.01155m
%Bearing_D = 15.958e-3; %D: media = 15.9396e-3; max = 15.958e-3; 
Bearing_c = (15.958e-3-shaft_od)/2*r3(i)*0.95; %valor verdadeiro = 5.23e-05 a 6.4e-5
Bearing_D = 2*Bearing_c+shaft_od;

[Bearing_nu] = dynamic_viscosity(Bearing_Tc); % Considering oil ISO VG 68

model.bearing = [7 Bearing_posL  Bearing_FL Bearing_D Bearing_L Bearing_c Bearing_nu; ...
                 7 Bearing_posR  Bearing_FR Bearing_D Bearing_L Bearing_c Bearing_nu];
             
% draw the rotor             
% figure
% picrotor(model)
          
% Gravitational force 
model.gforce = [-9.81]*0; %[Gravidady_acceleration]
           
% Unbalance force
unb_mag = 1e-3*r0(i)*0.05; %1.02g e r=0.05m
model.unbforce = [disk_node unb_mag 0]; %[Disk_node Unbalance_mag Unbalance_phase]

% Crack force
a_bar = 0.0001;


model.crackforce = [7 8 a_bar]; %[Node_left  Node_right  crack/shaft_od/2]

% Misalignment force
model.misforce = [1 0.00001]; % [Misalig_Type(1->angular) teta(degrees)]
%model.misforce = [2 5e-6 5e-6 0 0]; % [Misalig_Type(2->parallel) dx1 dx2 dy1 dy2]

% Rub force
model.rubforce = [11 1000 0.6e5 0.2]; %[Node Clearance statot_stiffness frictional_coefficient]


% Acceleration, Speed, Initial position
% the initial rotor spin speed is 0.1 rad/s
% acceleration = 24.9 rad/s^2 
alpha = [24.9 0.1 0]; %alpha = [a v0 s0] alpha real=24.89rad/s2
delta_t = 1e-4;
f_time = 15.1;
tspan = 0:delta_t:f_time;
nr = 10;  % number of degrees of freedom to retain in the reduced order model
fs = 1/delta_t;

% Time response
    
[time,response,speed, angle] = runup(model,alpha,tspan,nr);

x_dof_resp = 4*(gloveR_node)-3;
y_dof_resp = 4*(gloveR_node)-2;
ux = response(x_dof_resp,:);
vy = response(y_dof_resp,:);



% figure
% [AX,H1,H2] = plotyy(time,1e3*ux,time,speed/(2*pi));
% xlabel('Time (s)')
% ylabel(AX(1),'Response at disk (mm)')
% ylabel(AX(2),'Rotor speed (Hz)')
% 
% figure
% [AX,H1,H2] = plotyy(time,1e3*vy,time,speed/(2*pi));
% xlabel('Time (s)')
% ylabel(AX(1),'Response at disk (mm)')
% ylabel(AX(2),'Rotor speed (Hz)')

% plot full spectrum cascade response [um]
matrix1 = plotspectrum(vy,ux,delta_t,speed/(2*pi)); %[m],[m], [s], [rps]

%ordertrack
rpm1 = speed/(2*pi)*60 ;
mag = ordertrack(detrend(resample(ux,1,8)),1/delta_t/8,resample(rpm1,1,8),[0.48 1]);
%figure()
%plot(mag(1,:))
%hold on
%plot(mag(2,:))
%hold off
inst_max=max((matrix1(1,21:24)));
coef_inst= max(mag(1,round(end/2):end))/ max(mag(2,round(end/2):end)); %relação entre inst. e pico 1X: 0.48X/1X
if inst_max >0.05 &&  ...
    max(mag(1,round(end/2):end))< max(mag(2,round(end/2):end))*2
    %  Matrix of Feature 
    databuilder(fail,matrix1,disk_node,r0(i),r1(i),r2(i),r3(i),coef_inst); 
    ndata=ndata+1
    if ndata==50
        return
    end
    %matrix2 = plotebode(ux, vy, delta_t, speed/(2*pi), angle); %[m],[m], [s], [inst_max é a maior amplitude de inst. normalizarps], [rad]
else
    close(gcf)
end
pause(1)
end
end


