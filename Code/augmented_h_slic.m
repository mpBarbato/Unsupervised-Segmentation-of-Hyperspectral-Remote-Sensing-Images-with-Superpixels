function [superpixels_label, cluster_centers] = augmented_h_slic(image, n_cluster, m, m_clust, opts)
    
%Perform augmented Hyperspectral-SLIC of data using
%
% ---INPUT---
% 
% image         - Hyperspectral data to segment
% n_cluster     - Number of superpixels
% m             - Weight parameter of spatial information
% m_clust       - Weight parameter of similarity information
% 
% ---OPTIONAL INPUT---
% 
% bandwidth 	- Parameter for the extraction of the similarity information (Default:NaN -> value means that it will be automatically extracted)
% quantile      - Parameter that controls the automatic extraction of the bandwidth (Default: 0.05)
% perc          - Percentage of features vector to use for the bandwidth extraction (Default: NaN -> automatically computet based on the number of pixels)
% threshold     - Parameter that controls the stability of the superpixel segmetation (Default:0.01)
% 
% ---OUTPUT---
% 
% superpixels_label     - Image where each pixel is labeled in the correspondent superpixel
% cluster_centers       - List of superpixel centers
    
    arguments
        image
        n_cluster {mustBePositive}
        m (1,1) double {mustBePositive}
        m_clust (1,1) double {mustBeNonnegative}
        opts.bandwidth (1,1) double = NaN
        opts.quantile (1,1) double {mustBeGreaterThan(opts.quantile,0), mustBeLessThanOrEqual(opts.quantile,1)} = 0.05
        opts.perc (1,1) double = NaN
        opts.threshold (1,1) double = 0.01
    end

    n_cluster = int16(ceil(sqrt(n_cluster))^2);
    fprintf("The number of superpixels is: " + num2str(n_cluster) + "\n");
    
    if(m_clust < 0)
        ME = MException('Variables:valuesNotGood', 'm_clust must be >= 0');
        throw(ME)
    end
    
    if(m <= 0)
        ME = MException('Variables:valuesNotGood', 'm must be > 0');
        throw(ME)
    end

    % Resize Image
    original_size = size(image,1,2);
    min_value = min(original_size);
    image = imresize(image,[min_value, min_value]);

    % Extraction of similarity information ================================
    
    if(m_clust > 0)
        fprintf('Similarity information extraction ------------------------------\n');
        
        features_list = reshape(image,[prod(size(image,1,2)), size(image,3)]);
        if(isnan(opts.bandwidth))   % automatically selection of bandwidth
            if(isnan(opts.perc))    % automatically selection a percentance of the features list that use about 21025 features vectors
                perc = 21025*100/size(features_list,1);
            else
                perc = opts.perc;
            end
            if(isnan(opts.quantile))
                ME = MException('Variables:valuesNotGood', 'Bandwidth and quantile cannot be both None');
                throw(ME)
            end
            bandwidth = double(py.estimate_bandwidth_meanshift.estimate_bandwidth_meanshift(py.numpy.array(features_list), perc, opts.quantile));
        else
            bandwidth = opts.bandwidth;
        end
        
        [clustCent,data2cluster,~] = MeanShiftCluster(features_list',bandwidth,false);
        new_data = clustCent(:,data2cluster)';
        cluster_image = reshape(new_data, [size(image,1), size(image,2), size(image,3)]);
        
        image = cat(3, image, cluster_image);
        
        fprintf('Similarity information extraction end --------------------------\n');
    else
        image = cat(3, image, image); % the image concatened is not used
    end

    % AUGMENTED H-SLIC ====================================================

    % Center initialization
    fprintf('Clusters initialization ----------------------------------------\n');
    semi_area = sqrt(double((numel(image)/size(image,3))/double(n_cluster)));   % S value of SLIC
    cluster_centers = zeros(int32(sqrt(double(n_cluster))), int32(sqrt(double(n_cluster))), size(image,3)+2);
    
    if(m_clust > 0)
        gradient_image = mean(image, 3);
    else
        gradient_image = mean(image(:,:,end/2), 3);
    end
    
    [Gx,Gy] = imgradientxy(gradient_image);
    [gradient_image, ~] = imgradient(Gx, Gy);

    i = semi_area/2;
    j = semi_area/2;
    cluster_cont = 0;
    while(cluster_cont < n_cluster)
        start_index_x = i-1;
        end_index_x = i+1;
        start_index_y = j-1;
        end_index_y = j+1;
        
        % Extract indexes from gradient
        current_window_gradient = gradient_image(clip(int32(round(start_index_x)),1,size(image,1)):clip(int32(round(end_index_x)),1,size(image,1)),...
                                       clip(int32(round(start_index_y)),1,size(image,2)):clip(int32(round(end_index_y)),1,size(image,2)));
        
        min_value = min(current_window_gradient, [], 'all');
        min_index = find(current_window_gradient == min_value);
        min_index = min_index(1);
                                   
        [index_x, index_y] = ind2sub(size(current_window_gradient), min_index);
        index_x = start_index_x + index_x - 1;
        index_y = start_index_y + index_y - 1;

        cluster_centers(int32(floor(cluster_cont/size(cluster_centers,1)))+1,...
            int32(mod(cluster_cont, size(cluster_centers,2))+1),...
            1:end-2) = image(clip(int32(round(index_x)),1,size(image,1)), clip(int32(round(index_y)),1,size(image,2)),:);

        cluster_centers(int32(floor(cluster_cont/size(cluster_centers,1)))+1,...
            int32(mod(cluster_cont, size(cluster_centers,2))+1),...
            end-1:end) = [clip(int32(round(index_x)),1,size(image,1)), clip(int32(round(index_y)),1,size(image,2))];

        j = j + semi_area;

        if(j >= size(image,2))
            j = semi_area/2;
            i = i + semi_area;
        end

        cluster_cont = cluster_cont +  1;

    end

    superpixels_label = zeros(size(image,1,2))-1;
    distances_pixels = zeros(size(image,1,2))+99999999999999;

    fprintf('Clusters initialization end ------------------------------------\n'); 

    % H-Slic method =======================================================
    
    fprintf('Segmentation start ---------------------------------------------\n');

    iteration = 0;
    measure = 999999;
    last_measure = measure + 1;

    while(measure > opts.threshold && not(measure == last_measure))
        last_measure = measure;

        fprintf("iteration:" + num2str(iteration) + "\n");
        fprintf("measure:" + num2str(measure) + "\n");

        for i=1:size(cluster_centers,1)
            for j=1:size(cluster_centers,2)
                x = cluster_centers(i,j,end-1);
                y = cluster_centers(i,j,end);

                for k=floor(clip(x-semi_area,1,size(image,1))):ceil(clip(x+semi_area,1,size(image,1)))
                    for l=floor(clip(y-semi_area,1,size(image,2))):ceil(clip(y+semi_area,1,size(image,2)))
                        d_spec = vecnorm(image(k,l,1:size(image,3)/2) - cluster_centers(i,j,1:size(image,3)/2), 2, 3);
                        d_clust = vecnorm(image(k,l,(size(image,3)/2)+1:end) - cluster_centers(i,j,(size(image,3)/2)+1:end-2), 2, 3);
                        d_xy = vecnorm(reshape([k, l], [1,1,2]) - cluster_centers(i,j,end-1:end), 2, 3);
                        
                        d_s = sqrt((d_spec/(sqrt(size(image,3)/2)))^2 + m_clust*(d_clust/(sqrt(size(image,3)/2)))^2 + m*(d_xy/(semi_area*sqrt(2)))^2);
                        
                        if(distances_pixels(k,l) > d_s)
                            distances_pixels(k,l) = d_s;
                            superpixels_label(k,l) = sub2ind(size(cluster_centers,1,2), i,j);
                        end
                    end
                end
            end
        end

        % new_centers
        aux_image = reshape(image, [size(image,1)*size(image,2), size(image,3)]);
        new_cluster_centers = reshape(cluster_centers, [size(cluster_centers,1)*size(cluster_centers,2), size(cluster_centers,3)]);
        for i=1:n_cluster
            cluster_indexes = find(superpixels_label == i);
            if(not(isempty(cluster_indexes)))
                [aux_indexes_1, aux_indexes_2] = ind2sub(size(superpixels_label), cluster_indexes);
                new_cluster_centers(i,:) = mean(cat(2,aux_image(cluster_indexes,:), [aux_indexes_1, aux_indexes_2]));
             end
        end
        new_cluster_centers = reshape(new_cluster_centers, size(cluster_centers));

        measure = sum(sum(vecnorm(new_cluster_centers - cluster_centers, 1, 3)));
        cluster_centers = new_cluster_centers;

        iteration = iteration + 1;
    end

    % Post_processing =====================================================
    
    % Eliminate small superpixels
    clust_number = max(superpixels_label,[],'all');
    sum_area = 0;
    cont_clust = 0;
    for i = 1:clust_number
        clust_area = regionprops(superpixels_label == i, 'Area');
        sum_area = sum_area + sum([clust_area.Area]);
        cont_clust = cont_clust + 1;
    end
    mean_area = sum_area / cont_clust;
    
    aux_superpixels_label = superpixels_label;
    for i = 1:clust_number
        clust_area = regionprops(superpixels_label == i, 'Area');
        clust_area = [clust_area.Area];

        for j = 1:size(clust_area,2)
            if(clust_area(j) < (mean_area*5/100)) % 5% of the mean of the area of alla superpixels is considered
                lab = bwlabel(superpixels_label == i);
                indexes = lab == j;
                aux_superpixels_label(indexes) = -1;
            end 
        end
    end
    superpixels_label = aux_superpixels_label;
    
    % Eliminate not labeled pixels
    pixel_not_labeled = find(superpixels_label == -1);
    while(not(isempty(pixel_not_labeled)))
        for i=1:numel(pixel_not_labeled)
            [x,y] = ind2sub(size(superpixels_label), pixel_not_labeled(i));
            window = superpixels_label(clip(x-1,1,size(superpixels_label,1)):clip(x+1,1,size(superpixels_label,1)),...
                    clip(y-1,1,size(superpixels_label,2)):clip(y+1,1,size(superpixels_label,2)));

            element_list = unique(window);
            cont_list = zeros(numel(element_list),1);
            for j=1:numel(window)
                if(not(window(j) == -1))
                    cont_list(element_list == window(j)) = cont_list(element_list == window(j)) + 1;
                end
            end

            [~, max_ind] = max(cont_list);
            superpixels_label(x,y) = element_list(max_ind(1));
        end
        pixel_not_labeled = find(superpixels_label == -1);
    end
    
    % Compute new centers
    aux_image = reshape(image, [size(image,1)*size(image,2), size(image,3)]);
    new_cluster_centers = zeros([0, size(aux_image, 2)+2]);
    new_superpixels_label = zeros(size(superpixels_label));
    current_lab = 1;
    for i = 1:size(unique(superpixels_label))
        [current_sup, num_reg] = bwlabel(superpixels_label == i);
        for j = 1:num_reg
            cluster_indexes = find(current_sup == j);
            if(not(isempty(cluster_indexes)))
                [aux_indexes_1, aux_indexes_2] = ind2sub(size(superpixels_label), cluster_indexes);
                new_cluster_centers = cat(1, new_cluster_centers,...
                    mean(cat(2,aux_image(cluster_indexes,:), [aux_indexes_1, aux_indexes_2])));
                new_superpixels_label(cluster_indexes) = current_lab;
                current_lab = current_lab + 1;
            end
        end
    end
    cluster_centers = new_cluster_centers;
    superpixels_label = new_superpixels_label;
    
    cluster_centers = cat(2, cluster_centers(:,1:(end-2)/2), cluster_centers(:,end-1:end)/size(image,1)); % Coordinate are normalized by the dimension of the image
    superpixels_label = imresize(superpixels_label, original_size, 'nearest');
    
    fprintf('Segmentation end -----------------------------------------------\n');
    
end

%% Auxiliar functions

function y = clip(x,bl,bu)
    y=min(max(x,bl),bu);
end