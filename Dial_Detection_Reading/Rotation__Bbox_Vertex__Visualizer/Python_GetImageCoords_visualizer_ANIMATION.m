% Image Object Vertices Visualizer

clear; close all;

% Select original video file
[vid_name,path1] = uigetfile('*.*', "Select a Video File");

% Select rotation vector (angle for each frame)
[blender_csv_name,path2] = uigetfile('*.*', "Select a Vertex Data File");
blender_mat = readmatrix(strcat(path2, blender_csv_name));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETERS

% Dialog Box for Video Profile (file type)
profiles = {'Archival','Motion JPEG AVI','Motion JPEG 2000','MPEG-4', ...
            'Uncompressed AVI','Indexed AVI','Grayscale AVI'};
[lst_ind,~] = listdlg('PromptString', {'Select a Video File Format', '(Recommended: MPEG-4 or ','Uncompressed AVI):'}, ...
                      'SelectionMode', 'single', 'InitialValue', 4, ...
                      'ListSize',[150,100], ...
                      'ListString', profiles);

rot_column = 5;     % column of data with needle rotation(4->x, 5->y, 6->z)
font_size = 8;      % text font size
txt_x_perc = 0.8;   % text x-position as percent of total frame width
txt_y_perc = 0.2;   % text y-position as percent of total frame height
ring_radius = 8;
ring_thickness = 4;

% Video Profile (File Type)
selected_profile = profiles{lst_ind};

% New Video Name
new_vid_name = strcat(vid_name, '__ROTATION_BBOX-VERTEX_VISUAL_');

% Create objects to read and write the video
v_reader = VideoReader(strcat(path1, vid_name));
v_writer = VideoWriter(new_vid_name, selected_profile);
% Make frame rates equal
v_writer.FrameRate = v_reader.FrameRate;
% Open the video file for writing
open(v_writer);

% Width & Height
v_width = v_reader.Width;
v_height = v_reader.Height;

% Needle Rotation Vector
rot_vec = blender_mat(:, rot_column);

% Get Vertices Matrix
vert_mat = blender_mat(:,7:end);
% Format
vert_x = vert_mat(:, 1:2:end);  % x-values are odd
vert_y = vert_mat(:, 2:2:end);  % y-values are even
% Fix y-values << bottom left (0,0) --> top left (0,0) >>
vert_y = v_height - vert_y;


% Preallocate & Set
frame_new = zeros(v_height, v_width, 3);    % new frame size
incr = 0;                                   % increment
text_pos = round([txt_x_perc*v_width, txt_y_perc*v_height]);  % Text Position

% Create new video
while hasFrame(v_reader)
    incr = incr + 1;
    
    % Print what's happening
    print_str = strcat("\nFrame #", num2str(incr), ", Rotation = ", num2str(rot_vec(incr)));
    fprintf(print_str);

    % get current frame
    frame = readFrame(v_reader);
    
    % Correctly Format Verteces
    num_verteces = length(vert_x(incr,:));
    centers = zeros(num_verteces,2); % preallocate
    for c = 1:num_verteces
        centers(c,:) = [vert_x(incr,c), vert_y(incr,c)];
    end

    % Create radii matrix
    ring_radii = repmat(ring_radius, size(centers));

    % Insert Verteces' Circles
    [frame_new, ~] = circles_draw_fixed(frame, centers, ring_radii, ring_thickness);

    % Insert Rotation Angle Text)
    rot_text = sprintf("Angle: %.2f°", rot_vec(incr));
    frame_new = insertText(frame_new, text_pos, rot_text, FontSize=font_size,TextColor="white", BoxColor="red", BoxOpacity=0.3);

    % write new frame to new video
    writeVideo(v_writer, frame_new);

end

close(v_writer); % close the new video file

fprintf("\n>>> DONE <<<\n")