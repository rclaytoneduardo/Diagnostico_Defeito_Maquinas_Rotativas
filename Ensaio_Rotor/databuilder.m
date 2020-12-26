function databuilder(matrix)
%Gravação dos dados
prompt = '\nSalvar? s/n [n]: ';
str = input(prompt,'s');
%str = 's';
if str == 's'
    time = datestr(now,'yymmddHHMMSS');
    namevar='matrix';
    namefile=char(strcat('matrix',time,'.mat'));
    eval([namevar,' = matrix;']);
    save(namefile, namevar);
    disp('Salvo!');
end







 