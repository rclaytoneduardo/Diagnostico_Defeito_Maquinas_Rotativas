function databuilder(fail,matrix,disk_node,r0,r1,r2,r3,r4,r4p)
%Gravação dos dados
%prompt = '\nSalvar? s/n [n]: ';
%str = input(prompt,'s');
str = 's';
if str == 's'
    time = datestr(now,'yymmddHHMMSS');
    namevar=char('matrix');
    namefile=char(strcat('matrix',time,'.mat'));
    eval([namevar,' = matrix;']);
    save(namefile, namevar);
    disp('Salvo!');
end

%registro dos dados:

namefilereg=char(strcat('register_',fail,'.mat'));
if nargin < 8
    reg = struct('disk_node',disk_node,'r0',r0,'r1',r1,'r2',r2,'r3',r3);
elseif nargin < 9
    reg = struct('disk_node',disk_node,'r0',r0,'r1',r1,'r2',r2,'r3',r3,'r4',r4);
else
    reg = struct('disk_node',disk_node,'r0',r0,'r1',r1,'r2',r2,'r3',r3,'r4',r4,'r4p',r4p);
end
namereg=char(strcat('matrix',time));
eval([namereg, '= reg;']);

if ~exist(namefilereg)
  save(namefilereg,namereg);
else
   save(namefilereg,namereg,'-append');
end

pause(3)






 