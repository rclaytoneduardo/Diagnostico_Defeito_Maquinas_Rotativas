function  [ts,xs] = srcompensation(iKT,VT,delta_t,speedc)



tTacho=iKT*delta_t; % Pick out every 4th pulse
ts=[]; % Synchronous time instances
SampPerRev=100;
for n = 1:length(tTacho)-1
    tt=linspace(tTacho(n),tTacho(n+1),SampPerRev+1);
    ts=[ts tt(1:end-1)];
    if speedc>0
        if (tTacho(n+1)-tTacho(n))>(1/speedc)
            t0c = tTacho(n);
        end
    end
end
%create a time axis for this upsampled signal
tx=(0:delta_t:(length(VT)-1)*delta_t);
% Interpolate x onto the x-axis in ts instead of tx
xs=interp1(tx,VT,ts,'linear','extrap');

if speedc>0
    idx= find(ts==t0c);
    x = xs(idx:idx+SampPerRev);
    xsc=[];
    for n = 1:(length(ts))/(SampPerRev)
        xsc=[xsc x(1:end-1)];
    end
end
if speedc>0
    xs =xs-detrend(xsc);
end
xs = xs-mean(xs);

% tx=(0:delta_t:max(ts)); % Converte amostragem em tempo fixo
% xx=interp1(ts,xs,tx,'linear','extrap');


        
 


        
  