function plotpresentation_residual(xVT,yVT,time,delta_t,speed) %[m],[m],[s],[rps],[rad]
close all
meanxVT=mean(xVT) % valor médio subtraido do sinal x
meanyVT=mean(yVT) % valor médio subtraido do sinal y

figure('Position', [403,26,389,640])
subplot(3,1,1)
%figure('Position', [403,26,389,640])
%plot(time,(xVT-mean(xVT))*1e6)
plot(time,xVT*1e6)
xlabel('Tempo (s)')
ylabel('Amplitude (\mum)')
xlim([0 14])
ylim([1000 1200])
grid on
title('Resposta horizontal')

subplot(3,1,2)
%figure('Position', [403,26,389,640])
%plot(time,(yVT-mean(yVT))*1e6)
plot(time,yVT*1e6)
xlabel('Tempo (s)')
ylabel('Amplitude (\mum)')
xlim([0 14])
ylim([-1275 -1075])
grid on
title('Resposta vertical')

subplot(3,1,3)
%figure('Position', [403,26,389,640])
plot(time,speed*60)
xlabel('Tempo (s)')
ylabel('Velocidade (RPM)')
xlim([0 14])
grid on
title('Velocidade versus tempo')

figure('Position', [403,26,389,404])
rpm1 = speed*60 ;
[mag,rpm,time] = ordertrack(detrend(resample(xVT,1,5)),1/delta_t/5,resample(rpm1,1,5),[0.48 1 2 3]);
[mag2,rpm2,time2] = ordertrack(detrend(resample(yVT,1,5)),1/delta_t/5,resample(rpm1,1,5),[0.48 1 2 3]);
subplot(2,1,1)
plot(rpm, mag*1e6)
xlabel('Velocidade (RPM)')
ylabel('Amplitude (\mum)')
xlim([0 3500])
ylim([0 50])
title('Resposta horizontal')
legend('Ordem 0.48','Ordem 1', 'Ordem 2','Ordem 3','Location','northwest')
grid on
subplot(2,1,2)
plot(rpm2, mag2*1e6)
xlabel('Velocidade (RPM)')
ylabel('Amplitude (\mum)')
xlim([0 3500])
ylim([0 60])
title('Resposta vertical')
legend('Ordem 0.48','Ordem 1', 'Ordem 2','Ordem 3','Location','northwest')
grid on







