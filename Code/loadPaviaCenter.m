function [dataset_images, dataset_gt, bg_value] = loadPaviaCenter()
    
    bg_value = 0;
    dataset_images = cell(0);
    dataset_gt = cell(0);

    path_dataset = "..\Datasets\Pavia\";
    
    image = load(path_dataset + "Pavia.mat");
    image = image.pavia;

    % Normalization
    image = normalization(image,95);
    image = double(image)/max(double(image), [], 'all');
    dataset_images{1} = image;

    gt = load(path_dataset + "Pavia_gt.mat");
    gt = gt.pavia_gt;
    dataset_gt{1} = gt;
    
    %[dataset_images, dataset_gt] = preprocessing_data(dataset_images, dataset_gt)
    
end