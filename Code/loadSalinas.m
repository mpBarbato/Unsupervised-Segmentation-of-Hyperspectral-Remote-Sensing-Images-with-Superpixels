function [dataset_images, dataset_gt, bg_value] = loadSalinas()
    
    bg_value = 0;
    dataset_images = cell(0);
    dataset_gt = cell(0);
    
    path_dataset = "..\Datasets\Salinas\";
    
    image = load(path_dataset + "Salinas_corrected.mat");
    image = image.salinas_corrected;

    % Normalization
    image = normalization(image,95);
    image = double(image)/max(double(image), [], 'all');
    dataset_images{1} = image;

    gt = load(path_dataset + "Salinas_gt.mat");
    gt = gt.salinas_gt;
    dataset_gt{1} = gt;
end