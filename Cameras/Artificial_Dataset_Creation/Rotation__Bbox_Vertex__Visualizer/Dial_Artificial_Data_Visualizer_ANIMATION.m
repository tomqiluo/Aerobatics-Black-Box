% Image Object Vertices Visualizer

clear; close all;

% Select original video file
[vid_name,path1] = uigetfile('*.*', "Select a Video File");

% Select rotation vector (angle for each frame)
%{ 
FORMAT: 
| Object # | Frame # | Needle Angles: x, y, z | Bound-Box: x, y, width, height |
%}
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

obj_column = 1;     % column of data with object (dial) number
frame_column = 2;   % column of data with frame number
rot_column = 3;     % leftmost column of needle rotation data
bbox_column = 6;    % leftmost column of bounding-box data
font_size = 8;      % text font size
txt_x_perc = 0.8;   % text x-position as percent of total frame width
txt_y_perc = 0.2;   % text y-position as percent of total frame height
ring_radius = 8;
ring_thickness = 4;

% Video Profile (File Type)
selected_profile = profiles{lst_ind};

% New Video Name
new_vid_name = strcat(vid_name, '__ANGLE_BBOX_VISUAL_');

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

% Number of Frames
num_frames = v_reader.NumFrames;


% EXTRACT & FORMAT DATA _-_-_-_-_-_-_-

% Object Number Vector      | Object # |
obj_vec = blender_mat(:, obj_column);

% Number of Dials (Selected Blender Objects)
num_dials = length(unique(obj_vec));

% Preallocate
% Dials Matrix (Blender Matrix split up by each dial)
% row = frame, column = data value, for each dial
dials_mat = zeros(num_frames, size(blender_mat, 2), num_dials);
frame_vec = zeros(num_frames, num_dials);   % Frames Vectors
rot_mat = zeros(num_frames, 3, num_dials);  % Rotation (XYZ) Matrices
rot_vec = zeros(num_frames, num_dials);     % Rotation Vectors
bbox_mat = zeros(num_frames, 4, num_dials); % Bounding-Box Matrices

for dial_ind = 1:num_dials
    % Create Dials Matrix
    dials_mat(:,:,dial_ind) = blender_mat(  ( ((num_frames*(dial_ind-1))+1) : (num_frames*dial_ind) ), :  );

    % Frame Number Vector       | Frame # |
    frame_vec(:,dial_ind) = dials_mat(:, frame_column, dial_ind);
    
    % Needle Rotation Matrix    | Needle Angles: x, y, z |
    rot_mat(:,:,dial_ind) = dials_mat(:, rot_column:rot_column+2, dial_ind);
    % Needle Rotation Vector
    rot_column_for_angles = find(~all(rot_mat(:,:,dial_ind)==0)); % take the column that isn't all zeros
    rot_vec(:,dial_ind) = rot_mat(:, rot_column_for_angles, dial_ind);
    
    % Get Bounding-Box Matrix   | Bound-Box: x, y, width, height |
    bbox_mat(:,:,dial_ind) = dials_mat(:, bbox_column:(bbox_column+3), dial_ind);
end

% % Frame Number Vector       | Frame # |
% frame_vec = blender_mat(:, frame_column);
% 
% % Needle Rotation Matrix    | Needle Angles: x, y, z |
% rot_mat = blender_mat(:, rot_column:rot_column+2);
% % Needle Rotation Vector
% rot_vec = find(~all(rot_mat==0)); % take the column that isn't all zeros
% 
% % Get Bounding-Box Matrix   | Bound-Box: x, y, width, height |
% bbox_mat = blender_mat(:, bbox_column:(bbox_column+3));

% Preallocate & Set
frame_new = zeros(v_height, v_width, 3);    % new frame size
f_num = 0;                                  % frame number (incremental)
text_pos = round([txt_x_perc*v_width, txt_y_perc*v_height]);  % Text Position

% CREATE ANNOTATED VIDEO _-_-_-_-_-_-_-
% For Each Frame . . .
while hasFrame(v_reader)
    
    f_num = f_num + 1;
    
    % Print what's happening
    print_str = strcat("\nFrame #", num2str(f_num), ", Rotation = ", num2str(rot_vec(f_num)));
    fprintf(print_str);

    % get current frame
    frame = readFrame(v_reader);
    
%     % Correctly Format Verteces
%     num_verteces = length(vert_x(incr,:));
%     centers = zeros(num_verteces,2); % preallocate
%     for c = 1:num_verteces
%         centers(c,:) = [vert_x(incr,c), vert_y(incr,c)];
%     end
% 
%     % Create radii matrix
%     ring_radii = repmat(ring_radius, size(centers));
% 
%     % Insert Verteces' Circles
%     [frame_new, ~] = circles_draw_fixed(frame, centers, ring_radii, ring_thickness);
% 
%     % Insert Rotation Angle Text)
%     rot_text = sprintf("Angle: %.2f°", rot_vec(incr));
%     frame_new = insertText(frame_new, text_pos, rot_text, FontSize=font_size,TextColor="white", BoxColor="red", BoxOpacity=0.3);
    
    frame_new = frame;

    % For Each Dial . . .
    for dial_i = 1:num_dials
        % Needle Rotation Angle Text Label
        ang_txt = sprintf("Angle: %.2f°", rot_vec(f_num, dial_i));
        % Insert Bounding Box with Needle Angle Label
        frame_new = insertObjectAnnotation(frame_new, "rectangle", bbox_mat(f_num, :, dial_i), ang_txt, TextBoxOpacity=0.9);
    end

    % write new frame to new video
    writeVideo(v_writer, frame_new);

end

close(v_writer); % close the new video file

fprintf("\n>>> DONE <<<\n")