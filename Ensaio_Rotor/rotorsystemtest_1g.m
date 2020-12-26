% Operation condition
%"1-Normal", "2-Unbalance", "3-Misalignment", "4-Crack", "5-Rub", "6-Instability"

clear all
close all
clc

% Measured data file
%fileTDMS = 'unb36_p2_0.95g_5cm.tdms';

fileTDMS = 'unb185_p2_1gf1p2.tdms'; % Usado na dissertação como o valor máximo (FIGURA 3.11 b)

% Bearing selection
bearing = [4 5; 6 7]; % [4 5] = Lado acoplado ao motor // [6 7] = Lado não acoplado 
bset = bearing(2,:); % Bearing choosed

% Convert data
[ConvertedData,ConvertVer,ChanNames] = convertTDMS(false, fileTDMS);
xVT = ConvertedData.Data.MeasuredData(1,bset(1)).Data';
yVT = (-1)*ConvertedData.Data.MeasuredData(1,bset(2)).Data';
KT = ConvertedData.Data.MeasuredData(1,3).Data*1E3*7.87;
delta_t = ConvertedData.Data.MeasuredData(1,6).Property(1,3).Value;

L=length(KT);
t=(0:L-1)*delta_t;
% Produce +1 where signal is above trigger level
% and -1 where signal is below trigger level
TLevel=(max(KT)+min(KT))/2;
xs=sign(KT-TLevel);
% Differentiate this to find where xs changes
% between -1 and +1 and vice versa
xDiff=diff(xs);
% We need to synchronize xDiff with variable t from the
% code above, since DIFF shifts one step
tDiff=t(2:end);
% Now find the time instances of positive slope positions
% (-2 if negative slope is used)
iTacho=find(xDiff == 2);
tTacho=tDiff(iTacho);
% Count the time between the tacho signals and compute
rpsTacho=1./diff(tTacho);
rpsTacho(1)=0; % Solução para erro no valor da primeira velocidade de rotação
rpsTacho(end-5:end)=0; % Solução para erro nas últimas 5 velocidade de rotação
rps_max = max(rpsTacho)-1; %Hz
iend=min(find(rpsTacho>rps_max)); 
xVT=(xVT(iTacho(1):iTacho(iend)-1));
yVT=(yVT(iTacho(1):iTacho(iend)-1));
iKT = iTacho(1:iend)-iTacho(1)+1;
iKT(end)=iKT(end)-1;
% speed [rps]
speed = zeros(iTacho(iend)-iTacho(1),1);
k1=1;
j=1;
for i=1:iend-1
    for k=k1:(iTacho(i+1)-iTacho(1))
        speed(k)= rpsTacho(i)+(rpsTacho(i+1)-rpsTacho(i))/(iTacho(i+1)-iTacho(i))*j;
        j=j+1;
    end
    j=1;
    k1=iTacho(i+1)-iTacho(1)+1;
end
% Slow roll compensation
speedc = 0; %[rps] (0 [rps] if no compensation)

% matrix cascade 
matrix1 = plotspectrumtest(iKT,xVT,yVT,delta_t,speed,speedc); %[adm],[m],[m],[s],[rps],[rps]

% matrix for deep learning 
%databuilder(matrix)

% bode
%matrix2 = plotbodetest(iKT,xVT,yVT,delta_t,speed,speedc); %[adm],[m],[m],[s],[rps],[rps]



% ordertrack% 
% figure()
%ordertrack(resample(detrend(xVT),1,5),1/delta_t/5,resample(speed*60,1,5),[1 2 3]) 
% figure()
% ordertrack(resample(detrend(yVT),1,5),1/delta_t/5,resample(speed*60,1,5),[1 2 3]) 

% figure(4)
% [txs,xs] = srcompensation(iKT,xVT,delta_t,speedc);
% plot(txs,xs*1e3) %amplitude em mm e txs amostragem angular fixa
% 
% figure(5)
% [tys,ys] = srcompensation(iKT,yVT,delta_t,speedc);
% plot(tys,ys*1e3) %amplitude em mm e tys amostragem angular fixa

% ordertrack
% figure(6)
% plotordertrack(txs,xs,delta_t,speed)


% figuras
L=length(xVT);
t=(0:L-1)*delta_t;
plotpresentation_1g(xVT, yVT, t, delta_t, speed'); %[m],[m], [s], [rps]










