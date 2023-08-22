% Copyright (c) 2023 Olivier Rukundo
% University Clinic of Dentistry, Medical University of Vienna, Vienna
% E-mail: olivier.rukundo@meduniwien.ac.at | orukundo@gmail.com
% Version 1.0  dated 21.08.2023

function [gray_image_8bits, barImageGT, bar_values, centroids_labels]  = cellevalufunction(gray_image_8bits)

    % Check if the bit depth is equal to 8, if not convert it to a grayscale image with bit depth = 8.
    bit_depth_per_channel = class(gray_image_8bits); 
    bit_depth_per_channel = str2double(bit_depth_per_channel(5:end));
    
    if bit_depth_per_channel ~= 8
        image_normalized = double(gray_image_8bits) / double(intmax(['uint', num2str(bit_depth_per_channel)]));
        gray_image_8bits = uint8(image_normalized * 255);
    end

    % Convert unconnected pixels to 0 gray value
    img_bin = gray_image_8bits > 0;
    cc = bwconncomp(img_bin);
    label_matrix = labelmatrix(cc);
    img_unconnected = gray_image_8bits;
    img_unconnected(label_matrix == 0) = 0;
    
    % Find groups or objects of connected pixels with values greater than 0 (background).
    [labels, num] = bwlabel(img_unconnected > 0);
    
    % Assign class to each object based on their majority class
    for i = 1:num
        object = labels == i;
        object_pixels = img_unconnected(object);
        
        class1_pixels = sum(object_pixels == 128);
        class2_pixels = sum(object_pixels == 255);
        
        if class2_pixels > class1_pixels
            labels(object) = 255;
        else
            labels(object) = 128;
        end
    end
        
    % Find connected components
    CC = bwconncomp(labels > 0); % assuming labels greater than 0 represent objects
    
    % Initialize the array to save the centroids and labels
    centroids_labels = zeros(CC.NumObjects, 3);
    for i = 1:CC.NumObjects
        % Get the pixel list for this object
        pixels = CC.PixelIdxList{i};
        
        % Calculate the centroid
        [rows, cols] = ind2sub(size(labels), pixels);
        centroids_labels(i,1:2) = [mean(cols), mean(rows)];
        
        % Get the label
        centroids_labels(i,3) = mode(gray_image_8bits(pixels));
    end

% Initialize blue and yellow counts
    gray_count = 0;
    white_count = 0;

% Modify the input image by drawing circles
    for i = 1:size(centroids_labels, 1)
        % x = centroids_labels(i, 1);
        % y = centroids_labels(i, 2);
        label = centroids_labels(i, 3);
    
        if label == 255
            white_count = white_count + 1;
        elseif label == 128
            gray_count = gray_count + 1;
        end
    end

    % Create bar chart
    fig = figure('Visible', 'off'); % Ensure it's not displayed
    bar_values = [gray_count, white_count];
    bars = bar(1:2, bar_values);
    
    if length(bars) == 1  % Only one handle returned
        set(bars, 'FaceColor', 'flat');
        set(bars, 'CData', [1 1 0; 0 0 1]); % Yellow for the first bar, Blue for the second
    else  % Individual handles for each bar group
        set(bars(1), 'FaceColor', 'yellow');
        set(bars(2), 'FaceColor', 'blue');
    end
    
    ylim([0 max(bar_values)+30]); % To ensure space for text labels
    text(1, gray_count + 2, [num2str(gray_count)], 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    text(2, white_count + 2, [num2str(white_count)], 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    
    % Convert the figure to an image
    frame = getframe(gca);
    barImageGT = frame2im(frame);
    
    % Close the figure without displaying
    close(fig); 
end

