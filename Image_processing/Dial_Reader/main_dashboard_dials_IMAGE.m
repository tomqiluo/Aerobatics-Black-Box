% MAIN MODULE FOR DASHBOARD DIAL READING

clear; close all;

tic % timer start   ~*~*~*~


% ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
%% Input Parameters   ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~

% Select Image
[im_name,path] = uigetfile('*.*');

% Dialog Box for Input Parameters
dlg_title = 'Dashboard Dial Reader Video Input Parameters';
prompt = {'Display Toggle: (0 -> Off, 1 -> On, 2 -> Draw circles on image pixels)', ...
          'Downsampling Toggle: (1 -> On, 0 -> Off)', ...
          'Downsample Factor: (automatically goes to closest viable factor)', ...
          'Gaussian Blur Toggle: (1 -> On, 0 -> Off)', ...
          'Standard Deviation of Gaussian Filter Blur:', ...
          'Bilateral Filtering Toggle: (1 -> On, 0 -> Off)', ...
          'Edge Detection: (1), Adaptive Threshold (2), Both (3) Toggle', ...
          'Neighborhood for Widening Edge-Detector: (around pixel)', ...
          'Erode BW Cutout Dial Image: (1-> On, else -> Off)', ...

          };
dlg_dims = [1,40];
definput = {'2','1','4','1','1.4','1','2','2','0'};
opts.Resize = 'on';
input_params = inputdlg(prompt,dlg_title,dlg_dims,definput,opts);


% Display Toggle (0 -> Off, 1 -> On, 2 -> Draw circles on image pixels)
disp_toggle = str2double(input_params{1});

% Downsampling Toggle (1 -> On, 0 -> Off)
downsamp = str2double(input_params{2});

% Downsample Factor (automatically goes to closest viable factor)
downsamp_fact = str2double(input_params{3});

% Gaussian Blur Toggle (1 -> On, 0 -> Off)
gaussBlur = str2double(input_params{4});

% Standard Deviation of Gaussian Filter Blur
% (I chose this number because it seemed to 
% reduce most of the aliasing on the dial photos)
% 0.35 * downsamp_fact
sigma = str2double(input_params{5});

% Bilateral Filtering Toggle (1 -> On, 0 -> Off)
bilat_filt = str2double(input_params{6});

% Edge Detection (1), Adaptive Threshold (2), Both (3) Toggle
edge_adapt = str2double(input_params{7});

% Neighborhood for Widening Edge-Detector (around pixel)
% 1 -> 1st Order Neighborood, 2 -> 2nd Order Neighborhood
neighborhood = str2double(input_params{8});

% Erode BW Cutout Dial Image (1-> On, else -> Off)
erode = str2double(input_params{9});


% ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
%% Load Image   ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~

% Read Image
im_original = imread(strcat(path,im_name));

% Detect Dials
im_overlays = dial_read(im_original, im_name, disp_toggle, downsamp, downsamp_fact, gaussBlur, sigma, bilat_filt, edge_adapt, neighborhood, erode);

% Display Image with Overlays
imshow(im_overlays)

toc % timer end   ~*~*~*~