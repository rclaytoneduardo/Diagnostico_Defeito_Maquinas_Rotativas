function matrix = plotbode(xVT,yVT,delta_t,speed,angle) %[m],[m],[s],[rps],[rad]

La = length(angle);
k=1;
for i=1:La
    anglek = 2*pi*k;
    if angle(i)> anglek  
        iKT(k) = i;
        k = k+1;
    end
end

xVT=xVT(1:iKT(end));
yVT=yVT(1:iKT(end));

% Slow roll compensation
speedc = 0; %[rps] (0 [rps] if no compensation)

% bode
matrix  = plotbodetest(iKT,xVT,yVT,delta_t,speed,speedc); %[adm],[m],[m],[s],[rps],[rps]









