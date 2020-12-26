% Nova visualização da matriz
load('MyColormapgray.mat')
figure()

b= bar3(matrix);
colorbar
for k = 1:length(b)
    zdata = b(k).ZData;
    b(k).CData = zdata;
    b(k).FaceColor = 'interp';
end
%surf(matrix); view (0,270)
h = colormap(mymapgray);
%h = 1-h;

%shading interp;
set(gcf,'Renderer','opengl')
colorbar('southoutside')

%colormapeditor

%ax = gca;
%mymap = colormap(ax);
%save('MyColormap','mymap')