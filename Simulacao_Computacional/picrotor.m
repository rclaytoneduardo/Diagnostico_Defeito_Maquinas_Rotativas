function [] = picrotor(model)
%
%  function to plot a schematic of the rotor system
%
%     [] = picrotor(model)
%
%  This function takes the definitions for the nodes, shafts, bearings
%  and discs and plots the rotor cross-section on a 2D plot
%
%
% This function is part of a MATLAB Toolbox to accompany the book
% 'Dynamics of Rotating Machinery' by MI Friswell, JET Penny, SD Garvey
% & AW Lees, published by Cambridge University Press, 2010
%


Node_Def = model.node;
Shaft_Def = model.shaft;
Disc_Def = model.disc;
Bearing_Def = model.bearing;


FontName = 'Arial';
FontSize = 10;

plot_nodes = 1; % determines whether to plot marker and numbers for nodes


% Set up plotting functions
% The first column is the z position and the 2nd column the radius

[nnode,ncol_node] = size(Node_Def);
ndof = 4*nnode;
if ncol_node == 1
    Node_Def = [(1:nnode)' zeros(nnode,2) Node_Def];
end
if ncol_node == 2
    Node_Def = [Node_Def(:,1) zeros(nnode,2) Node_Def(:,2)];
end

[nshaft,ncol_shaft] = size(Shaft_Def);
[ndisc,ncol_disc] = size(Disc_Def);
[nbearing,ncol_bearing] = size(Bearing_Def);

shaft_length = max(Node_Def(:,4)) - min(Node_Def(:,4));


hold on


% Plot shaft sections

max_shaft_radius = 0.0;
shaft_radii_all = zeros(nshaft,2);

for i = 1:nshaft
    
    n1 = Shaft_Def(i,2);
    n2 = Shaft_Def(i,3);
    
    z1 = Node_Def(n1,4);
    z2 = Node_Def(n2,4);
    
    % symmetric shaft
    if Shaft_Def(i,1) < 10
        shaft_or1 = 0.5*Shaft_Def(i,4);
        shaft_ir1 = 0.5*Shaft_Def(i,5);
        shaft_or2 = shaft_or1;
        shaft_ir2 = shaft_ir1;
    end
    % asymmetric shaft - estimate radii from stiffness values
    if Shaft_Def(i,1) > 10 & Shaft_Def(i,1) < 20
        shaft_ir1 = 0.0; % as good as any!
        shaft_ir2 = 0.0;
        E = 211e9;  % assume steel
        EI = 0.5*(Shaft_Def(i,4)+Shaft_Def(i,5));
        shaft_or1 = sqrt(sqrt(4*EI/(E*pi)));
        shaft_or2 = shaft_or1;
    end
    % tapered shaft
    if Shaft_Def(i,1) > 20
        shaft_or1 = 0.5*Shaft_Def(i,4);
        shaft_or2 = 0.5*Shaft_Def(i,5);
        shaft_ir1 = 0.5*Shaft_Def(i,6);;
        shaft_ir2 = 0.5*Shaft_Def(i,7);;
    end
    max_shaft_radius = max([max_shaft_radius shaft_or1 shaft_or2]);
    shaft_radii_all(i,:) = [shaft_or1 shaft_or2];
    
    zfill = [z1 z1 z2 z2];
    
    if shaft_ir1 == 0 & shaft_ir2 == 0
        xfill = [-shaft_or1 shaft_or1 shaft_or2 -shaft_or2];
        fill(zfill,xfill,'c')
    else
        xfill = [shaft_ir1 shaft_or1 shaft_or2 shaft_ir2];
        fill(zfill,xfill,'c')
        xfill = [-shaft_or1 -shaft_ir1 -shaft_ir2 -shaft_or2];
        fill(zfill,xfill,'c')
        plot([z1 z1],[shaft_or1 -shaft_or1],'k',[z2 z2],[shaft_or2 -shaft_or2],'k')
    end
    
end


% Plot discs

max_disc_radius = 0;
max_disc_thick = 0.5*max_shaft_radius;
for i = 1:ndisc
    Disk_Type = round(Disc_Def(i,1));
    disk_node = Disc_Def(i,2);
    if Disk_Type == 1 | Disk_Type == 3
        thickness = Disc_Def(i,4);
        disk_radius = 0.5*Disc_Def(i,5);
        dsk_iradius = 0.5*Disc_Def(i,6);
    end
    if Disk_Type == 2 | Disk_Type == 4
        % approximate radius from Ip and mass
        disk_radius = sqrt(2*Disc_Def(i,5)/Disc_Def(i,3));
        % calculate convenient thickness as it is difficult to estimate
        thickness = 0.2*disk_radius;
        dsk_iradius = [];
        for ii = 1:nshaft % find shaft elements at node
            if Shaft_Def(ii,2)== disk_node
                dsk_iradius = [dsk_iradius shaft_radii_all(ii,1)];
            end
            if Shaft_Def(ii,3)== disk_node
                dsk_iradius = [dsk_iradius shaft_radii_all(ii,2)];
            end
        end
        dsk_iradius = mean(dsk_iradius);
    end
    max_disc_thick = max([max_disc_thick thickness]);
    max_disc_radius = max([max_disc_radius disk_radius]);
    % disk_node
    zc = Node_Def(disk_node,4);
    z1 = zc - thickness/2;
    z2 = zc + thickness/2;   
    alpha=0.2;
    knee_radius = alpha*disk_radius+(1-alpha)*dsk_iradius;
    xfill = [dsk_iradius knee_radius disk_radius disk_radius knee_radius dsk_iradius];
    zfill = [zc z1 z1 z2 z2 zc];
    fill(zfill,xfill,'y')
    xfill = -[dsk_iradius knee_radius disk_radius disk_radius knee_radius dsk_iradius];
    zfill = [zc z1 z1 z2 z2 zc];
    fill(zfill,xfill,'y')
end


% Plot bearings - not to scale

max_shaft_radius_bearing = 0;
for i = 1:nbearing
    bearing_type = Bearing_Def(i,1);
    bearing_node = Bearing_Def(i,2);
    if bearing_node==1
        shaft_radius = shaft_radii_all(1,1);
    elseif bearing_node==nnode
        shaft_radius = shaft_radii_all(nnode-1,2);
    else
        shaft_radius = 0.5*(shaft_radii_all(bearing_node-1,2)+shaft_radii_all(bearing_node,1));
    end
    max_shaft_radius_bearing = max([max_shaft_radius_bearing shaft_radius]);
    bear_radius = 2*shaft_radius;
    bear_width = 0.5*shaft_radius;
    zc = Node_Def(bearing_node,4);
    z1 = zc - bear_width;
    z2 = zc + bear_width;
    xfill = [shaft_radius bear_radius bear_radius];
    zfill = [zc z1 z2];
    fill(zfill,xfill,'r',zfill,-xfill,'r')
    text(z1, -1.6*bear_radius,['  Brg Type ', num2str(bearing_type)],...
        'HorizontalAlignment','center','FontName',FontName,...
        'FontSize',FontSize);
end


% Plot markers for nodes

if plot_nodes==1
%    marker_size = 0.35*max_shaft_radius;
    marker_size = 0.35*max_shaft_radius_bearing;
    for i = 1:nnode
        zc = Node_Def(i,4);
        z1 = zc - marker_size;
        z2 = zc + marker_size;
        xfill = [0 marker_size 0 -marker_size];
        zfill = [z1 zc z2 zc];
        fill(zfill,xfill,'g')
    end
    % add node numbers
    for i = 1:nnode
        text(Node_Def(i,4),-1.2*max([max_disc_radius max_shaft_radius]),...
            ['Node ' num2str(Node_Def(i,1))],...
            'HorizontalAlignment','right','FontName',FontName,...
            'FontSize',FontSize,'Rotation',90)
    end
end


% Plot dot-dashed centreline

plot([-0.05*shaft_length 1.05*shaft_length], [0 0],'k-.')



axis('off')
hold off
set(gca,'position',[0.05 0.5 0.9 0.4]);
drawnow

