%%

clear variables
close all

%% Import python utility

py.importlib.import_module('python_utility');
rng(123);

%% Load dataset

% [dataset_images, dataset_gt, bg_value] = loadIndianPines();
% [dataset_images, dataset_gt, bg_value] = loadPaviaCenter();
% [dataset_images, dataset_gt, bg_value] = loadPaviaUniversity();
[dataset_images, dataset_gt, bg_value] = loadSalinas();
% [dataset_images, dataset_gt, bg_value] = loadSalinasA();

%% Superpixel segmetation

image = dataset_images{1};
gt = dataset_gt{1};

n_cluster = 800;
m = 0.4;
m_clust = 0.8;

[sp_labels, sp_centers] = augmented_h_slic(image,...
    n_cluster,...
    m,...
    m_clust,...
    bandwidth=NaN,...
    quantile=0.06,...
    perc=NaN,...
    threshold=0.01);

%% Evaluation of superpixel segmetation

percentange = 15;
UE = undersegmentation_error(sp_labels, gt, percentange, bg_value);

%% Unsupervised region segmentation

image = dataset_images{1};
gt = dataset_gt{1};
mask = not(gt == bg_value);

[clust_cent, clust_lab, image_centers] = unsupervised_segmentation(image,...
    sp_labels,...
    sp_centers,...
    mask,...
    bandwidth=NaN,...
    quantile=0.05,...
    perc_bandwidth=NaN,...
    PCA_mode=false,...
    perc_major=10);

%% Evaluation
gt = dataset_gt{1};

% NMI =====================================================================

NMI = getNMI(clust_lab, gt, bg_value);

% ARI =====================================================================

ARI = getARI(clust_lab, gt, bg_value);

% F1 score ================================================================

[REC, PREC, F1] = get_acc_measures(clust_lab, gt, bg_value);
