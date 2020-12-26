%Nova visualização da matriz
load('MyColormap.mat')
figure()
%surf(X,Y,Z); view (0,90)
surf(matrix); view (0,270)
colormap(mymap)
shading interp;
set(gcf,'Renderer','opengl')
colorbar('southoutside')

%colormapeditor

%ax = gca;
%mymap = colormap(ax);
%save('MyColormap','mymap')