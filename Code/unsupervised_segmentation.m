function [clust_cent_im, clust_lab] = unsupervised_segmentation(image, sp_labels, sp_centers, mask, opts)
    
%Perform Unsupervised segmentation of the regions using the superpixels
%
% ---INPUT---
% 
% image             - Hyperspectral data
% sp_labels         - Superpixel labels
% sp_centers        - Superpixel centers
% mask              - Mask of the regions to segment
% 
% ---OPTIONAL INPUT---
% 
% bandwidth         - Mean-shift parameter that manipulates the segmentation (Default:NaN -> value means that it will be automatically extracted)
% quantile          - Parameter that controls the automatic extraction of the bandwidth (Default: 0.05)
% perc_bandwidth    - Percentage of features vector to use for the bandwidth extraction (Default: NaN -> automatically computet based on the number of pixels)
% PCA_mode          - To use PCA = true (Default: false)
% perc_major        - Percentage of area to label the noise-pixel in the majority procedure (Default: 10)
%
% ---OUTPUT---
% 
% clust_cent_im     - Center of each cluster
% clust_lab         - Image where each pixel in the region of the mask is labeled in the correspondent superpixel


    arguments
        image
        sp_labels
        sp_centers
        mask
        opts.bandwidth (1,1) double = NaN
        opts.quantile (1,1) double {mustBeGreaterThan(opts.quantile,0), mustBeLessThanOrEqual(opts.quantile,1)} = 0.06
        opts.perc_bandwidth (1,1) double = NaN
        opts.PCA_mode (1,1) logical = false
        opts.perc_major (1,1) double = 10
    end

    % Resize Image, mask, superpixels labels
    original_size = size(image,1,2);
    min_value = min(original_size);
    image = imresize(image,[min_value, min_value]);
    mask = imresize(mask,[min_value, min_value], 'nearest');
    superpixels_label = imresize(sp_labels,[min_value, min_value], 'nearest');
    
    % PCA =============================================================
    
    if(opts.PCA_mode)
        features = reshape(image, [prod(size(image,1,2)), size(image,3)]);
        feat_centers = sp_centers;

        % PCA on the image data
        [coeff,~,~,~,explained,~] = pca(features);
        I = image;
        Itransformed = features*coeff;

        new_im = [];
        ex_sum = 0;
        ex_index = 1;
        while(ex_sum <= 99.9)
            ex_sum = ex_sum + explained(ex_index);
            Ipc = reshape(Itransformed(:,ex_index),size(I,1),size(I,2));
            new_im = cat(3, new_im, Ipc);
            ex_index = ex_index + 1;
        end
        image = new_im;

        % PCA on the centers
        [coeff,~,~,~,explained,~] = pca(feat_centers);
        Itransformed = feat_centers*coeff;

        new_sp_centers_hyp = [];
        ex_sum = 0;
        ex_index = 1;
        while(ex_sum <= 99.9)
            ex_sum = ex_sum + explained(ex_index);
            Ipc = Itransformed(:,ex_index);
            new_sp_centers_hyp = cat(2, new_sp_centers_hyp, Ipc);
            ex_index = ex_index + 1;
        end
        sp_centers = new_sp_centers_hyp;
    end

    % Concatenation of the image with the superpixel centers ==============
    
    sp_centers_list = sp_centers;

    centers_image = zeros([size(image,1)*size(image,2), size(sp_centers,2)]);
    for j = 1:size(unique(superpixels_label),1)
        indexes = find(superpixels_label == j);
        for k = 1:size(indexes,1)
            centers_image(indexes(k), :) = sp_centers_list(j,1:end); 
        end
    end

    image_aux = reshape(image, [prod(size(image,1,2)), size(image,3)]);

    indexes = find(not(mask==0)); % 0 represents the background of the gt
    center_list = centers_image(indexes,:);
    image_list = image_aux(indexes,:);
    
    features = cat(2, image_list, center_list);

    % Clustering ==========================================================
    
    fprintf('Clustering -----------------------------------------------------\n');
    
    if(isnan(opts.bandwidth))   % automatically selection of bandwidth
        if(isnan(opts.perc_bandwidth))    % automatically selection a percentance of the features list that use about 21025 features vectors
            perc_bandwidth = 21025*100/size(features,1);
        else
            perc_bandwidth = opts.perc_bandwidth;
        end
        if(isnan(opts.quantile))
            ME = MException('Variables:valuesNotGood', 'Bandwidth and quantile cannot be both None');
            throw(ME)
        end
        bandwidth = double(py.python_utility.estimate_bandwidth_meanshift(py.numpy.array(features), perc_bandwidth, opts.quantile));
    else
        bandwidth = opts.bandwidth;
    end

%     [sp_clustCent,sp_data2cluster,~] = MeanShiftCluster(features',bandwidth,false);
    [~,sp_data2cluster,~] = MeanShiftCluster(features',bandwidth,false);
%     new_sp_data = sp_clustCent(:,sp_data2cluster)';
    
    % Reconstruction of the image with background =========================
    
%    clust_cent_im = zeros([size(image,1), size(image,2), size(features, 2)]);
    clust_lab = zeros(size(mask))-1;

    list_index = 1;
    for j = 1:size(mask,2)
        for i = 1:size(mask,1)
            if(not(mask(i,j) == 0))
                %clust_cent_im(i,j,:) = new_sp_data(list_index,:);
                clust_lab(i,j) = sp_data2cluster(list_index);

                list_index = list_index + 1;
            end
        end
    end
    
    % Major voting ========================================================
    
    clust_lab = major_voting_cluster_eliminate(clust_lab, opts.perc_major);

    % New centers
    image_features = cat(2, image_aux, centers_image);
    cluster_centers = zeros([max(clust_lab,[],'all'), size(image_features,2)])-1; %size(clust_cent_im,3)]); %clust_cent_im can be substituite with aux_image
    for i=1:max(clust_lab,[],'all')
        cluster_indexes = find(clust_lab == i);
        if(not(isempty(cluster_indexes)))
            cluster_centers(i,:) = mean(image_features(cluster_indexes,:));
         end
    end
%     new_cluster_centers = reshape(new_cluster_centers, size(cluster_centers));
    
    clust_cent_im = cluster_centers;
    clust_lab = imresize(clust_lab, original_size, 'nearest');
    
    %TODO ricostruire immagine
    
    fprintf('Clustering end -------------------------------------------------\n');
    
end

%% Major voting function

function new_labels = major_voting_cluster_eliminate(original_labels, val_reg)

    original_labels(original_labels == -1) = max(original_labels,[],'all')+1; % background as max
    labels_aux = original_labels;

    regions = not(original_labels == max(original_labels, [], 'all'));
    regions_label = bwlabel(regions);
    regions_label(regions_label == 0) = max(regions_label,[],'all')+1;

    regions_list = unique(regions_label);
    for regions_ind = 1:size(regions_list,1)-1 %-1 because background is max + 1 --> not considered
        labeled_regions = original_labels.*(regions_label == regions_list(regions_ind));  %region extraction and background become 0
        
        clust_area = regionprops(labeled_regions, 'Area');
        clust_area = [clust_area.Area];

        clust_area_sum = sum(clust_area,'all');
        
        labels_aux_backup = labels_aux;
        eliminated_area = 0;
        for clust_ind = 1:size(clust_area,2)
            if(not(clust_area(clust_ind)==0) && clust_area(clust_ind) < (clust_area_sum*val_reg/100))
                eliminated_area = eliminated_area + clust_area(clust_ind);
                indexes = labeled_regions == clust_ind;
                labels_aux(indexes) = -2;   % -2 represents the noise-pixels
            end
        end
        if(eliminated_area >= (clust_area_sum*90/100))  % if noise_pixel are more than 90% of the region area, go back to original label for that region
            labels_aux = labels_aux_backup;
        end
    end
    original_labels = labels_aux;
    pixel_not_labeled = find(original_labels == -2);

    cont_change = true;
    while(not(isempty(pixel_not_labeled)) && cont_change)
        cont_change = false;
        for not_labeled_ind=1:numel(pixel_not_labeled)
            [x,y] = ind2sub(size(original_labels), pixel_not_labeled(not_labeled_ind));
            window = original_labels(clip(x-1,1,size(original_labels,1)):clip(x+1,1,size(original_labels,1)),...
                    clip(y-1,1,size(original_labels,2)):clip(y+1,1,size(original_labels,2)));

            element_list = unique(window);
            cont_list = zeros(numel(element_list),1);
            for current_window_ind=1:numel(window)
                if(not(window(current_window_ind) == -2) && not(window(current_window_ind) == max(original_labels,[],'all')))
                    cont_list(element_list == window(current_window_ind)) = cont_list(element_list == window(current_window_ind)) + 1;
                end
            end

            [~, max_ind] = max(cont_list);
            original_labels(x,y) = element_list(max_ind(1));
            cont_change = true;
        end
        pixel_not_labeled = find(original_labels == -2);
    end

    new_list_class = unique(original_labels);
    labels_aux = original_labels;
    for i = 1:size(new_list_class)
        labels_aux(original_labels == new_list_class(i)) = i;
    end
    original_labels = labels_aux;
    original_labels(original_labels == max(original_labels,[],'all')) = 0; % background set to zeros
    
    new_labels = original_labels;
end
    
%% Aux functions

function y = clip(x,bl,bu)
    y=min(max(x,bl),bu);
end