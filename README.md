# Unsupervised-Segmentation-of-Hyperspectral-Remote-Sensing-Images-with-Superpixels

The method returns an unsupervised region segmentation for hyperspectral remote sensing images without requiring further information like the number of segmentation classes or a-priori knowledge about the type of land-cover or land-use (e.g. water, vegetation, building, etc...). It is divided into two steps:

1) Augmented Hyperspectral SLIC superpixels: a technique of superpixels segmentation that adapts the original SLIC to hyperspectral images and make use of the Mean-shift algorithm to improve the segmentation
2) Unsupervised region segmentation: the segmentation of the regions in different classes using the original Hyperspectral information together with the superpixels information extracted in the first step.

# Datasets

The datasets used for the evaluation are Pavia Center, Pavia University, Salinas, and SalinasA, which are available at http://www.ehu.eus/ccwintco/index.php/Hyperspectral_Remote_Sensing_Scenes.

# Superpixel Evaluation

The evaluation of the Superpixels segmentation makes use of the undersegmentation error.

# Unsupervised region segmentation evaluation

The evaluation of the Unsupervised region segmentation makes use of NMI (Normalized Mutual Information), ARI (Adjusted Rand Index) and F1 metrics.

# How to use

Insert the dataset in a "Datasets" folder. For each dataset, the hyperspectral image, the groud-truth, and the value of the background in the ground-truth need to be furnished for the elaboration and evaluation of the datasets. Functions for Pavia Center, Pavia Univesity, Salinas, and SalinasA loading are already available. To use these functions the datasets and respective ground-truth need to be inserted in the "Datasets" folder and respectively in another folder as follows:

Dataset --> Folder

Pavia Center --> Datasets/Pavia

Pavia Center --> Datasets/Pavia_university

Salinas --> Datasets/Salinas

SalinasA --> Datasets/Salinas

To start the method, select the right function to load the right dataset in the main and start the algorithm. Matlab needs to be opened from an environment with python installed due to the functionalities of python that are used in the code.

# Contacts

Email: m.barbato2@campus.unimib.it

# Citation
```text
@article{BARBATO2022100823,
title = {Unsupervised segmentation of hyperspectral remote sensing images with superpixels},
journal = {Remote Sensing Applications: Society and Environment},
volume = {28},
pages = {100823},
year = {2022},
issn = {2352-9385},
doi = {https://doi.org/10.1016/j.rsase.2022.100823},
url = {https://www.sciencedirect.com/science/article/pii/S2352938522001318},
author = {Mirko Paolo Barbato and Paolo Napoletano and Flavio Piccoli and Raimondo Schettini}
}
```
