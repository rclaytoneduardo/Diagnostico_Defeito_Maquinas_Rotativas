function matrix = plotbodetest(iKT,xVT,yVT,tdelta,speed,speedc) %[adm],[m],[m],[s],[rps],[rps]

speed_max = 60;
n_speed_step = 30;
freq_max = speed_max;
n_freq_step = 30;
fs=1/tdelta;
twin=1; % Duração da onda amostrada para Full Spectrum [s]


Lx = length(xVT); 
i1=1;
idelta=round(twin/tdelta);
iend=round(Lx/idelta)*idelta;
k=1;

if iend/n_speed_step >= idelta
    i1delta=round(iend/n_speed_step+1); %Sem sobreposição da janela
else
    i1delta=round((iend-idelta)/(n_speed_step)); % Com sobreposição da janela
end

% Slow Roll Compensation
if speedc > 0 
    stop = 0;
    while speed(k) <= speed_max && (i1+idelta) <= iend && stop == 0
        if speed(k) >= speedc
            stop = 1;
            icycle=min(find(iKT >= k));
            xVTcycle = xVT(iKT(icycle):iKT(icycle+1)-1);
            yVTcycle = yVT(iKT(icycle):iKT(icycle+1)-1);
            xVT30 = xVTcycle';
            yVT30 = yVTcycle';
            % Concatenação para formação de um trem de rotação
            for itrain = 1:30
                xVT30 = vertcat(xVT30,xVTcycle');
                yVT30 = vertcat(yVT30,yVTcycle');
            end
            % Filtragem do sinal na frequencia de rotação
            xVT30 = detrend(xVT30');
            yVT30 = detrend(yVT30');
            f1 = 2*speed(k)*0.9/fs;
            f2 = 2*speed(k)*1.1/fs;
            [b1,a1] = butter(2,[f1 f2]); % Filtragem em 1X
            xVT_1x = filtfilt(b1,a1,xVT30);
            yVT_1x = filtfilt(b1,a1,yVT30);

            Lcycle = length(xVTcycle);
            
            xVT_1xcycle = xVT_1x(Lcycle*15:Lcycle*16);
            [C,I] = max(xVT_1xcycle);
            xVTphi = I/(Lcycle)*360; 
            xVTmag = (max(xVT_1xcycle)-min(xVT_1xcycle))/2;
            
            yVT_1xcycle = yVT_1x(Lcycle*15:Lcycle*16);
            [C,I] = max(yVT_1xcycle);
            yVTphi = I/(Lcycle)*360; 
            yVTmag = (max(yVT_1xcycle)-min(yVT_1xcycle))/2;
            
            for i=1:length(iKT)-1
                xVTc = [];
                yVTc = [];
                iL = iKT(i+1)-iKT(i);
                ispeed = mean(speed(iKT(i):iKT(i+1)));
                for ii=1:iL
                    xVTc(ii) = xVTmag*cos(2*pi*ispeed*(ii-1)*tdelta-xVTphi*pi/180);
                    yVTc(ii) = yVTmag*cos(2*pi*ispeed*(ii-1)*tdelta-yVTphi*pi/180);
                end
                xVT(iKT(i):iKT(i+1)-1) = xVT(iKT(i):iKT(i+1)-1)-xVTc;
                yVT(iKT(i):iKT(i+1)-1) = yVT(iKT(i):iKT(i+1)-1)-yVTc;
                
            end
        end
        k = k+1;
    end
end



speed_i = 6;
step_speed = 0.2;
k=1;
j=1;
while speed_i+step_speed < 59 
    if speed(k) >= speed_i
            icycle=min(find(iKT >= k)); % iKT é o indice do degrau positivo do tacho 
            xVTcycle = xVT(iKT(icycle):iKT(icycle+1)-1); % seleciona o primeiro ciclo
            yVTcycle = yVT(iKT(icycle):iKT(icycle+1)-1);
            xVT30 = xVTcycle';
            yVT30 = yVTcycle';
            % Concatenação para formação de um trem de rotação
            for itrain = 1:30
                xVT30 = vertcat(xVT30,xVTcycle'); % concatena o ciclo 30 vezes
                yVT30 = vertcat(yVT30,yVTcycle');
            end
            % Filtragem do sinal na frequencia de rotação
            xVT30 = detrend(xVT30');
            yVT30 = detrend(yVT30');
            f1 = 2*speed(k)*0.9/fs;
            f2 = 2*speed(k)*1.1/fs;
            [b1,a1] = butter(2,[f1 f2]); % Filtragem em 1X
            xVT_1x = filtfilt(b1,a1,xVT30);
            yVT_1x = filtfilt(b1,a1,yVT30);

            Lcycle = length(xVTcycle);
            
            xVT_1xcycle = xVT_1x(Lcycle*15:Lcycle*16); % seleciona o ciclo do meio filtrado
            [C,I] = max(xVT_1xcycle);
            xVTphi(j) = I/(Lcycle)*360; 
            xVTmag(j) = (max(xVT_1xcycle)-min(xVT_1xcycle))/2;
            
            yVT_1xcycle = yVT_1x(Lcycle*15:Lcycle*16);
            [C,I] = max(yVT_1xcycle);
            yVTphi(j) = I/(Lcycle)*360; 
            yVTmag(j) = (max(yVT_1xcycle)-min(yVT_1xcycle))/2;
            
            speedbode(j) = mean(speed(iKT(icycle):iKT(icycle+1)-1));
            
            j=j+1;
            speed_i = speed_i+step_speed;
    end
    k = k+1;
    
end
matrix = [xVTmag' xVTphi' yVTmag' yVTphi' speedbode'];
figure(3)
ax1 = subplot(2,1,1);
plot(speedbode,xVTmag)
xlabel('Frequencia [Hz]')
ylabel('Amplitude p [m]')
hold(ax1,'on')
ax2 = subplot(2,1,2);
plot(speedbode,min(unwrap(xVTphi,180))-unwrap(xVTphi,180))
xlabel('Frequencia [Hz]')
ylabel('Fase [graus]')
hold(ax2,'on')
hold on
figure(3)
ax1 = subplot(2,1,1);
plot(speedbode,yVTmag)
xlabel('Frequencia [Hz]')
ylabel('Amplitude p [m]')
hold(ax1,'on')
ax2 = subplot(2,1,2);
plot(speedbode,min(unwrap(yVTphi,180))-unwrap(yVTphi,180))
xlabel('Frequencia [Hz]')
ylabel('Fase [graus]')
hold(ax2,'on')
hold on

%semilogx(speedbode,min(unwrap(yVTphi,180))-unwrap(yVTphi,180))






    
    
    
 