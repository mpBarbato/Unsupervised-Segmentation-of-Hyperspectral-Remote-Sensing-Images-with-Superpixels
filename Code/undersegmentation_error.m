function error = undersegmentation_error(superpixels_label, gt, percentange, bg_value)
    
    % Do not consider background
    
    % Resize of the gt if necessary
    gt = imresize(gt, size(superpixels_label), 'nearest');

    classes = unique(gt);
    classes_sum = 0;

    for i=1:numel(classes)
        if(not(classes(i) == bg_value))
            superpixels_list = unique(superpixels_label(gt == classes(i)));

            superpixels_area = 0;            
            for j=1:numel(superpixels_list)
                current_superpixel_area = sum(sum(superpixels_label == superpixels_list(j)));
                current_superpixel_overlapping_area = sum(sum((gt == classes(i)) .* (superpixels_label == superpixels_list(j))));
                
                if(current_superpixel_overlapping_area*100/current_superpixel_area > percentange)
                    superpixels_area = superpixels_area + (sum(sum(superpixels_label == superpixels_list(j))));
                end
            end
            classes_sum = classes_sum + superpixels_area;
        end
    end
    
    error = (classes_sum-(numel(gt)-sum(sum(gt==bg_value))))/(numel(gt)-sum(sum(gt==bg_value)));
end
