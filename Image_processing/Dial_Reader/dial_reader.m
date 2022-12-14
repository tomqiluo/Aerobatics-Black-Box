% Dial Reader
% EC463
% Max Bakalos
% 11/15/2022

%{
DIAL READER: CIRCLE DETECTION

Downsampling
*   Gaussian blur (remove high frequencies) to prevent aliasing
*   Downsample image

Bilateral Filtering
*   Smooth continuous regions of image but preserve edges

Edge Detection
*   Convert image from RGB → grayscale
*   Use gradient approximation to detect edges
*   Widen the detected edge lines
    -   Detect white pixels in a neighborhood around a selected pixel
    -   If white pixel detected: turn selected pixel white
*   Invert the image (helps detect circles)

Find Circles
*   Use circular Hough transform to detect circles within a given radius range
%}

clear; close all;

tic % timer start


% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% Input Parameters

% Downsampling Toggle (1 -> On, 0 -> Off)
downsamp = 1;

% Downsample Factor (automatically goes to closest viable factor)
downsamp_fact = 4;

% Gaussian Blur Toggle (1 -> On, 0 -> Off)
gaussBlur = 0;

% Standard Deviation of Gaussian Filter Blur
% (I chose this number because it seemed to 
% reduce most of the aliasing on the dial photos)
sigma = 0.35*downsamp_fact;

% Bilateral Filtering Toggle (1 -> On, 0 -> Off)
bilat_filt = 1;

% Edge Detection (1), Adaptive Threshold (2), Both (3) Toggle
edge_adapt = 2;

% Neighborhood for Widening Edge-Detector (around pixel)
% 1 -> 1st Order Neighborood, 2 -> 2nd Order Neighborhood
neighborhood = 2;

% Erode BW Cutout Dial Image (1-> On, else -> Off)
erode = 1;

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% Load Image

% Select Image
[im_name,path] = uigetfile('*.*');

% Read Image
im_original = imread(strcat(path,im_name));
%im_original = imnoise(im_original, "gaussian", 0, 0.1);

% New Image Name
print_text = strcat("\nProcessing ",im_name, " . . .\n\n");
fprintf(print_text)

% Image Dimensions
dim_OG = size(im_original);


% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% Downsample

% If downsampling is on % the image is divisible by the downsample factor
if ( (downsamp == 1) )%&& (sum(mod(dim(1:2),downsamp_fact)) == 0) )

    % If Gaussian Blur is toggled on
    if (gaussBlur == 1)
        % Blur Image
        im_blur = imgaussfilt(im_original,sigma);
    % If not
    elseif (gaussBlur == 0)
        % Don't Blur Image
        im_blur = im_original;
    end

    % Find the common divisors between the 2 dimensions of the OG image
    downsamp_possibilities = intersect(divisors(dim_OG(1)), divisors(dim_OG(2)));


    if not(sum(ismember(downsamp_possibilities, downsamp_fact)))
        % Find index of the possible downsample factor closest to the input
        [~, downsamp_new_index] = min(abs(downsamp_fact - downsamp_possibilities));
    
        % Put New Downsample Factor into variable
        downsamp_fact_new = downsamp_possibilities(downsamp_new_index);

        % Print Notification
        fprintf("\nThe image was downsampled by %d instead of %d\nbecause %d doesn't fit!\n",downsamp_fact_new, downsamp_fact, downsamp_fact);

        % Set as new downsample factor
        downsamp_fact = downsamp_fact_new;
    end

    % Downsample Image
    im = im_blur( 1:downsamp_fact:dim_OG(1) ,  1:downsamp_fact:dim_OG(2), :);


    % Display
    figure('Name', 'Downsampling Process')
    subplot(2,2,1)
    imshow(im_original)
    title("Original Image")
    subplot(2,2,2)
    imshow(im_blur)
    title("Blurred Image")
    subplot(2,2,3)
    imshow(im)
    title("Downsampled Image")
else
    im = im_original;
end

% Convert to uint8
im = uint8(im);

% Downsampled Image Dimensions
dim = size(im);

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% BILATERAL FILTERING

if (bilat_filt == 1)
    im_bilat = imbilatfilt(im);

    figure('Name',"Bilateral Filtering Process")
    subplot(1,2,1)
    imshow(im); title("Before")
    subplot(1,2,2)
    imshow(im_bilat);  title("After Bilateral Filtering")

    im = im_bilat;
end


% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% EDGE DETECTION /[OR]/ ADAPTIVE THRESHOLDING

% CONVERT TO GRAYSCALE   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (length(dim_OG) == 3)
    im_bw = rgb2gray(im);
else
    im_bw = im;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EDGE DETECTION ~ ~ ~ ~ ~ ~ ~ ~ ~
if (edge_adapt == 1) || (edge_adapt == 3)
    
    % DETECT IMAGE EDGES   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    im_edge = double(edge(im_bw));
    

    % WIDEN EDGE-DETECTED IMAGE   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Preallocate
    im_preCirc = im_edge; % Widened Edge-Detected Image
    
    % 1st Order Neighborhood
    if (neighborhood == 1)
        for r = 2:size(im_edge, 1)-1
            for c = 2:size(im_edge, 2)-1
                % 1st Order Neighborhood around pixel (r,c)
                nbhd_1 = [im_edge(r-1,c), im_edge(r,c-1), im_edge(r+1,c), im_edge(r,c+1)];
                
                % If there are any edges in the neighborhood
                if (sum(nbhd_1) > 0)
                    im_preCirc(r,c) = 1;
                end
            end
        end
    % 2nd Order Neighborhood
    elseif (neighborhood == 2)
        for r = 2:size(im_edge, 1)-1
            for c = 2:size(im_edge, 2)-1
                % 2nd Order Neighborhood around pixel (r,c)
                nbhd_2 = [im_edge(r-1,c-1), im_edge(r-1,c), im_edge(r,c-1), im_edge(r+1,c+1), im_edge(r+1,c), im_edge(r,c+1), im_edge(r+1,c-1), im_edge(r-1,c+1)];
                
                % If there are any edges in the neighborhood
                if (sum(nbhd_2) > 0)
                    im_preCirc(r,c) = 1;
                end
            end
        end
    end

    % Invert Widened Edge-Detected Image   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    im_preCirc_A = not(im_preCirc);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ADAPTIVE THRESHOLDING ~ ~ ~ ~ ~ ~ ~ ~ ~
if (edge_adapt == 2) || (edge_adapt == 3)
    % ADAPTIVE THRESHOLD   %%%%%%%
    
    % Find the adaptive threshold at each pixel based on neighborhood mean
    thresh = adaptthresh(im_bw, 0.35, 'Statistic','gaussian', 'ForegroundPolarity','bright');
    
    % Convert into a binary image based on the threshold
    im_preCirc = imbinarize(im_bw, thresh); % Adaptive-Thresholded Image

    % Invert
    im_preCirc_B = not(im_preCirc);
end

% Determine Final Binary Image
if (edge_adapt == 1)
    im_preCirc_inv = im_preCirc_A;  % Widened Edge-Detected
elseif (edge_adapt == 2)
    im_preCirc_inv = im_preCirc_B;  % Adaptive-Thresholded
elseif (edge_adapt == 3)
    im_preCirc_inv = (im_preCirc_A & im_preCirc_B); % Both

    figure()
    subplot(2,2,1)
    imshow(im_preCirc_A)
    subplot(2,2,2)
    imshow(im_preCirc_B)
    subplot(2,2,[3,4])
    imshow(im_preCirc_inv)
end


% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%% FIND CIRCLES


short_dim = min(size(im,[1,2]));   % Shortest dimension of image
min_radius_perc = 0.05; % minimum radius (as a percent of short_dim)
radius_range = [round(min_radius_perc*short_dim), short_dim]; % Circle Radius Range

% Find Circles
[centers, radii, metric] = imfindcircles(im_preCirc_inv, radius_range);

% Create Rectangle Bounding Box Parameters
x_rec = round( centers(:,1) - radii ); % lower left corner x-value
y_rec = round( centers(:,2) - radii ); % lower left corner y-value
w_rec = round(2*radii);    % horizontal width
h_rec = w_rec;                  % vertical height

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DISPLAY THE DETECTED CIRCLES   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Display
figure('Name', 'Circle Detection Process')

% Edge Detection
if (edge_adapt == 1)
    subplot(2,2,1)
    imshow(im_edge)
    title("Edge-Detected Image")
    subplot(2,2,2)
    imshow(im_preCirc)
    title("Widened Edge-Detected Image")
    subplot(2,2,3)
    imshow(im_preCirc_inv)
    title("Inverted Widened Edge-Detected Image")

% Adaptive Thresholding
elseif (edge_adapt == 2)
    subplot(2,2,[1,2])
    imshow(im_preCirc)
    title("Adaptive-Thresholded Image")
    subplot(2,2,3)
    imshow(im_preCirc_inv)
    title("Inverted Adaptive-Thresholded Image")
end

% Circles (& Bounding Boxes) Overlayed on OG Image
subplot(2,2,4)
imshow(im)
% Rectangles
for i = 1:size(x_rec, 1)
    rectangle('Position',[x_rec(i), y_rec(i), w_rec(i), h_rec(i)], 'EdgeColor','r', 'LineWidth',2)
end
% Circles
viscircles(centers, radii,'EdgeColor','b'); % circle circumferences
viscircles(centers, ones(size(centers,1),1),'EdgeColor','b'); % circle centers
title("Detected Circles")

%% Cut Each Circle Out
circles_list = cell(1, size(x_rec, 1));     % Modified Circle Cutout
circles_list_im = cell(1, size(x_rec, 1));  % Circle Cutout of Image

for i = 1:size(x_rec, 1)
    x_range = round( centers(i,1) - radii(i) ) : round( centers(i,1) + radii(i) );
    y_range = round( centers(i,2) - radii(i) ) : round( centers(i,2) + radii(i) );

    % Too low fix
    x_range(x_range <= 0) = 1;  % width
    y_range(y_range <= 0) = 1;  % height
    % Too high fix
    x_range(x_range > dim(2)) = dim(2);  % height
    y_range(y_range > dim(1)) = dim(1);  % width

    %// Generate grid with binary mask representing the circle. Credit to Jonas for original code.
    %x_range_grid = round(-length(x_range)/2) : round(length(x_range)/2);
    %y_range_grid = round(-length(y_range)/2) : round(length(y_range)/2);

    [y_grid, x_grid] = ndgrid(y_range - round(centers(i,2)), x_range - round(centers(i,1)));
    mask = (x_grid.^2 + y_grid.^2) > (0.7*radii(i)^2);

    im_cutout = im_preCirc(y_range, x_range);
    im_cutout(mask) = 0;
    
    if (erode == 1)
        se = strel('square', 2);
        % Erode the image with the structuring element.
        im_cutout = imerode(im_cutout, se);
    end

    circles_list{1, i} = im_cutout;

    circles_list_im{1, i} = im(y_range, x_range,:);
end

figure('Name','Cut-Out Circles (Dials)')
montage(circles_list)

%% FIND LINES

numLines = 10;                  % # of lines to find
c_num = size(circles_list, 2);  % # of circles

figure('Name', 'Detected Lines in Cut-Out Circles')
for i = 1:c_num

    % Compute the Hough transform of the binary image returned by edge.
    [H,theta,rho] = hough(circles_list{i});
    
    % Find the peaks in the Hough transform matrix, H, using the houghpeaks function.
    P = houghpeaks(H,numLines);%,'threshold',ceil(0.3*max(H(:))));
    
    % Find lines in the image using the houghlines function. 
    lines = houghlines(circles_list{i},theta,rho,P, 'FillGap', 30, 'MinLength',radii(i)/3.5);

    % Only keep the lines that have a length of less than the circle radius
    keep = vecnorm(vertcat(lines.point1)-vertcat(lines.point2),2,2) < radii(i);
    lines = lines(keep);
    
    % Create a plot that displays the original image with the lines superimposed on it.
    subplot(2, c_num, i)
    imshow(circles_list{i}), hold on
    max_len = 0;
    for k = 1:length(lines)
       xy = [lines(k).point1; lines(k).point2];
       plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
    
       % Plot beginnings and ends of lines
       plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
       plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
    
       % Determine the endpoints of the longest line segment
       len = norm(lines(k).point1 - lines(k).point2);
       if ( len > max_len)
          max_len = len;
          xy_long = xy;
       end
    end
    if not(isempty(lines))
        % highlight the longest line segment
        plot(xy_long(:,1),xy_long(:,2),'LineWidth',2,'Color','red');
    end
    title(strcat("Top Lines: Dial #", num2str(i)))
    hold off;

    subplot(2, c_num, c_num + i)
    imshow(circles_list_im{i}), hold on
    if not(isempty(lines))
        % Overlay the longest line segment
        plot(xy_long(:,1),xy_long(:,2),'LineWidth',2,'Color','red');
    end
    title(strcat("Longest Line: Dial #", num2str(i)))

end


toc % timer end
