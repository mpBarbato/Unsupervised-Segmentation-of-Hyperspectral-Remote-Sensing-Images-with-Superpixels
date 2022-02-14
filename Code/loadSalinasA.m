function [dataset_images, dataset_gt, bg_value] = loadSalinasA()
    
    bg_value = 0;
    dataset_images = cell(0);
    dataset_gt = cell(0);
    
    path_dataset = "..\Datasets\SalinasA\";
    
    image = load(path_dataset + "SalinasA_corrected.mat");
    image = image.salinasA_corrected;

    % Normalization
    image = normalization(image,95);
    image = double(image)/max(double(image), [], 'all');
    dataset_images{1} = image;

    gt = load(path_dataset + "SalinasA_gt.mat");
    gt = gt.salinasA_gt;
    dataset_gt{1} = gt;
end