%{
~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
Image Object Vertices Visualizer
~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

4/11/2023
 
Blender Export CSV File Format: 
| Object # | Frame # | Bound-Box: x, y, width, height |

%}

clear; close all;

% Select original video file
[vid_name,path1] = uigetfile('*.*', "Select a Video File");

% Select Blender Export CSV File
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
bbox_column = 3;    % leftmost column of bounding-box data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Video Profile (File Type)
selected_profile = profiles{lst_ind};

% New Video Name
new_vid_name = strcat(vid_name, '__ANGLE_BBOX_VISUAL_BboxOnly_');


% SET UP VIDEO _-_-_-_-_-_-_-

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

% Preallocate _-_-_-_-_-
% Dials Matrix (Blender Matrix split up by each dial)
% row = frame, column = data value, for each dial
dials_mat = zeros(num_frames, size(blender_mat, 2), num_dials);
frame_vec = zeros(num_frames, num_dials);   % Frames Vectors
bbox_mat = zeros(num_frames, 4, num_dials); % Bounding-Box Matrices

% For Each Dial . . .
for dial_ind = 1:num_dials
    % Create Dials Matrix
    dials_mat(:,:,dial_ind) = blender_mat(  ( ((num_frames*(dial_ind-1))+1) : (num_frames*dial_ind) ), :  );

    % Frame Number Vector       | Frame # |
    frame_vec(:,dial_ind) = dials_mat(:, frame_column, dial_ind);
    
    % Get Bounding-Box Matrix   | Bound-Box: x, y, width, height |
    bbox_mat(:,:,dial_ind) = dials_mat(:, bbox_column:(bbox_column+3), dial_ind);
end


% Preallocate & Set
frame_new = zeros(v_height, v_width, 3);    % new frame size
f_num = 0;                                  % frame number (incremental)

% CREATE ANNOTATED VIDEO _-_-_-_-_-_-_-
% For Each Frame . . .
while hasFrame(v_reader)
    % Increment frame #
    f_num = f_num + 1;
    
    % Print what's happening
    print_str = strcat("\nFrame #", num2str(f_num));
    fprintf(print_str);

    % Get current frame
    frame = readFrame(v_reader);
    
    % Copy frame to new frame for dial annotation
    frame_new = frame;

    % For Each Dial . . .
    for dial_i = 1:num_dials
        bbox_i = bbox_mat(f_num, :, dial_i);
        % Check if each corner's height & width are in frame
        [tl_w, tl_h, br_w, br_h] = check_bbox_bounds(bbox_i, v_width, v_height);
        
        % If the bounding box is within the frame: add it
        if ( (tl_w && tl_h) && (br_w && br_h) )
            % Insert Bounding Box
            frame_new = insertObjectAnnotation(frame_new, "rectangle", bbox_i, sprintf('BBOX %d', dial_i));
        else
            % Check if it is at least half within frame
            [tl_w_half, tl_h_half, br_w_half, br_h_half] = check_bbox_bounds_half(bbox_i, v_width, v_height);
            if ( (tl_w_half && tl_h_half) && (br_w_half && br_h_half) )
                uhh = find([tl_w, tl_h, br_w, br_h]);
                for ind = 1:length(uhh)
%                     % If it is the width
%                     if ( (uhh(ind) == 1) || (uhh(ind) == 3) )
%                         dims_vec_w = [0+1, v_width-1];
%                         [~, closest_ind_w] = min(abs(bbox_i(uhh(ind)) - dims_vec_w));
%                         bbox_i(uhh(ind)) = dims_vec_w(closest_ind_w);
%                     end
%                     % If it is the height
%                     if ( (uhh(ind) == 2) || (uhh(ind) == 4) )
%                         dims_vec_h = [0+1, v_height-1];
%                         [~, closest_ind_h] = min(abs(bbox_i(uhh(ind)) - dims_vec_h));
%                         bbox_i(uhh(ind)) = dims_vec_h(closest_ind_h);
%                     end
                    if (uhh(ind) == 1)
                        bbox_i(uhh(ind)) = 0+1;
                    elseif (uhh(ind) == 2)
                        bbox_i(uhh(ind)) = 0+1;
                    elseif (uhh(ind) == 3)
                        bbox_i(uhh(ind)) = (v_width-1) - bbox_i(1);
                    elseif (uhh(ind) == 4)
                        bbox_i(uhh(ind)) = (v_height-1) - bbox_i(2);
                    end
                    
                end
                % Insert Bounding Box
                frame_new = insertObjectAnnotation(frame_new, "rectangle", bbox_i, sprintf('BBOX %d', dial_i));
            end
        end
    end


    % Write new frame to new video
    writeVideo(v_writer, frame_new);

end

close(v_writer); % close the new video file

fprintf("\n>>> DONE <<<\n")



function [top_L_w, top_L_h, bottom_R_w, bottom_R_h] = check_bbox_bounds(bbox_vec, f_width, f_height)
    %{
      If the bounding box is in the frame all of the 
      output variables will equal 1 (True)
    %}

    % Discard bounding boxes outside the frame
    top_L_w = ((bbox_vec(1) < f_width) & (bbox_vec(1) > 0));   % top left width check
    top_L_h = ((bbox_vec(2) < f_height) & (bbox_vec(2) > 0));  % top left height check
    bottom_R_w = (( bbox_vec(1) + bbox_vec(3) ) < f_width) & (( bbox_vec(1) + bbox_vec(3) ) > 0); % bottom right width check
    bottom_R_h = (( bbox_vec(2) + bbox_vec(4) ) < f_height) & (( bbox_vec(2) + bbox_vec(4) ) > 0);% bottom right height check);
end

function [tL_w, tL_h, bR_w, bR_h] = check_bbox_bounds_half(bbox_vec, f_width, f_height)
    %{
      If the bounding box is in the frame all of the 
      output variables will equal 1 (True)
    %}

    half_bbox_w = round(bbox_vec(3) / 2);
    half_bbox_h = round(bbox_vec(4) / 2);

    f_w_high = (f_width + half_bbox_w);
    f_h_high = (f_height + half_bbox_h);
    f_w_low = 0 - half_bbox_w;
    f_h_low = 0 - half_bbox_h;


    % Discard bounding boxes outside the frame (+ half size buffer)
    tL_w = ((bbox_vec(1) < f_w_high) & (bbox_vec(1) > f_w_low));  % top left width check
    tL_h = ((bbox_vec(2) < f_h_high) & (bbox_vec(2) > f_h_low));  % top left height check
    bR_w = (( bbox_vec(1) + bbox_vec(3) ) < f_w_high) & (( bbox_vec(1) + bbox_vec(3) ) > f_w_low); % bottom right width check
    bR_h = (( bbox_vec(2) + bbox_vec(4) ) < f_h_high) & (( bbox_vec(2) + bbox_vec(4) ) > f_h_low); % bottom right height check);
end
