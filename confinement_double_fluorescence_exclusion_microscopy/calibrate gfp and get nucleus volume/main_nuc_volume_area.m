

% This code is for calibrating GFP intensity and measuring nucleus volume
% (in um3) and 3D surface area (in um2).
%
% Note:
% GFP channel has different background values inside and outside narrow channel.
% GFP image need to be subtracted by different background values at different region. 
% Or else, the calibration will have problem at the frames, where part of
% the cell is inside the channel and part of the cell is outside the channel.
%
% Update(8 Aug): 
% Three if conditions added (line222-line257), mainly to deal with empty masks 
% One if condition added to the end (line299-line301), to remove empty folders
% Other minor changes to the output file 
%
% Written by hui ting, 1 Aug 2023.
% Edited by yixuan, 8 Aug 2023.
% Edited by hui ting, 10 July 2024. (Output filenames in excel file)


close all;clear all;clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pixel_size = 0.2305798; % um/pixel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pathname = uigetdir("Select your input folder");
files = dir(fullfile(pathname,'*_Hc.tif'));
total_files = length(files)

for ifile = 1:total_files
    
height_map_filename = files(ifile).name
GFP_filename = strrep(height_map_filename,'_Hc.tif','_GFP.tif');
mask_channel_filename = strrep(height_map_filename,'_Hc.tif','_channel_mask.tif');  
mask_cell_filename = strrep(height_map_filename,'_Hc.tif','_cell_label.tif');                                  
mask_cell_body_filename = strrep(height_map_filename,'_Hc.tif','_cell_body_label.tif'); 

GFP_stack = tiffreadVolume(fullfile(pathname,GFP_filename));
height_map_stack = tiffreadVolume(fullfile(pathname,height_map_filename));
mask_channel = imread(fullfile(pathname,mask_channel_filename));
mask_cell_stack = tiffreadVolume(fullfile(pathname,mask_cell_filename));
mask_cb_stack = tiffreadVolume(fullfile(pathname,mask_cell_body_filename));

number_of_cells = max(mask_cell_stack,[],"all");

for icell=1:number_of_cells

fi_name1 = {[height_map_filename(1:end-7) '_cell_' num2str(icell)]};
main_res_folder = fullfile(pathname, [height_map_filename(1:end-7) '_cell_' num2str(icell)]);
res_folder1 = fullfile(main_res_folder,'plots');
res_folder2 = fullfile(main_res_folder,'GFP_sb');
res_folder3 = fullfile(main_res_folder,'H_gfp');
res_folder4 = fullfile(main_res_folder,'refined_cell_mask');
res_folder5 = fullfile(main_res_folder,'refined_cell_body_mask');
res_folder6 = fullfile(main_res_folder,'refined_nuc_mask');
res_folder7 = fullfile(main_res_folder,'mat_and_excel_files');
res_folder8 = fullfile(main_res_folder,'H_nuc');
res_folder9 = fullfile(main_res_folder,'3D_reconstruction');
mkdir(main_res_folder);
mkdir(res_folder1);
mkdir(res_folder2);
mkdir(res_folder3);
mkdir(res_folder4);
mkdir(res_folder5);
mkdir(res_folder6);
mkdir(res_folder7);
mkdir(res_folder8);
mkdir(res_folder9);

total_frames = size(height_map_stack,3)
mean_height_cell = nan(total_frames,1);
m_rb = mean_height_cell;
c_rb = mean_height_cell;
Hc_mean = mean_height_cell;
H_gfp_mean= mean_height_cell;
Hc_volume = mean_height_cell;
H_gfp_volume = mean_height_cell;
nuc_volume = mean_height_cell;
cell_volume = mean_height_cell;
cell_body_volume = mean_height_cell;
x_nuc = mean_height_cell;
y_nuc = mean_height_cell;
area_3d = mean_height_cell;
volume_3d = mean_height_cell;
r_square = mean_height_cell;


[bg_region, min_idx_x, max_idx_x] = get_bg_region(mask_channel);

figure;
for t=1:total_frames

green = GFP_stack(:,:,t);
Hc = height_map_stack(:,:,t);

mask_cell = mask_cell_stack(:,:,t);
mask_cell = mask_cell==icell;

if (sum(mask_cell(:)>0))

mask_cell_e1 = imerode(mask_cell,strel('disk',1));
mask_cell_e2 = imerode(mask_cell,strel('disk',2));

mask_cb = mask_cb_stack(:,:,t);                      % figure;imshow(mask,[]);
mask_cb = mask_cb==icell;
mask_cb_e1 = imerode(mask_cb,strel('disk',1));
mask_cb_e2 = imerode(mask_cb,strel('disk',2));       % figure;imshow(mask,[]);

green = medfilt2(green,[3 3],'symmetric');        % figure(100);imshow(green,[]);
Hc = medfilt2(Hc,[3 3],'symmetric');

bg0 = prctile(green(bg_region==0),10);
bg1 = prctile(green(bg_region==1),10);
bg2 = prctile(green(bg_region==2),10);
bg3 = prctile(green(bg_region==3),10);

bg_img = uint16(bg_region);
bg_img(bg_region==0)=bg0;
bg_img(bg_region==1)=bg1;
bg_img(bg_region==2)=bg2;
bg_img(bg_region==3)=bg3;                        % figure(200);imshow(bg_img,[]);

green_sb = uint16(green-bg_img);                 % figure(300);imshow(green_sb,[]);
green_sb = uint16(~mask_channel).*green_sb;

g_int = green_sb(mask_cb_e2>0);
hc_values = Hc(mask_cb_e2>0);                       % figure;scatter(hc_values, g_int);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mean_height_cell(t) = mean(hc_values);
h_intv_c = round(mean_height_cell(t));
h_intv_max1 = h_intv_c+1; % +1um
h_intv_min1 = 0;
h_intv_min = max(h_intv_min1,0);
h_intv_max = min(h_intv_max1,10); % 10um is the maximum height

h_intv = h_intv_min:0.1:h_intv_max; 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

total_intv = length(h_intv)-1;

g = nan(total_intv,1);
n = g;
h = g;
h1 = g;

for c = 1:total_intv

idx = find((hc_values>h_intv(c))&(hc_values<=h_intv(c+1)));
n(c)=length(idx);
h1(c)=(h_intv(c)+h_intv(c+1))/2;
if n(c)>=5 
g(c)=nanmean(g_int(idx));
h(c)=h1(c);
end

end

if (length(g(~isnan(g)))>=3)
cla;scatter(h,g);hold on;
rb = robustfit(h(~isnan(g)),g(~isnan(g)),'bisquare',3.5); % 3, Default = 4.685
m_rb(t)=rb(2);
c_rb(t)=rb(1);
eqn = string(" Linear: y = " + m_rb(t)) + "x + " + string(c_rb(t)); % rb(1) = c, rb(2) = m
text(1,200,eqn,"HorizontalAlignment","left","VerticalAlignment","top");

%get the r square
X = rmmissing(h);
Y = rmmissing(g);
r_square(t) = corr(Y,rb(1) +rb(2)*X);


x_rb = h1;
y_rb = m_rb(t)*x_rb+c_rb(t);
plot(x_rb,y_rb,'r-');

xlim([0 10]);
ylim([0 300]);
saveas(gcf,fullfile(res_folder1,[num2str(t) '.tif']));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

H_gfp = (double(green_sb)-c_rb(t))/m_rb(t);
H_gfp(H_gfp<0)=0;

% Replace super bright gfp spots with median gfp value
H_gfp_cb_median = median(H_gfp(mask_cb_e2>0));
H_gfp(H_gfp>=11&mask_cb_e1>0)=H_gfp_cb_median;

mask_nuc = mask_cell-mask_cb;
refined_cell_mask = logical(mask_cell_e1);
refined_nuc_mask = refined_cell_mask&logical(mask_nuc);

H_gfp_nuc_median = median(H_gfp(refined_nuc_mask>0));
H_gfp(H_gfp>=11&refined_nuc_mask>0)=H_gfp_nuc_median;
V_gfp = H_gfp*pixel_size*pixel_size;
Vc = Hc*pixel_size*pixel_size;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


H_nuc = Hc-H_gfp;

refined_nuc_mask(H_nuc<0)=0;
refined_nuc_mask = imopen(refined_nuc_mask,strel('disk',2)); % 1 or 2 ?
refined_nuc_mask = bwareafilt(refined_nuc_mask,1);
refined_cb_mask = refined_cell_mask-refined_nuc_mask;

s = regionprops(imfill(refined_nuc_mask,"holes"), 'centroid');
centroids = cat(1, s.Centroid);

if length(centroids)~=0

    if isequal(length(centroids(:,1)),1)
    
    x_nuc(t)=centroids(:,1);
    y_nuc(t)=centroids(:,2);
    
    Hc_mean(t)= mean(Hc(mask_cb_e1>0));          % check cell body
    H_gfp_mean(t) = mean(H_gfp(mask_cb_e1>0));   % check cell body
    
    Hc_volume(t)= sum(Vc(refined_nuc_mask>0)); % cell volume (cb+nuc) within nuc mask
    H_gfp_volume(t) = sum(V_gfp(refined_nuc_mask>0)); % cell body volume within nuc mask
    nuc_volume(t) = Hc_volume(t)-H_gfp_volume(t); % nuc volume within nuc mask
    
    cell_volume(t) = sum(Vc(refined_cell_mask>0)); % cell volume (cb+nuc) within cell mask
    cell_body_volume(t) = cell_volume(t)-nuc_volume(t); % cell body volume
        
        if (sum(~isnan(H_nuc))~=0)
        
        [area_3d(t), volume_3d(t),f] = get_3D_area_volume(pixel_size,refined_nuc_mask,H_nuc);
        
        imwrite(green_sb, fullfile(res_folder2,[num2str(t) '.tif']));
        imwrite(refined_cell_mask, fullfile(res_folder4,[num2str(t) '.tif']), 'tif','Compression','none');
        imwrite(refined_cb_mask, fullfile(res_folder5,[num2str(t) '.tif']), 'tif','Compression','none');
        imwrite(refined_nuc_mask, fullfile(res_folder6,[num2str(t) '.tif']), 'tif','Compression','none');
        write32bit(H_gfp,fullfile(res_folder3,[num2str(t) '.tif']));
        write32bit(H_nuc,fullfile(res_folder8,[num2str(t) '.tif']));
        imwrite(f.cdata,fullfile(res_folder9,[num2str(t) '.tif']));
        
        end
    
    end
end

end
end

x_idx = [min_idx_x, max_idx_x];
relative_x_um = (max_idx_x-x_nuc)*pixel_size;
tp = [1:total_frames]';
fi_name = repmat(fi_name1,total_frames,1);
save(fullfile(res_folder7,"m_rb.mat"),"m_rb")
save(fullfile(res_folder7,"c_rb.mat"),"c_rb")
save(fullfile(res_folder7,"Hc_mean.mat"),"Hc_mean")
save(fullfile(res_folder7,"H_gfp_mean.mat"),"H_gfp_mean")
save(fullfile(res_folder7,"x_idx.mat"),"x_idx")

close all;

writecell({'frame','çell_volume','cell_body_volume','nuc_volume','nuc_volume (3D recon)','nuc_surface_area (3D recon)','x_nuc(pixels)','y_nuc(pixels)','x_nuc_relative(um)','R square','file_name'},fullfile(res_folder7,'nuc_volume.xlsx'),'Range','A1');
writecell(fi_name,fullfile(res_folder7,'nuc_volume.xlsx'),'Range','K2');
writematrix([tp cell_volume cell_body_volume nuc_volume volume_3d area_3d x_nuc y_nuc relative_x_um r_square],fullfile(res_folder7,'nuc_volume.xlsx'),'Range','A2');

figure;
plot(Hc_mean,'b-');hold on;
plot(H_gfp_mean,'r-');
title('Cell body average height');
saveas(gcf,fullfile(res_folder7,"Cell_body_average_height.png"));

figure;
plot(Hc_volume,'b-');hold on;
plot(H_gfp_volume,'r-');hold on;
plot(nuc_volume,'m-');
title('Volume within nuc region');
legend('cell','cell body','nuc','Location','southeast');
saveas(gcf,fullfile(res_folder7,"Volume_within_nuc_region.png"));

figure;
plot(cell_volume,'b-');hold on;
plot(cell_body_volume,'r-');hold on;
plot(nuc_volume,'m-');
title('Volume');
legend('cell','cell body','nuc','Location','southeast');
saveas(gcf,fullfile(res_folder7,"Volume_changes.png"));

close all;

if (sum(~isnan(nuc_volume))==0)
rmdir(fullfile(pathname, [height_map_filename(1:end-7) '_cell_' num2str(icell)]),"s");
end

end

end


% figure;plot(nuc_volume);hold on;plot(volume_3d);


