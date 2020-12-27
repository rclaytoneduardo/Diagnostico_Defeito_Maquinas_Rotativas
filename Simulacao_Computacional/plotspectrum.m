function matrix = plotspectrum(x,y,tdelta,speed) %[m],[m], [s], [rps]

speed_max = 60;
n_speed_step = 30;
freq_max = speed_max;
n_freq_step = 30;
twin=1; % Duração da onda amostrada para Full Spectrum [s]

speed_i = 0;
Lx = length(x); 
i1=1;
idelta=round(twin/tdelta);
iend=round(Lx/idelta)*idelta;
k=1;

if iend/n_speed_step >= idelta
    i1delta=round(iend/n_speed_step+1);
else
    i1delta=round((iend-idelta)/(n_speed_step));
end

%figure %desativar
while speed_i <= speed_max && (i1+idelta) <= iend
    i2=i1+idelta;
    speedm(k)=(speed(i1)+speed(i2))/2;
    Vx=x(i1:i2);
    Vy=y(i1:i2);
    fs=1/tdelta;
    Vx = detrend(Vx);
    Vy = detrend(Vy);
    Vxy = complex(Vx, Vy);
    L = length(Vx);
    Y = 8/3*abs(fft(Vxy'.*hann(L))/L); % Compensação do janelamento -> 8/3
    Y = fftshift(Y);
    F = fs*[-L/2:L/2-1]/L;
    F = F(round(L/2+1-L*freq_max/fs):round(L/2+L*freq_max/fs));
    Y = Y(round(L/2+1-L*freq_max/fs):round(L/2+L*freq_max/fs));
    
    %Vetores para dados de treinamento plotagem do Cascata de Full Spectrum
    FSf(k,:)=F';
    FSy(k,:)=Y;
    L_F=speedm(k)./ones(1,length(F));
    
    %plot3(L_F,FSf(k,:),FSy(k,:)*1e6) %desativar
    %hold on; %desativar
    
    FSwm(k)=speedm(k);
    ORBx(k,:)=Vx;
    ORBy(k,:)=Vy;
    speed_i=speedm(k);
    i1=i1+i1delta;
    k=k+1;
end
%Plotagem do Cascata de Full Spectrum
% view(80,-45)
% title('Cascade')
% xlabel('Rotor speed (rev/s)')
% ylabel('Frequency (Hz)')
% zlabel('Amplitude (um)')
% rotate3d


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

figure
matrix = flipud(matrix);
bar3(matrix)
rotate3d

% %Checking Fullspectrum (para comentarios: control + r / para retornar: control + t )
% figure
% k=1;
% key=0;
% n=length(FSwm);
% while key == 0
%     subplot(2,1,1);
%     plot(ORBx(k,:),ORBy(k,:))
%     %axis equal
%     axis square
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

    
    
    
 