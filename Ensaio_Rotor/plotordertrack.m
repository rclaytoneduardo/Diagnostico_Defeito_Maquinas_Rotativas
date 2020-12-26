function plotordertrack(txs,xs,delta_t,speed)

tx=(0:1e-3:max(txs));
VT=interp1(txs,xs,tx,'linear','extrap');
tspeed = (0:delta_t:(length(speed)-1)*delta_t)' ;
rpm=interp1(tspeed,speed*60,tx,'linear','extrap');
 

[MAG,RPM,TIME]=ordertrack(VT,1/1e-3,rpm,[0.5 1 2]);
plot(RPM,MAG)