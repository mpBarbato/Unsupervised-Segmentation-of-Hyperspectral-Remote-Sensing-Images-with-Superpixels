function [recall, precision, F1] = get_acc_measures(clust_lab, gt, bg_value)

indexes = find(not(gt==bg_value));
gt_list = gt(indexes);

pred_list = clust_lab;
lab = pred_list(indexes);

mat = zeros([max(lab), max(gt_list)]);

for class = 1:max(gt_list)
    class_indexes = find(gt_list == class);
    for cluster = 1:max(lab)
        clust_indexes = find(lab == cluster);
        values = intersect(clust_indexes, class_indexes);    
        mat(cluster, class) = size(values,1);
    end
end

precision = getPrecision(mat, max(lab));
recall = getRecall(mat, max(gt_list));
F1 = getF1(precision, recall);

end

function precision = getPrecision(mat, k)

total = 0;

for i = 1:k
   gold = max(mat(i,:));
   total = total + gold;
end

precision = total/sum(mat,'all');

end

function recall = getRecall(mat, s)

total = 0;

for i = 1:s
   gold = max(mat(:,i));
   total = total + gold;
end

recall = total/sum(mat,'all');

end

function F1 = getF1(precision, recall)

F1 = 2*((precision*recall)/(precision+recall));

end