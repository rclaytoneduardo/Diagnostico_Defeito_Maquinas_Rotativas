function matrix = plotspectrum(iKT,xVT,yVT,tdelta,speed,speedc) %[adm],[m],[m],[s],[rps],[rps]

speed_max = 60;
n_speed_step = 30;
freq_max = speed_max;
n_freq_step = 30;
fs=1/tdelta;
twin=1; % Duração da onda amostrada para Full Spectrum [s]

speed_i = 0;
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

figure(1)
i1=1;
k=1;
while speed_i <= speed_max && (i1+idelta) <= iend
    i2=i1+idelta;
    speedm(k)= mean(speed(i1:i2));
    Vx=xVT(i1:i2);
    Vy=yVT(i1:i2);
    
    % Filtragem do ruído de alta frequência
    fc = 3*2*speedm(k)/fs;  
    [b1,a1] = butter(5,fc,'low');% here 5 is the order of the filter; The asymptotic roll-off of an nth order is 20n dB/decade
    Vx = filtfilt(b1,a1,Vx);
    Vy = filtfilt(b1,a1,Vy);
    Vx = detrend(Vx);
    Vy = detrend(Vy);
    
    %%
    Vxy = complex(Vx, Vy);
    L = length(Vx);
    Y = 8/3*2*abs(fft(Vxy'.*hann(L))/L); % Compensação do janelamento -> 8/3
    Y = fftshift(Y);
    F = fs*[-L/2:L/2-1]/L;
    F = F(round(L/2+1-L*freq_max/fs):round(L/2+L*freq_max/fs));
    Y = Y(round(L/2+1-L*freq_max/fs):round(L/2+L*freq_max/fs));
    %Vetores para dados de treinamento plotagem do Cascata de Full Spectrum
    FSf(k,:)=F';
    FSy(k,:)=Y;
    L_F=speedm(k)./ones(1,length(F));
    plot3(L_F*60*1e-3,FSf(k,:)*60*1e-3,FSy(k,:)*1e6*2) %[kcpm, krpm, mmpp]
   


    
    %h.ZAxisLocation = 'right';
    %h.YAxisLocation = 'left';
    
    hold on; 
    FSwm(k)=speedm(k); %Check Fullspectrum
    ORBx(k,:)=Vx; %Check Fullspectrum
    ORBy(k,:)=Vy; %Check Fullspectrum
    
    speed_i = speedm(k);
    i1=i1+i1delta;
    k=k+1;
end
%Plotagem do Cascata de Full Spectrum
%view(80,-45)
view(89.999,-65)
%ZAxisLocation = 'right';
%YAxisLocation = 'left';
%title('Cascade')
xlabel('Rotação (krpm)')
ylabel('Frequência (kcpm)')
zlabel('Resposta (um pp)')

%rotate3d

%Matrix da Cascata
Ln = length(Y);
group= floor(Ln/n_freq_step);
matrix = zeros(n_speed_step,n_freq_step);
j=1;
for n=1:n_freq_step
    for m=1:n_speed_step
        matrix(m,n)=max(FSy(m,j:j+group-1));
    end
    j=j+group;
end

% Normalização da matriz
matrix = matrix/max(matrix(:));

figure(2)
matrix = flipud(matrix);
load('MyColormap.mat')

%surf(X,Y,Z); view (0,90)
surf(matrix); view (0,270)
colormap(mymap)
shading interp;
set(gcf,'Renderer','opengl')
colorbar('southoutside')

%Check Fullspectrum

% figure
% k=1;
% key=0;
% n=length(FSwm);
% while key == 0
%     subplot(2,1,1);
%     plot(ORBx(k,:),ORBy(k,:))
%     axis equal
%     title('Orbit [m] x [m]')
%     subplot(2,1,2);
%     plot(FSf(k,:)/FSwm(k),FSy(k,:))
%     title(['Full Spectrum [Ordem] x [m] - freq.=',num2str(FSwm(k)),'[Rev/s]'])
%     opcao = menu('Clique numa opção:','-->','<--','Sair');
%     switch opcao
%         case 1
%             if k < n
%                 k = k+1;
%              else
%                 k=k;
%             end
%         case 2 
%             if k > 1
%                 k = k-1;
%             else
%                 k=k;
%             end
%         otherwise
%             key = 1;
%             close all
%     end
% end

    
    
    
 