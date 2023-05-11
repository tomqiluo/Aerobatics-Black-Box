% MAIN MODULE FOR DASHBOARD DIAL READING (VIDEO)

clear; close all;

tic % timer start   ~*~*~*~


% ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
%% Input Parameters   ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~

% Select original video file
[vid_name,path] = uigetfile('*.*');

% Dialog Box for Input Parameters
dlg_title = 'Dashboard Dial Reader Video Input Parameters';
prompt = {'Display Toggle: (0 -> Off, 1 -> On, 2 -> Draw circles on image pixels)', ...
          'Dial Pointer Detection Toggle: (0 -> Off, 1 -> On)', ...
          'Downsampling Toggle: (1 -> On, 0 -> Off)', ...
          'Downsample Factor: (automatically goes to closest viable factor)', ...
          'Gaussian Blur Toggle: (1 -> On, 0 -> Off)', ...
          'Standard Deviation of Gaussian Filter Blur:', ...
          'Bilateral Filtering Toggle: (1 -> On, 0 -> Off)', ...
          'Binary Image Creator Toggle: (1 -> Edge Detection, 2 -> Adaptive Threshold, 3 -> Both)', ...
          'Neighborhood for Widening Edge-Detector: (around pixel) (1 -> 1st Order Neighborood, 2 -> 2nd Order Neighborhood)', ...
          'Erode BW Cutout Dial Image: (1-> On, else -> Off)', ...

          };
dlg_dims = [1,70];
definput = {'2','2','1','4','1','1.4','1','2','2','0'};
opts.Resize = 'on';
input_params = inputdlg(prompt,dlg_title,dlg_dims,definput,opts);

% Dialog Box for Video Profile (file type)
profiles = {'Archival','Motion JPEG AVI','Motion JPEG 2000','MPEG-4', ...
            'Uncompressed AVI','Indexed AVI','Grayscale AVI'};
[lst_ind,~] = listdlg('PromptString', {'Select a Video File Format', '(Recommended: MPEG-4 or ','Uncompressed AVI):'}, ...
                      'SelectionMode', 'single', 'InitialValue', 4, ...
                      'ListSize',[150,100], ...
                      'ListString', profiles);

% Display Toggle (0 -> Off, 1 -> On, 2 -> Draw circles on image pixels)
disp_toggle = str2double(input_params{1});

% Dial Pointer Detection Toggle (0 -> Off, 1 -> On)
dialPoint_toggle = str2double(input_params{2});

% Downsampling Toggle (1 -> On, 0 -> Off)
downsamp = str2double(input_params{3});

% Downsample Factor (automatically goes to closest viable factor)
downsamp_fact = str2double(input_params{4});

% Gaussian Blur Toggle (1 -> On, 0 -> Off)
gaussBlur = str2double(input_params{5});

% Standard Deviation of Gaussian Filter Blur
% (I chose this number because it seemed to 
% reduce most of the aliasing on the dial photos)
% 0.35 * downsamp_fact
sigma = str2double(input_params{6});

% Bilateral Filtering Toggle (1 -> On, 0 -> Off)
bilat_filt = str2double(input_params{7});

% Edge Detection (1), Adaptive Threshold (2), Both (3) Toggle
edge_adapt = str2double(input_params{8});

% Neighborhood for Widening Edge-Detector (around pixel)
% 1 -> 1st Order Neighborood, 2 -> 2nd Order Neighborhood
neighborhood = str2double(input_params{9});

% Erode BW Cutout Dial Image (1-> On, else -> Off)
erode = str2double(input_params{10});



% Video Profile (File Type)
selected_profile = profiles{lst_ind};


% ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
%% Load Image   ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~

% New video name
input_str = '';
if (dialPoint_toggle == 1)
    input_str = '_dialPoint';
end
if (downsamp == 1)
    input_str = append(input_str, strcat('_downX', num2str(downsamp_fact)));
end
if (gaussBlur == 1)
    input_str = append(input_str, strcat('_Gblur', num2str(sigma)));
end
if (bilat_filt == 1)
    input_str = append(input_str, '_bilatFilt');
end
switch edge_adapt
    case 1
        input_str = append(input_str,strcat('_edgeDetect', num2str(neighborhood)));
    case 2
        input_str = append(input_str, '_adaptThresh');
    case 3
        input_str = append(input_str,strcat('_edgeDetect', num2str(neighborhood), '_adaptThresh'));
end
if (erode == 1)
    input_str = append(input_str, '_erode');
end

new_vid_name = strcat(vid_name, '__Dial-Detect__', input_str);
fprintf(strcat("-----\nCreating \n", new_vid_name, "\nin the ", selected_profile, " format . . .\n"))




% Create objects to read and write the video
v_reader = VideoReader(strcat(path, vid_name));
v_writer = VideoWriter(new_vid_name, selected_profile);
% Make frame rates equal
v_writer.FrameRate = v_reader.FrameRate;
% Open the video file for writing
open(v_writer);

% Width & Height
v_width = v_reader.Width;
v_height = v_reader.Height;

% Preallocate
frame_new = zeros(v_height, v_width, 3);    % new frame size
incr = 0;                                   % increment
circles_struct = struct('cent',[], 'rad',[]);

% Create new video
while hasFrame(v_reader)

    incr = incr + 1;

    % get current frame
    frame = readFrame(v_reader);

    [centers, radii, frame_new, ~] = dial_read(frame, strcat("frame ",num2str(incr)), disp_toggle, dialPoint_toggle, downsamp, downsamp_fact, gaussBlur, sigma, bilat_filt, edge_adapt, neighborhood, erode);

    circles_struct(incr).cent = centers;
    circles_struct(incr).rad = radii;

    % write new frame to new video
    writeVideo(v_writer, frame_new);

end

close(v_writer); % close the new video file

fprintf("\n>>> DONE <<<\n")

toc % timer end   ~*~*~*~
