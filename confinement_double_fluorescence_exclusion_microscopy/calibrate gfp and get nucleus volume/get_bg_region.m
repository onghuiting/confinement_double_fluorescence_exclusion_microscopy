


function [bg_region, min_idx_x, max_idx_x] = get_bg_region(mask_channel)

% figure;imshow(mask_channel,[]);

proj_vert_mean = mean(mask_channel,1);                   % figure;plot(proj_vert_mean);hold on;

max_pvm = prctile(proj_vert_mean,95);

idx_x = find(proj_vert_mean>=0.98*max_pvm);              % plot(idx_x,proj_vert_mean(idx_x),'ro');
min_idx_x = min(idx_x);
max_idx_x = max(idx_x);

bg_region = mask_channel;
bg_region(:,min_idx_x:max_idx_x) = 2;
bg_region(:,1:min_idx_x)=1;
bg_region(:,max_idx_x:end)=3;
bg_region = uint8(~mask_channel).*bg_region;

%figure;imshow(bg_region,[]);

end