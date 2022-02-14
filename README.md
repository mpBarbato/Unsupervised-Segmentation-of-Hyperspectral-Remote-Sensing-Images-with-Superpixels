# Unsupervised-Segmentation-of-Hyperspectral-Remote-Sensing-Images-with-Superpixels

The exploits an unsupervised region segmentation for hyperspectral remote sensing images without requiring further information like the number of segmentation classes or a-priori knowledge about the type of land-cover or land-use (e.g. water, vegetation, building etc...). It is divided in two steps:

1) Augmented Hyperspectral SLIC superpixels: a technique of superpixels segmentation that adapts the original SLIC to hyperspectral images and make use of Mean-shift algorithm to improve the segmentation
2) Unsupervised region segmentation: the segmentation of the regions in different classes using the original Hyperspectral information together with the superpixels information extracted in the first step.

# Datasets

The datasets used for the evaluation are Pavia Center, Pavia University, Salinas and SalinasA, that are avaible at http://www.ehu.eus/ccwintco/index.php/Hyperspectral_Remote_Sensing_Scenes.

# Superpixel Evaluation

The evaluation of the Superpixels segmentation makes use of the undersegmentation error.

# Unsupervised regions segmentation evaluation

The evaluation of the Unsupervised regions segmentation makes use of NMI (Normalized Mutual Information), ARI (Adjusted Rand Index) and F1 metrics.

# How to use

Insert the dataset in the Datasets folder. For each dataset, the hyperspectral image, the groud-truth and the value of the background in the ground-truth need to be furnished for the elaboration and evaluation of the datasets. Functions for Pavia Center, Pavia Univesity, Salinas and SalinasA loading are already avaiable. To use these functions the datasets and respective ground-truth need to be insert in the "Datasets" folder and respectively in another folder as follows:

Dataset --> Folder

Pavia Center --> Pavia

Pavia Center --> Pavia_university

Salinas --> Salinas

SalinasA --> Salinas

To start the method, select the right function to load the right dataset in the main and start the algorithm. Matlab needs to be opened from a environment with python installed due to the functionality of python that are used in the code.

# Contact

Email: m.barbato2@campus.unimib.it
