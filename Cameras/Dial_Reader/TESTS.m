% Dial Reader TESTS

clear; close all;


% Select Image
[im_name,path] = uigetfile('*.*');

% Read Image
im_OG = imread(strcat(path,im_name));

im = downsample(im_OG,4);
im = downsample(pagetranspose(im),4);
im = pagetranspose(im);

width_im = size(im,2);
height_im  =size(im,1);

%{
im_noise = imnoise(im, "gaussian", 0, 0.005);

figure()
subplot(1,2,1)
imshow(im)
subplot(1,2,2)
imshow(im_noise)
%}

im_bw = rgb2gray(im);

% Use adaptthresh to determine threshold to use in binarization operation.

thresh = adaptthresh(im_bw, 0.4);

% Convert image to binary image, specifying the threshold value.

im_adapthresh = imbinarize(im_bw,thresh);

% Display the original image with the binary version, side-by-side.

figure();
imshowpair(im_bw, im_adapthresh, 'montage');

% Invert Adapted -Thresholded Image
im_preCirc = not(im_adapthresh);


short_dim = min(size(im_preCirc,[1,2]));   % Shortest dimension of image
min_radius_perc = 0.05; % minimum radius (as a percent of short_dim)
radius_range = [round(min_radius_perc*short_dim), short_dim]; % Circle Radius Range

% Find Circles
[centers, radii, metric] = imfindcircles(im_preCirc, radius_range);

% Create Rectangle Parameters
x_rec = round( centers(:,1) - radii ); % lower left corner x-value
y_rec = round( centers(:,2) - radii ); % lower left corner y-value
w_rec = round(2*radii);    % horizontal width
h_rec = w_rec;                  % vertical height


figure()
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
circles_list = cell(1, size(x_rec, 1));

for c_n = 1:size(x_rec, 1)
    x_range = round( centers(c_n,1) - radii(c_n) ) : round( centers(c_n,1) + radii(c_n) );
    y_range = round( centers(c_n,2) - radii(c_n) ) : round( centers(c_n,2) + radii(c_n) );

    % Too low fix
    x_range(x_range <= 0) = 1;
    y_range(y_range <= 0) = 1;
    % Too high fix
    x_range(x_range > width_im) = 1;
    y_range(y_range > height_im) = 1;

    circles_list{1, c_n} = edge(im(y_range, x_range));

    
end

figure()
montage(circles_list)

%% FIND LINES

% # of lines to find
numLines = 5;

figure()
for i = 1: size(circles_list, 2)

    % Compute the Hough transform of the binary image returned by edge.
    [H,theta,rho] = hough(circles_list{i});
    
    % Find the peaks in the Hough transform matrix, H, using the houghpeaks function.
    P = houghpeaks(H,numLines);%,'threshold',ceil(0.3*max(H(:))));
    
    % Find lines in the image using the houghlines function. 
    lines = houghlines(circles_list{i},theta,rho,P);%,'FillGap',5,'MinLength',7);
    
    % Create a plot that displays the original image with the lines superimposed on it.
    subplot(1,size(circles_list, 2), i)
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
    % highlight the longest line segment
    plot(xy_long(:,1),xy_long(:,2),'LineWidth',2,'Color','red');

end


