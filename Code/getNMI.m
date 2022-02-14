function NMI = getNMI(clust_lab, gt, bg_value)

    indexes = find(not(gt==bg_value));
    gt_list = gt(indexes);

    clust_lab = imresize(clust_lab, size(gt), 'nearest');
    pred_list = clust_lab;
    pred_list = pred_list(indexes);
    
    NMI = double(py.python_utility.getNMI(py.numpy.array(gt_list), py.numpy.array(reshape(pred_list, [prod(size(pred_list,1,2)), size(pred_list,3)]))));
end