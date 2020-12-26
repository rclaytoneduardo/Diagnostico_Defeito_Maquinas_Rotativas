% Nova visualização da matriz
load('MyColormapgray.mat')
figure()

surf(matrix); view (0,270)
h = colormap(mymapgray);
%h = 1-h;
colormap(h)
%shading interp;
set(gcf,'Renderer','opengl')
colorbar('southoutside')

%colormapeditor

%ax = gca;
%mymap = colormap(ax);
%save('MyColormap','mymap')