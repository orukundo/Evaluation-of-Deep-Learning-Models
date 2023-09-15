% Copyright (c) 2023 Olivier Rukundo
% University Clinic of Dentistry, Medical University of Vienna, Vienna
% E-mail: olivier.rukundo@meduniwien.ac.at | orukundo@gmail.com
% Version 1.0  dated 21.08.2023


classdef dlevaluator < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        DLEVALUATORUIFigure             matlab.ui.Figure
        IMAGEMenu                       matlab.ui.container.Menu
        MASKMenu                        matlab.ui.container.Menu
        MODELMenu                       matlab.ui.container.Menu
        ListLoadedMasksListBox          matlab.ui.control.ListBox
        TabGroup                        matlab.ui.container.TabGroup
        DETECTIONTab                    matlab.ui.container.Tab
        ExportingDetectedCellsFilesPanel  matlab.ui.container.Panel
        ExportCSVButton                 matlab.ui.control.Button
        ExportImageButton               matlab.ui.control.Button
        DetectedCellsPanel              matlab.ui.container.Panel
        UIAxes                          matlab.ui.control.UIAxes
        NumberofDetectedCellsPanel      matlab.ui.container.Panel
        UIAxes2                         matlab.ui.control.UIAxes
        EVALUATIONTab                   matlab.ui.container.Tab
        GroundTruthImageOverlayImagePanel  matlab.ui.container.Panel
        UIAxes_2                        matlab.ui.control.UIAxes
        GenerateComparisonResultsPanel  matlab.ui.container.Panel
        ClearButton                     matlab.ui.control.Button
        CompareButton                   matlab.ui.control.Button
        GroundTruthCellsvsDetectedCellsPanel  matlab.ui.container.Panel
        UIAxes2_3                       matlab.ui.control.UIAxes
        NumberofGroundTruthCellsPanel   matlab.ui.container.Panel
        UIAxes2_2                       matlab.ui.control.UIAxes
        PREPROCESSINGTab                matlab.ui.container.Tab
        PatchFilteringPanel             matlab.ui.container.Panel
        FilterSizeEditField             matlab.ui.control.NumericEditField
        FilterSizeEditFieldLabel        matlab.ui.control.Label
        ThresholdEditField              matlab.ui.control.NumericEditField
        ThresholdEditFieldLabel         matlab.ui.control.Label
        FilterPatchesButton             matlab.ui.control.Button
        FilteredPatchFolderPathButton   matlab.ui.control.Button
        CreatePatcheswithSlidingWindowPanel  matlab.ui.container.Panel
        ResetButton                     matlab.ui.control.Button
        StopButton                      matlab.ui.control.Button
        CreatePatchesButton             matlab.ui.control.Button
        StepSizeEditField               matlab.ui.control.NumericEditField
        StepSizeEditFieldLabel          matlab.ui.control.Label
        WindowSizeEditField             matlab.ui.control.NumericEditField
        WindowSizeEditFieldLabel        matlab.ui.control.Label
        OutputFileFormatDropDown        matlab.ui.control.DropDown
        OutputFileFormatDropDownLabel   matlab.ui.control.Label
        InputFileFormatDropDown         matlab.ui.control.DropDown
        InputFileFormatDropDownLabel    matlab.ui.control.Label
        PatchFolderPathButton           matlab.ui.control.Button
        ImageFolderPathButton           matlab.ui.control.Button
        ListLoadedImagesListBox         matlab.ui.control.ListBox
    end

    properties (Access = private)
        selected_mask = [];            % Selected Ground truth image or mask
        output_color_image = [];       % Output color image after analysis
        centroids_labels_color = [];   % Detected centroids (Color Image)
        centroids_labels_gray = [];    % Detected centroids (Grayscale Image)
        net = [];                      % Loaded deep learning model
        ImageFolderPath char = '';     % Path to the folder containing images (initialize as empty)
        PatchFolderPath char = '';     % Path to the folder containing patches (initialize as empty)
        FilteredPatchFolderPath char = '';   % Path to the folder containing filtered patches (initialize as empty)
        TempPatchFolderPath = '';      % Temporary path for patches (initialize as empty)
        stopProcess = false;           % Flag to control processing
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: ListLoadedImagesListBox
        function ListLoadedImagesListBoxValueChanged(app, event)
            selectedImage = "";         %#ok   % Store the selected image name
            imageDir = "";              %#ok   % Store the image directory path
            input_color_image = [];     %#ok   % Input color image to be processed
            unetsegmented_image = [];   %#ok   % Result of semantic segmentation
            barImage = [];              %#ok   % Processed image with detected cells

            % Get the selected image name from the ListLoadedMasksListBox
            selectedImage = app.ListLoadedImagesListBox.Value;

            % Get the directory where the image is located from UserData
            imageDir = app.ListLoadedImagesListBox.UserData;

            % Read or load and display the selected image
            input_color_image = imread(fullfile(imageDir, selectedImage));

            % Perform semantic segmentation using the pre-trained U-Net model
            unetsegmented_image = semanticseg(input_color_image, app.net);

            % Call celldetectfunction to detect cells.
            [app.output_color_image, barImage, bar_values, app.centroids_labels_color] = celldetectfunction(input_color_image, unetsegmented_image);

            % Display the processed image on UIAxes
            imshow(app.output_color_image, 'Parent', app.UIAxes);

            % Add descriptive titles to the output image
            A = {'CELL 1', 'CELL 2'};
            imgHeight = round(0.125*size(barImage, 1));
            imgWidth = size(barImage, 2);
            fontSize = 24;

            % Create a blank image for writing
            textImg = uint8(255 * ones(imgHeight, imgWidth, 3));
            barWidth = imgWidth/length(bar_values);

            % Define positions manually
            positions = [
                0.5 * barWidth + barWidth/6;
                1.5 * barWidth - barWidth/6;
                ];

            % Insert text for each position
            textImg = insertText(textImg, [positions(1), imgHeight - fontSize], char(A(1)), 'FontSize', fontSize, 'BoxOpacity', 0, 'AnchorPoint', 'CenterBottom');
            textImg = insertText(textImg, [positions(2), imgHeight - fontSize], char(A(2)), 'FontSize', fontSize, 'BoxOpacity', 0, 'AnchorPoint', 'CenterBottom');

            % Combine the two images (bar image and text description)
            combinedImg = vertcat(barImage, textImg);

            % Display the combined image on UIAxes2 for visualization
            imshow(combinedImg, 'Parent', app.UIAxes2);

            % Adjust the UIAxes display properties for better visualization
            axis(app.UIAxes, 'image');
            axis(app.UIAxes, 'off');
        end

        % Menu selected function: IMAGEMenu
        function IMAGEMenuSelected(app, event)
            % Default directory
            defaultImgDir = '';

            % Check if the default directory exists
            if ~exist(defaultImgDir, 'dir')
                % Prompt the user for directory selection
                imageDir = uigetdir('', 'Select Image Folder');
            else
                imageDir = defaultImgDir;
            end

            % This will bring the UIFigure to the front.
            figure(app.DLEVALUATORUIFigure);

            if imageDir == 0
                % User cancelled folder selection
                return
            end

            % List of extensions
            extensions = {'.jpg', '.png', '.bmp', '.tif', '.tiff', '.jpeg'};

            % Initialize an empty array to store the imageFiles
            imageFiles = [];

            % Create a waitbar
            h = waitbar(0, 'LOADING IMAGES...', 'Name', 'Progress');

            % Get all image files in this directory
            for i = 1:length(extensions)
                tempFiles = dir(fullfile(imageDir, ['*', extensions{i}]));
                imageFiles = [imageFiles; tempFiles];  %#ok

                % Update the waitbar
                waitbar(i / length(extensions), h, sprintf('LOADING %s IMAGES...', extensions{i}));
            end

            % Update ListLoadedImagesListBox
            app.ListLoadedImagesListBox.Items = {imageFiles.name};

            % Store the image directory for later use
            app.ListLoadedImagesListBox.UserData = imageDir;

            % If the directory has images, set the value to the first image and call the value changed function
            if ~isempty(imageFiles)
                app.ListLoadedImagesListBox.Value = imageFiles(1).name;
                ListLoadedImagesListBoxValueChanged(app, []);
            end

            % Close the waitbar
            close(h);
        end

        % Menu selected function: MASKMenu
        function MASKMenuSelected(app, event)
            % Set the default directory path
            defaultMaskDir = '';

            % Check the existence of the default directory. If default directory doesn't exist, prompt user to select a directory
            if ~exist(defaultMaskDir, 'dir')
                maskDir = uigetdir('', 'Select Mask Folder');
            else
                maskDir = defaultMaskDir;
            end

            % Bring the UIFigure to the forefront
            figure(app.DLEVALUATORUIFigure);

            % Exit if user cancels the folder selection
            if maskDir == 0
                return
            end

            % Define the list of valid image extensions
            extensions = {'.jpg', '.png', '.bmp', '.tif', '.tiff', '.jpeg'};

            % Initialize array to hold image file details
            maskFiles = [];

            % Populate maskFiles with details of images present in the selected directory
            for i = 1:length(extensions)
                maskFiles = [maskFiles; dir(fullfile(maskDir, ['*', extensions{i}]))];  %#ok
            end

            % Update the ListBox with the names of the loaded mask images
            app.ListLoadedMasksListBox.Items = {maskFiles.name};

            % Store the directory path for later retrieval
            app.ListLoadedMasksListBox.UserData = maskDir;

            % If images are present, set the default selected image to the first one and trigger its value changed function
            if ~isempty(maskFiles)
                app.ListLoadedMasksListBox.Value = maskFiles(1).name;
                ListLoadedMasksListBoxValueChanged(app, []);
            end
        end

        % Value changed function: ListLoadedMasksListBox
        function ListLoadedMasksListBoxValueChanged(app, event)
            % Get the selected mask name from the ListLoadedMasksListBox
            selectedMask = app.ListLoadedMasksListBox.Value;

            % Get the directory where the mask is located from UserData
            maskDir = app.ListLoadedMasksListBox.UserData;

            % Load and display the selected mask
            ground_truth_mask = imread(fullfile(maskDir, selectedMask));

            % Update the app property with the loaded mask image
            app.selected_mask = ground_truth_mask;

            % Display the mask on UIAxes_2
            imshow(ground_truth_mask, 'Parent', app.UIAxes_2);

            % Call the testdetectfunction to detect cells
            [~, barImageGT, bar_values, app.centroids_labels_gray] = cellevalufunction(ground_truth_mask);

            % Add descriptive titles to the output image
            A = {'CELL 1', 'CELL 2'};
            imgHeight = round(0.125*size(barImageGT, 1));
            imgWidth = size(barImageGT, 2);
            fontSize = 24;

            % Create a blank canvas for text insertion
            textImg = uint8(255 * ones(imgHeight, imgWidth, 3));
            barWidth = imgWidth/length(bar_values);

            % Manually define positions for text insertion
            positions = [
                0.5 * barWidth + barWidth/6;
                1.5 * barWidth - barWidth/6;
                ];

            % Insert text for each position
            textImg = insertText(textImg, [positions(1), imgHeight - fontSize], char(A(1)), 'FontSize', fontSize, 'BoxOpacity', 0, 'AnchorPoint', 'CenterBottom');
            textImg = insertText(textImg, [positions(2), imgHeight - fontSize], char(A(2)), 'FontSize', fontSize, 'BoxOpacity', 0, 'AnchorPoint', 'CenterBottom');

            % Combine the two images (bar mask and text description)
            combinedImgGT = vertcat(barImageGT, textImg);

            % Display the combined image on UIAxes2_2
            imshow(combinedImgGT, 'Parent', app.UIAxes2_2);

            % Adjust the UIAxes_2 display properties for better visualization
            axis(app.UIAxes_2, 'image');
            axis(app.UIAxes_2, 'off');
        end

        % Button pushed function: CompareButton
        function CompareButtonPushed(app, event)
            % Check if both images are loaded. If not, display an error message.
            if isempty(app.selected_mask) || isempty(app.output_color_image)
                uialert(app.DLEVALUATORUIFigure, 'Please ensure both images are loaded before comparison.', 'Error');
                return;
            end

            % Display the difference between the ground truth and Unet segmented images on UIAxes_2
            imshowpair(app.selected_mask, app.output_color_image, 'falsecolor', 'Parent', app.UIAxes_2);

            % Extract centroids based on the pixel values (128 and 255) from Unet segmented masks (app.centroids_labels_color)
            rows_color_128 = app.centroids_labels_color(:,3) == 128;
            x_c_128 = app.centroids_labels_color(rows_color_128, 1);
            y_c_128 = app.centroids_labels_color(rows_color_128, 2);
            rows_color_255 = app.centroids_labels_color(:,3) == 255;
            x_c_255 = app.centroids_labels_color(rows_color_255, 1);
            y_c_255 = app.centroids_labels_color(rows_color_255, 2);

            % Ensure the gray image centroids array has enough columns before processing.
            if size(app.centroids_labels_gray, 2) >= 3
                % Extract centroids based on the pixel values (128 and 255) for gray images.
                rows_gray_128 = app.centroids_labels_gray(:,3) == 128;
                x_g_128 = app.centroids_labels_gray(rows_gray_128, 1);
                y_g_128 = app.centroids_labels_gray(rows_gray_128, 2);
                rows_gray_255 = app.centroids_labels_gray(:,3) == 255;
                x_g_255 = app.centroids_labels_gray(rows_gray_255, 1);
                y_g_255 = app.centroids_labels_gray(rows_gray_255, 2);

                %% Compare coordinates of color and gray images for 128 and 255 values
                % to calculate TP (True Positives), FP (False Positives), and FN (False Negatives).

                % Handling centroids with pixel value 128
                min_length_128 = min(length(x_c_128), length(x_g_128));
                TP_128 = 0; FP_128 = 0; FN_128 = 0;
                for i = 1:min_length_128
                    distance_128 = sqrt((x_c_128(i) - x_g_128(i))^2 + (y_c_128(i) - y_g_128(i))^2);
                    % If distance is within 15 pixels, consider as a match, else a mismatch.
                    if distance_128 <= 15
                        TP_128 = TP_128 + 1;
                    else
                        FP_128 = FP_128 + 1;
                    end
                end
                FN_128 = FN_128 + abs(length(x_c_128) - length(x_g_128));

                % Handling centroids with pixel value 255
                min_length_255 = min(length(x_c_255), length(x_g_255));
                TP_255 = 0; FP_255 = 0; FN_255 = 0;

                for i = 1:min_length_255
                    distance_255 = sqrt((x_c_255(i) - x_g_255(i))^2 + (y_c_255(i) - y_g_255(i))^2);
                    if distance_255 <= 15
                        TP_255 = TP_255 + 1;
                    else
                        FP_255 = FP_255 + 1;
                    end
                end
                FN_255 = FN_255 + abs(length(x_c_255) - length(x_g_255));

                %% Visualizing the comparison results using a bar chart
                % Each bar represents TP, FP, or FN for either 128 or 255 value.

                % Initialize the bar chart with custom positions and colors
                figure('Visible', 'off', 'Units', 'pixels', 'Position', [100, 100, 600, 400]); % Increased height
                bar_values = [TP_128, FP_128, FN_128, TP_255, FP_255, FN_255];
                bars = bar(1:6, bar_values);

                % Assign colors based on bar values.
                if length(bars) == 1
                    set(bars, 'FaceColor', 'flat');
                    set(bars, 'CData', [1 1 0; 1 1 0; 1 0 0; 0 0 1; 0 0 1; 1 0 0]); % Yellow for the first bar, Blue for the second, etc.
                else
                    set(bars(1), 'FaceColor', 'yellow');
                    set(bars(2), 'FaceColor', 'yellow');
                    set(bars(3), 'FaceColor', 'red');
                    set(bars(4), 'FaceColor', 'blue');
                    set(bars(5), 'FaceColor', 'blue');
                    set(bars(6), 'FaceColor', 'red');
                end
                ylim([0 max(bar_values) + 30]);

                for idx = 1:length(bar_values)
                    text(idx, bar_values(idx) + 2, [num2str(bar_values(idx))], 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
                end

                % Capture the chart and close the temporary figure
                frame = getframe(gca);
                CompBarImage = frame2im(frame);
                close;

                % Now, write the titles onto the image
                A = {'TP', 'FP', 'FN', 'TP', 'FP', 'FN'};
                imgHeight = round(0.125*size(CompBarImage, 1));
                imgWidth = size(CompBarImage, 2);
                fontSize = 24; % or whatever is suitable

                % Create a blank image for writing
                textImg = uint8(255 * ones(imgHeight, imgWidth, 3));
                barWidth = imgWidth/length(bar_values);

                % Define positions manually
                positions = [
                    0.5 * barWidth + barWidth/2;
                    1.5 * barWidth + barWidth/3;
                    2.5 * barWidth + barWidth/7;
                    3.5 * barWidth - barWidth/17;
                    4.5 * barWidth - barWidth/3.5;
                    5.5 * barWidth - barWidth/2.5
                    ];

                % Insert text for each position
                textImg = insertText(textImg, [positions(1), imgHeight - fontSize], char(A(1)), 'FontSize', fontSize, 'BoxOpacity', 0, 'AnchorPoint', 'CenterBottom');
                textImg = insertText(textImg, [positions(2), imgHeight - fontSize], char(A(2)), 'FontSize', fontSize, 'BoxOpacity', 0, 'AnchorPoint', 'CenterBottom');
                textImg = insertText(textImg, [positions(3), imgHeight - fontSize], char(A(3)), 'FontSize', fontSize, 'BoxOpacity', 0, 'AnchorPoint', 'CenterBottom');
                textImg = insertText(textImg, [positions(4), imgHeight - fontSize], char(A(4)), 'FontSize', fontSize, 'BoxOpacity', 0, 'AnchorPoint', 'CenterBottom');
                textImg = insertText(textImg, [positions(5), imgHeight - fontSize], char(A(5)), 'FontSize', fontSize, 'BoxOpacity', 0, 'AnchorPoint', 'CenterBottom');
                textImg = insertText(textImg, [positions(6), imgHeight - fontSize], char(A(6)), 'FontSize', fontSize, 'BoxOpacity', 0, 'AnchorPoint', 'CenterBottom');

                % Combine the two images(bar image and text description)
                combinedImg = vertcat(CompBarImage, textImg);

                % Display the ground truth mask on the specified UIaxes
                imshow(combinedImg, 'Parent', app.UIAxes2_3);
            else
                % If centroids_labels_gray does not contain the expected number of columns, log a warning.
                disp('Warning: centroids_labels_gray does not have 3 columns.');
            end
        end

        % Button pushed function: ClearButton
        function ClearButtonPushed(app, event)
            % Ensure that the required output image is loaded and available in the app
            % Show an alert if the output image isn't available
            if isempty(app.output_color_image)
                uialert(app.DLEVALUATORUIFigure, 'Output image is not available.', 'Error');
                return;
            end

            % Retrieve the selected mask name and its directory from the UI
            selectedMask = app.ListLoadedMasksListBox.Value;
            maskDir = app.ListLoadedMasksListBox.UserData;

            % Load the selected mask image
            ground_truth_mask = imread(fullfile(maskDir, selectedMask));

            % Display the ground truth mask on the specified UIaxes
            imshow(ground_truth_mask, 'Parent', app.UIAxes_2);

            % Create a temporary invisible figure for capturing the bar chart image
            % This is necessary because the bar chart may not be directly obtainable as an image
            figure('Visible', 'off');
            frame = getframe(gca);           % Capture the current axis' frame
            CompBarImage = frame2im(frame);  % Convert the frame to an image

            % Close the temporary invisible figure now that the bar chart image has been captured
            close;

            % Display the captured bar chart image on the designated axes
            imshow(CompBarImage, 'Parent', app.UIAxes2_3);

            % Adjust the display properties of UIAxes_2 for better visualization
            axis(app.UIAxes_2, 'image');   % Adjust the aspect ratio
            axis(app.UIAxes_2, 'off');     % Hide axis tick marks and labels.
        end

        % Button pushed function: ExportImageButton
        function ExportImageButtonPushed(app, event)
            % Prompt the user to select a directory
            folderName = uigetdir;

            if folderName == 0
                % User pressed cancel or closed the prompt
                return;
            end

            % Create a file path for the PNG image
            imagePath = fullfile(folderName, 'output_image.png');
            imwrite(app.output_color_image, imagePath);
            msgbox('IMAGE EXPORTED SUCCESSFULLY!', 'Success');
        end

        % Button pushed function: ExportCSVButton
        function ExportCSVButtonPushed(app, event)
            % Prompt the user to select a directory
            folderName = uigetdir;
            if folderName == 0
                % User pressed cancel or closed the prompt
                return;
            end

            % Convert the matrix to a table with column names
            T = array2table(round(app.centroids_labels_color), 'VariableNames', {'X', 'Y', 'Label'});

            % Create a file path for the CSV file
            csvPath = fullfile(folderName, 'centroids_data.csv');

            % Write the table to the CSV file using semicolon as delimiter
            writetable(T, csvPath, 'Delimiter', ';');
            msgbox('CSV EXPORTED SUCCESSFULLY!', 'Success');
        end

        % Menu selected function: MODELMenu
        function MODELMenuSelected(app, event)
            % Bring the UIFigure to the front
            figure(app.DLEVALUATORUIFigure);

            % This function loads a pre-trained model. It first checks a hardcoded path for the model.
            % If not found, it prompts the user to select a model file.
            modelPath = '';

            if ~exist(modelPath, 'file')
                [file, path] = uigetfile('*.mat', '');
                if isequal(file, 0)
                    error('User did not select a model file. Exiting...');
                else
                    modelPath = fullfile(path, file);
                end
            end

            loadedModel = load(modelPath);
            if isfield(loadedModel, 'net')
                app.net = loadedModel.net;

                % Display a message box to notify the user
                msgbox('MODEL LOADED SUCCESSFULLY!', 'Success', 'help');

            else
                error('The loaded .mat file does not contain a "net" variable.');
            end
        end

        % Button pushed function: CreatePatchesButton
        function CreatePatchesButtonPushed(app, event)
            % Initialize the progress bar with 0%
            progress = 0;   %#ok

            % Change button name to "Processing"
            app.CreatePatchesButton.Text = 'Processing... 0%';  % Initialize with 0% progress

            % Put text on top of icon
            app.CreatePatchesButton.IconAlignment = 'bottom';

            % Create waitbar with the same color as the button
            wbar = permute(repmat(app.CreatePatchesButton.BackgroundColor,15,1,400), [1,3,2]);

            % Black frame around waitbar
            wbar([1, end], :, :) = 0;
            wbar(:, [1, end], :) = 0;

            % Load the empty waitbar to the button
            app.CreatePatchesButton.Icon = wbar;

            % Force the GUI to update immediately,
            drawnow;

            % Retrieve values from UI components
            window_size = app.WindowSizeEditField.Value;

            % Ensure window_size has a valid value and perform the patch creation
            if isempty(window_size) || window_size <= 0
                msgbox('Please enter a valid window size.');
                return;  % Exit the function if window size is invalid
            end

            % Retrieve values from UI components
            step_size = app.StepSizeEditField.Value;

            % Ensure step_size has a valid value and perform the patch creation
            if isempty(step_size) || step_size <= 0
                msgbox('Please enter a valid step size.');
                return;  % Exit the function if step size is invalid
            end

            % Get the selected input file format from the dropdown menu
            input_format = app.InputFileFormatDropDown.Value;

            % Get the selected output file format from the dropdown menu
            output_format = app.OutputFileFormatDropDown.Value;

            % Check if image and patch folders are selected
            if isempty(app.ImageFolderPath) || isempty(app.PatchFolderPath)
                msgbox('Please select both the image folder and patch folder.');
                return;  % Exit the function if folders are not selected
            end

            % Check if the folderPath is empty
            if ~isempty(dir(fullfile(app.PatchFolderPath, ['*.' output_format])))
                % Display a warning message and stop the script
                warning_msg = 'The Patch Folder Is Not Empty. Please Empty It Before Starting Again.';
                warndlg(warning_msg, 'Patch Folder Is Not Empty');
                return; % Terminate the script
            end

            % Check for valid window_size and step_size
            if window_size <= 0
                fprintf('Error: Window size must be greater than 0. Exiting the script.\n');
                return;
            end

            if step_size <= 0
                fprintf('Error: Step size must be greater than 0. Exiting the script.\n');
                return;
            end

            if step_size > window_size
                fprintf('Error: Step size must be less than or equal to window size. Exiting the script.\n');
                return;
            end

            % Get the list of image files in the image folder with the input format
            image_files = dir(fullfile(app.ImageFolderPath, ['*.' input_format]));


            % Check if there are any image files in the specified input format
            if isempty(image_files)
                fprintf('No image files with the specified input format found in the selected image folder. Exiting the script.\n');
                return;
            end

            % Calculate total number of patches to save
            total_patches = 0;
            for i = 1:numel(image_files)
                [rows, cols, ~] = size(imread(fullfile(app.ImageFolderPath, image_files(i).name)));
                total_patches = total_patches + ((rows - window_size + 1) / step_size) * ((cols - window_size + 1) / step_size);
            end

            % Loop through the images in the image folder
            for m = 1:numel(image_files)

                % Check if the process should be stopped
                if app.stopProcess
                    break;  % Exit the loop if the user wants to stop
                end

                % Load the current image in the input format
                current_image = imread(fullfile(app.ImageFolderPath, image_files(m).name));

                % Get the dimensions of the current image
                [rows, cols, ~] = size(current_image);

                % Initialize the patch counter for the current image
                patch_counter = 0;

                % Loop through the current image using a sliding window
                for r = 1 : step_size : rows - window_size + 1
                    for c = 1 : step_size : cols - window_size + 1

                        % Extract the current patch
                        current_image_patch = current_image(r : r + window_size - 1, c : c + window_size - 1, :);

                        % Increment the patch counter for the current image
                        patch_counter = patch_counter + 1;

                        % Save the current patch in the output patch format
                        imwrite(current_image_patch, fullfile(app.PatchFolderPath, sprintf('%s_%d.%s', image_files(m).name, patch_counter, output_format)));

                        % Update the progress bar
                        progress = (m - 1 + (patch_counter / total_patches)) / numel(image_files);

                        % Update image data (royalblue)
                        currentProg = min(round((size(wbar, 2) - 2) * (progress)), size(wbar, 2) - 2);
                        RGB = app.CreatePatchesButton.Icon;
                        RGB(2:end-1, 2:currentProg+1, 1) = 0.25391; 
                        RGB(2:end-1, 2:currentProg+1, 2) = 0.41016;
                        RGB(2:end-1, 2:currentProg+1, 3) = 0.87891;
                        app.CreatePatchesButton.Icon = RGB;

                        % Update button text to display progress percentage
                        app.CreatePatchesButton.Text = sprintf('Processing... %.2f%%', progress * 100);

                        % Add a drawnow call to update the GUI
                        drawnow;

                        % Delay for a short time to smooth updates
                        pause(0.01);
                    end
                end
            end

            % Reset the global variable
            app.stopProcess = false;

            % Remove waitbar
            app.CreatePatchesButton.Icon = '';

            % Change button name back to "Create Patches"
            app.CreatePatchesButton.Text = 'Create Patches';
        end

        % Button pushed function: ImageFolderPathButton
        function ImageFolderPathButtonPushed(app, event)
            % Bring the UIFigure to the front
            figure(app.DLEVALUATORUIFigure);
            
            % Prompt the user to select the image folder
            image_folder = uigetdir('', 'Select Image Folder');

            % Check if the user canceled the folder selection
            if image_folder == 0
                app.ImageFolderPathButton.Text = ''; % Set text to empty if canceled
            else
                app.ImageFolderPathButton.Text = image_folder;
            end

            % Store the selected folder path as a string
            app.ImageFolderPath = image_folder;
        end

        % Button pushed function: PatchFolderPathButton
        function PatchFolderPathButtonPushed(app, event)
            % Bring the UIFigure to the front
            figure(app.DLEVALUATORUIFigure);

            % Prompt the user to select the patch folder
            patch_folder = uigetdir('', 'Select Patch Folder');

            % Check if the user canceled the folder selection
            if patch_folder == 0
                app.PatchFolderPathButton.Text = ''; % Set text to empty if canceled
            else
                app.PatchFolderPathButton.Text = patch_folder;

                % Store the selected folder path in the temporary property
                app.TempPatchFolderPath = patch_folder;
            end

            % Store the selected folder path as a string
            app.PatchFolderPath = patch_folder;
        end

        % Button pushed function: FilteredPatchFolderPathButton
        function FilteredPatchFolderPathButtonPushed(app, event)
            % Bring the UIFigure to the front
            figure(app.DLEVALUATORUIFigure);

            % Prompt the user to select the patch folder
            filtered_patch_folder = uigetdir('', 'Select Filtered Patch Folder');

            % Check if the user canceled the folder selection
            if filtered_patch_folder == 0
                app.FilteredPatchFolderPathButton.Text = ''; % Set text to empty if canceled
            else
                app.FilteredPatchFolderPathButton.Text = filtered_patch_folder;
            end

            % Store the selected folder path as a string
            app.FilteredPatchFolderPath = filtered_patch_folder;
        end

        % Button pushed function: FilterPatchesButton
        function FilterPatchesButtonPushed(app, event)
            % Initialize
            filtered_patch_folder = app.FilteredPatchFolderPath;
            input_format = app.InputFileFormatDropDown.Value;
            output_format = app.OutputFileFormatDropDown.Value;

            % Initialize the progress bar with 0%
            filtering_progress = 0;   %#ok

            % Change button name to "Processing"
            app.FilterPatchesButton.Text = 'Processing... 0%';  % Initialize with 0% progress

            % Put text on top of icon
            app.FilterPatchesButton.IconAlignment = 'bottom';

            % Create waitbar with the same color as the button
            wbar = permute(repmat(app.FilterPatchesButton.BackgroundColor,15,1,400), [1,3,2]);

            % Black frame around waitbar
            wbar([1, end], :, :) = 0;
            wbar(:, [1, end], :) = 0;

            % Load the empty waitbar to the button
            app.FilterPatchesButton.Icon = wbar;

            % Force the GUI to update immediately,
            drawnow;

            % Retrieve values from UI components
            filter_size = app.FilterSizeEditField.Value;

            % Ensure filter_size has a valid value and perform the patch filtering
            if isempty(filter_size) || filter_size < 0
                msgbox('Please enter a valid Filter size.');
                return;  % Exit the function if filter size is invalid
            end

            % Retrieve values from UI components
            threshold_value = app.ThresholdEditField.Value;

            % Ensure threshold is a valid value and perform the patch filtering
            if isempty(threshold_value) || threshold_value < 0
                msgbox('Please enter a valid threshold value.');
                return;  % Exit the function if threshold is invalid
            end

            % Check if filtered patch folder is selected
            if isempty(app.FilteredPatchFolderPath)
                msgbox('Please select filtered patch folder.');
                return;  % Exit the function if folders are not selected
            end

            % Check if the filtered patch folder is empty
            if ~isempty(dir(fullfile(app.FilteredPatchFolderPath, ['*.' output_format])))
                % Display a warning message and stop the script
                warning_msg = 'The Filtered Patch Folder Is Not Empty. Please Empty It Before Starting Again.';
                warndlg(warning_msg, 'Filtered Patch Folder Is Not Empty');
                return; % Terminate the script
            end

            % Check for valid window_size and step_size
            if filter_size < 0
                fprintf('Error: Filter size must be greater than 0. Exiting the script.\n');
                return;
            end

            if threshold_value < 0
                fprintf('Error: Threshold value must be greater than 0. Exiting the script.\n');
                return;
            end

            % Calculate total number of patches to filter
            patchFile_list = dir(fullfile(app.PatchFolderPath, ['*.' output_format]));
            filtering_total_patches = numel(patchFile_list);

            % Check if the temporary path property is empty
            if ~isempty(app.TempPatchFolderPath)
                % Use the temporary path in your code
                % input_format = 'your_input_format'; % Define your input format
                image_patch_files = dir(fullfile(app.TempPatchFolderPath, ['*.' input_format]));

                % Loop through each image patch file
                for i = 1:numel(image_patch_files)

                    % Initialize the patch counter for the current image
                    filtering_patch_counter = 0;

                    % Read the current image patch
                    current_image_patch = imread(fullfile(app.PatchFolderPath, image_patch_files(i).name));

                    % Convert the color image to grayscale
                    gray_image_patch = rgb2gray(current_image_patch);

                    % Define a threshold value
                    threshold = threshold_value; % Adjust this value as needed

                    % Create a binary image using the threshold
                    binary_image_patch = gray_image_patch > threshold;

                    % Create a binary image using the threshold
                    inv_binary_image_patch = imcomplement(binary_image_patch);

                    % Check if inv_binary_image_patch meets the threshold condition
                    if sum(inv_binary_image_patch(:)) > (filter_size * filter_size)
                        % Generate an output file name based on the input file name
                        [~, base_filename, ~] = fileparts(image_patch_files(i).name);
                        output_filename = sprintf('%s_%d.%s', base_filename, i, output_format);

                        % Increment the patch counter for the current image
                        filtering_patch_counter = filtering_patch_counter + 1;

                        % Save the current patch in the filtered_patch_folder
                        imwrite(current_image_patch, fullfile(filtered_patch_folder, output_filename));

                        % Update the progress bar
                        filtering_progress = (i - 1 + (filtering_patch_counter/filtering_total_patches))/numel(image_patch_files);

                        % Update image data (royalblue)
                        currentProg = min(round((size(wbar, 2) - 2) * (filtering_progress)), size(wbar, 2) - 2);
                        RGB = app.FilterPatchesButton.Icon;
                        RGB(2:end-1, 2:currentProg+1, 1) = 0.25391; % (royalblue)
                        RGB(2:end-1, 2:currentProg+1, 2) = 0.41016;
                        RGB(2:end-1, 2:currentProg+1, 3) = 0.87891;
                        app.FilterPatchesButton.Icon = RGB;

                        % Update button text to display progress percentage
                        app.FilterPatchesButton.Text = sprintf('Processing... %.2f%%', filtering_progress * 100);

                        % Add a drawnow call to update the GUI
                        drawnow;

                        % Delay for a short time to smooth updates
                        pause(0.01);

                    end

                end
            else
                % Handle the case where the path is not set
                disp('Patch folder path is not set.');
            end

            % Remove waitbar
            app.FilterPatchesButton.Icon = '';

            % Change button name back to "Create Patches"
            app.FilterPatchesButton.Text = 'Filter Patches';
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            % Set window size and step size and kernel size and threshold to zero
            app.WindowSizeEditField.Value = 0;
            app.StepSizeEditField.Value = 0;
            app.FilterSizeEditField.Value = 0;
            app.ThresholdEditField.Value = 0;
            % Clear selected paths
            app.ImageFolderPathButton.Text = 'Image Folder Path';
            app.PatchFolderPathButton.Text = 'Patch Folder Path';
            app.FilteredPatchFolderPathButton.Text = 'Filtered Patch Folder Path';
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            % global stopProcess;
            app.stopProcess = true;  % Set the flag to stop the process
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create DLEVALUATORUIFigure and hide until all components are created
            app.DLEVALUATORUIFigure = uifigure('Visible', 'off');
            app.DLEVALUATORUIFigure.Color = [0.149 0.149 0.149];
            app.DLEVALUATORUIFigure.Position = [100 100 1525 1031];
            app.DLEVALUATORUIFigure.Name = 'DL-EVALUATOR';
            app.DLEVALUATORUIFigure.Icon = fullfile(pathToMLAPP, 'MainIcon.png');

            % Create IMAGEMenu
            app.IMAGEMenu = uimenu(app.DLEVALUATORUIFigure);
            app.IMAGEMenu.MenuSelectedFcn = createCallbackFcn(app, @IMAGEMenuSelected, true);
            app.IMAGEMenu.Text = '             IMAGE           ';

            % Create MASKMenu
            app.MASKMenu = uimenu(app.DLEVALUATORUIFigure);
            app.MASKMenu.MenuSelectedFcn = createCallbackFcn(app, @MASKMenuSelected, true);
            app.MASKMenu.Text = '             MASK            ';

            % Create MODELMenu
            app.MODELMenu = uimenu(app.DLEVALUATORUIFigure);
            app.MODELMenu.MenuSelectedFcn = createCallbackFcn(app, @MODELMenuSelected, true);
            app.MODELMenu.Text = '          MODEL       ';

            % Create ListLoadedImagesListBox
            app.ListLoadedImagesListBox = uilistbox(app.DLEVALUATORUIFigure);
            app.ListLoadedImagesListBox.ValueChangedFcn = createCallbackFcn(app, @ListLoadedImagesListBoxValueChanged, true);
            app.ListLoadedImagesListBox.Position = [9 21 113 1003];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.DLEVALUATORUIFigure);
            app.TabGroup.Position = [253 21 1263 1003];

            % Create DETECTIONTab
            app.DETECTIONTab = uitab(app.TabGroup);
            app.DETECTIONTab.Title = 'DETECTION';

            % Create NumberofDetectedCellsPanel
            app.NumberofDetectedCellsPanel = uipanel(app.DETECTIONTab);
            app.NumberofDetectedCellsPanel.TitlePosition = 'centertop';
            app.NumberofDetectedCellsPanel.Title = 'Number of Detected Cells';
            app.NumberofDetectedCellsPanel.FontWeight = 'bold';
            app.NumberofDetectedCellsPanel.Position = [927 594 328 376];

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.NumberofDetectedCellsPanel);
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.XTick = [0 0.2 0.4 0.6 0.8 1];
            app.UIAxes2.XTickLabel = {'0'; '0.2'; '0.4'; '0.6'; '0.8'; '1'};
            app.UIAxes2.Position = [20 12 290 326];

            % Create DetectedCellsPanel
            app.DetectedCellsPanel = uipanel(app.DETECTIONTab);
            app.DetectedCellsPanel.TitlePosition = 'centertop';
            app.DetectedCellsPanel.Title = 'Detected Cells';
            app.DetectedCellsPanel.FontWeight = 'bold';
            app.DetectedCellsPanel.Position = [10 12 908 958];

            % Create UIAxes
            app.UIAxes = uiaxes(app.DetectedCellsPanel);
            app.UIAxes.XColor = [0 0.4471 0.7412];
            app.UIAxes.XTick = [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.UIAxes.YColor = [0 0.4471 0.7412];
            app.UIAxes.Position = [20 9 876 920];

            % Create ExportingDetectedCellsFilesPanel
            app.ExportingDetectedCellsFilesPanel = uipanel(app.DETECTIONTab);
            app.ExportingDetectedCellsFilesPanel.TitlePosition = 'centertop';
            app.ExportingDetectedCellsFilesPanel.Title = 'Exporting Detected Cells Files';
            app.ExportingDetectedCellsFilesPanel.FontWeight = 'bold';
            app.ExportingDetectedCellsFilesPanel.Position = [929 452 327 124];

            % Create ExportImageButton
            app.ExportImageButton = uibutton(app.ExportingDetectedCellsFilesPanel, 'push');
            app.ExportImageButton.ButtonPushedFcn = createCallbackFcn(app, @ExportImageButtonPushed, true);
            app.ExportImageButton.Position = [8 34 150 30];
            app.ExportImageButton.Text = 'Export Image';

            % Create ExportCSVButton
            app.ExportCSVButton = uibutton(app.ExportingDetectedCellsFilesPanel, 'push');
            app.ExportCSVButton.ButtonPushedFcn = createCallbackFcn(app, @ExportCSVButtonPushed, true);
            app.ExportCSVButton.Position = [169 34 150 30];
            app.ExportCSVButton.Text = 'Export CSV';

            % Create EVALUATIONTab
            app.EVALUATIONTab = uitab(app.TabGroup);
            app.EVALUATIONTab.Title = ' EVALUATION';

            % Create NumberofGroundTruthCellsPanel
            app.NumberofGroundTruthCellsPanel = uipanel(app.EVALUATIONTab);
            app.NumberofGroundTruthCellsPanel.TitlePosition = 'centertop';
            app.NumberofGroundTruthCellsPanel.Title = 'Number of Ground Truth Cells';
            app.NumberofGroundTruthCellsPanel.FontWeight = 'bold';
            app.NumberofGroundTruthCellsPanel.Position = [917 575 338 388];

            % Create UIAxes2_2
            app.UIAxes2_2 = uiaxes(app.NumberofGroundTruthCellsPanel);
            zlabel(app.UIAxes2_2, 'Z')
            app.UIAxes2_2.Position = [12 19 309 335];

            % Create GroundTruthCellsvsDetectedCellsPanel
            app.GroundTruthCellsvsDetectedCellsPanel = uipanel(app.EVALUATIONTab);
            app.GroundTruthCellsvsDetectedCellsPanel.TitlePosition = 'centertop';
            app.GroundTruthCellsvsDetectedCellsPanel.Title = 'Ground Truth Cells vs Detected Cells';
            app.GroundTruthCellsvsDetectedCellsPanel.FontWeight = 'bold';
            app.GroundTruthCellsvsDetectedCellsPanel.Position = [919 188 337 363];

            % Create UIAxes2_3
            app.UIAxes2_3 = uiaxes(app.GroundTruthCellsvsDetectedCellsPanel);
            zlabel(app.UIAxes2_3, 'Z')
            app.UIAxes2_3.Position = [10 17 318 311];

            % Create GenerateComparisonResultsPanel
            app.GenerateComparisonResultsPanel = uipanel(app.EVALUATIONTab);
            app.GenerateComparisonResultsPanel.TitlePosition = 'centertop';
            app.GenerateComparisonResultsPanel.Title = 'Generate Comparison Results';
            app.GenerateComparisonResultsPanel.FontWeight = 'bold';
            app.GenerateComparisonResultsPanel.Position = [920 21 336 142];

            % Create CompareButton
            app.CompareButton = uibutton(app.GenerateComparisonResultsPanel, 'push');
            app.CompareButton.ButtonPushedFcn = createCallbackFcn(app, @CompareButtonPushed, true);
            app.CompareButton.Position = [10 44 150 30];
            app.CompareButton.Text = 'Compare';

            % Create ClearButton
            app.ClearButton = uibutton(app.GenerateComparisonResultsPanel, 'push');
            app.ClearButton.ButtonPushedFcn = createCallbackFcn(app, @ClearButtonPushed, true);
            app.ClearButton.Position = [178 44 150 30];
            app.ClearButton.Text = 'Clear';

            % Create GroundTruthImageOverlayImagePanel
            app.GroundTruthImageOverlayImagePanel = uipanel(app.EVALUATIONTab);
            app.GroundTruthImageOverlayImagePanel.TitlePosition = 'centertop';
            app.GroundTruthImageOverlayImagePanel.Title = 'Ground Truth Image / Overlay Image';
            app.GroundTruthImageOverlayImagePanel.FontWeight = 'bold';
            app.GroundTruthImageOverlayImagePanel.Position = [10 12 885 951];

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.GroundTruthImageOverlayImagePanel);
            app.UIAxes_2.XColor = [0 0.4471 0.7412];
            app.UIAxes_2.XTick = [0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1];
            app.UIAxes_2.YColor = [0 0.4471 0.7412];
            app.UIAxes_2.Position = [8 9 856 908];

            % Create PREPROCESSINGTab
            app.PREPROCESSINGTab = uitab(app.TabGroup);
            app.PREPROCESSINGTab.Title = 'PREPROCESSING';

            % Create CreatePatcheswithSlidingWindowPanel
            app.CreatePatcheswithSlidingWindowPanel = uipanel(app.PREPROCESSINGTab);
            app.CreatePatcheswithSlidingWindowPanel.TitlePosition = 'centertop';
            app.CreatePatcheswithSlidingWindowPanel.Title = 'Create Patches with Sliding Window';
            app.CreatePatcheswithSlidingWindowPanel.FontWeight = 'bold';
            app.CreatePatcheswithSlidingWindowPanel.Position = [18 699 1212 264];

            % Create ImageFolderPathButton
            app.ImageFolderPathButton = uibutton(app.CreatePatcheswithSlidingWindowPanel, 'push');
            app.ImageFolderPathButton.ButtonPushedFcn = createCallbackFcn(app, @ImageFolderPathButtonPushed, true);
            app.ImageFolderPathButton.Position = [20 165 600 60];
            app.ImageFolderPathButton.Text = 'Image Folder Path';

            % Create PatchFolderPathButton
            app.PatchFolderPathButton = uibutton(app.CreatePatcheswithSlidingWindowPanel, 'push');
            app.PatchFolderPathButton.ButtonPushedFcn = createCallbackFcn(app, @PatchFolderPathButtonPushed, true);
            app.PatchFolderPathButton.Position = [20 90 600 60];
            app.PatchFolderPathButton.Text = 'Patch Folder Path';

            % Create InputFileFormatDropDownLabel
            app.InputFileFormatDropDownLabel = uilabel(app.CreatePatcheswithSlidingWindowPanel);
            app.InputFileFormatDropDownLabel.HorizontalAlignment = 'right';
            app.InputFileFormatDropDownLabel.Position = [700 178 96 30];
            app.InputFileFormatDropDownLabel.Text = 'Input File Format';

            % Create InputFileFormatDropDown
            app.InputFileFormatDropDown = uidropdown(app.CreatePatcheswithSlidingWindowPanel);
            app.InputFileFormatDropDown.Items = {'png', 'jpg', 'tiff', 'bmp'};
            app.InputFileFormatDropDown.Position = [811 178 100 30];
            app.InputFileFormatDropDown.Value = 'png';

            % Create OutputFileFormatDropDownLabel
            app.OutputFileFormatDropDownLabel = uilabel(app.CreatePatcheswithSlidingWindowPanel);
            app.OutputFileFormatDropDownLabel.HorizontalAlignment = 'right';
            app.OutputFileFormatDropDownLabel.Position = [691 105 105 30];
            app.OutputFileFormatDropDownLabel.Text = 'Output File Format';

            % Create OutputFileFormatDropDown
            app.OutputFileFormatDropDown = uidropdown(app.CreatePatcheswithSlidingWindowPanel);
            app.OutputFileFormatDropDown.Items = {'png', 'jpg', 'tiff', 'bmp'};
            app.OutputFileFormatDropDown.Position = [811 105 100 30];
            app.OutputFileFormatDropDown.Value = 'png';

            % Create WindowSizeEditFieldLabel
            app.WindowSizeEditFieldLabel = uilabel(app.CreatePatcheswithSlidingWindowPanel);
            app.WindowSizeEditFieldLabel.HorizontalAlignment = 'right';
            app.WindowSizeEditFieldLabel.Position = [919 178 87 30];
            app.WindowSizeEditFieldLabel.Text = 'Window Size';

            % Create WindowSizeEditField
            app.WindowSizeEditField = uieditfield(app.CreatePatcheswithSlidingWindowPanel, 'numeric');
            app.WindowSizeEditField.Position = [1019 178 150 30];

            % Create StepSizeEditFieldLabel
            app.StepSizeEditFieldLabel = uilabel(app.CreatePatcheswithSlidingWindowPanel);
            app.StepSizeEditFieldLabel.HorizontalAlignment = 'right';
            app.StepSizeEditFieldLabel.Position = [948 105 59 30];
            app.StepSizeEditFieldLabel.Text = 'Step Size';

            % Create StepSizeEditField
            app.StepSizeEditField = uieditfield(app.CreatePatcheswithSlidingWindowPanel, 'numeric');
            app.StepSizeEditField.Position = [1019 105 150 30];

            % Create CreatePatchesButton
            app.CreatePatchesButton = uibutton(app.CreatePatcheswithSlidingWindowPanel, 'push');
            app.CreatePatchesButton.ButtonPushedFcn = createCallbackFcn(app, @CreatePatchesButtonPushed, true);
            app.CreatePatchesButton.FontWeight = 'bold';
            app.CreatePatchesButton.Position = [21 17 600 60];
            app.CreatePatchesButton.Text = 'Create Patches';

            % Create StopButton
            app.StopButton = uibutton(app.CreatePatcheswithSlidingWindowPanel, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Position = [692 32 218 30];
            app.StopButton.Text = 'Stop';

            % Create ResetButton
            app.ResetButton = uibutton(app.CreatePatcheswithSlidingWindowPanel, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Position = [948 32 222 30];
            app.ResetButton.Text = 'Reset';

            % Create PatchFilteringPanel
            app.PatchFilteringPanel = uipanel(app.PREPROCESSINGTab);
            app.PatchFilteringPanel.TitlePosition = 'centertop';
            app.PatchFilteringPanel.Title = 'Patch Filtering';
            app.PatchFilteringPanel.FontWeight = 'bold';
            app.PatchFilteringPanel.Position = [19 575 1211 110];

            % Create FilteredPatchFolderPathButton
            app.FilteredPatchFolderPathButton = uibutton(app.PatchFilteringPanel, 'push');
            app.FilteredPatchFolderPathButton.ButtonPushedFcn = createCallbackFcn(app, @FilteredPatchFolderPathButtonPushed, true);
            app.FilteredPatchFolderPathButton.Position = [22 16 450 60];
            app.FilteredPatchFolderPathButton.Text = 'Filtered Patch Folder Path';

            % Create FilterPatchesButton
            app.FilterPatchesButton = uibutton(app.PatchFilteringPanel, 'push');
            app.FilterPatchesButton.ButtonPushedFcn = createCallbackFcn(app, @FilterPatchesButtonPushed, true);
            app.FilterPatchesButton.FontWeight = 'bold';
            app.FilterPatchesButton.Position = [499 16 450 60];
            app.FilterPatchesButton.Text = 'Filter Patches';

            % Create ThresholdEditFieldLabel
            app.ThresholdEditFieldLabel = uilabel(app.PatchFilteringPanel);
            app.ThresholdEditFieldLabel.HorizontalAlignment = 'center';
            app.ThresholdEditFieldLabel.Position = [1087 31 70 30];
            app.ThresholdEditFieldLabel.Text = 'Threshold';

            % Create ThresholdEditField
            app.ThresholdEditField = uieditfield(app.PatchFilteringPanel, 'numeric');
            app.ThresholdEditField.Position = [1159 31 40 30];

            % Create FilterSizeEditFieldLabel
            app.FilterSizeEditFieldLabel = uilabel(app.PatchFilteringPanel);
            app.FilterSizeEditFieldLabel.HorizontalAlignment = 'center';
            app.FilterSizeEditFieldLabel.Position = [966 31 70 30];
            app.FilterSizeEditFieldLabel.Text = 'Filter Size';

            % Create FilterSizeEditField
            app.FilterSizeEditField = uieditfield(app.PatchFilteringPanel, 'numeric');
            app.FilterSizeEditField.Position = [1039 31 40 30];

            % Create ListLoadedMasksListBox
            app.ListLoadedMasksListBox = uilistbox(app.DLEVALUATORUIFigure);
            app.ListLoadedMasksListBox.ValueChangedFcn = createCallbackFcn(app, @ListLoadedMasksListBoxValueChanged, true);
            app.ListLoadedMasksListBox.Position = [129 21 113 1003];

            % Show the figure after all components are created
            app.DLEVALUATORUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = dlevaluator

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.DLEVALUATORUIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.DLEVALUATORUIFigure)
        end
    end
end