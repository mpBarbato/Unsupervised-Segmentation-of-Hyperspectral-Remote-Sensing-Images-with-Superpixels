function out = normalization(image, perc)
    [counts, bins] = histcounts(image);
    cumulative_histogram = cumsum(counts);
    max_value_index = find(cumulative_histogram < floor((perc*cumulative_histogram(end))/100), 1, 'last');
    max_value = bins(max_value_index);
    out = double(image);
    out(out>max_value) = max_value;
    
    out = double(out)/max_value;
end