

% This function measures 3D surface area and 3D volume from 3D
% boundary points.
%
% Written by hui ting, 1 Aug 2023.


function [area_3d, volume_3d,f] = get_3D_area_volume(pixel_size,mask,H_nuc)

[y,x] = find(mask);

% boundary_bw = bwperim(mask);
boundary_bw = bwperim(imdilate(mask,strel('disk',1)));
[yb,xb] = find(boundary_bw);

x_um = pixel_size*(x);
y_um = pixel_size*(y);
xb_um = pixel_size*(xb);
yb_um = pixel_size*(yb);

lg_x = length(x);
z_um = nan(lg_x,1);

for p = 1:lg_x

height_nuc = H_nuc(y(p),x(p));
z_um(p) = height_nuc/2;

end

xyz1 = [x_um y_um z_um];
xyz2 = [x_um y_um -z_um];
xyz3 = [xb_um yb_um zeros(length(xb_um),1)];

xyz = [xyz1;xyz2;xyz3];

a = 4; % 4 best

shp = alphaShape(xyz,a);

area_3d = surfaceArea(shp);
volume_3d = volume(shp);

%figure;plot3(xyz(:,1),xyz(:,2),xyz(:,3),'.');axis equal;grid on;

figure;plot(shp);axis equal;grid on;
f = getframe(gcf);
% close all;










