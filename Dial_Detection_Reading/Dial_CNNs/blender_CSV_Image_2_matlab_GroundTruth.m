% FUNCTION: Converter to use in Deep Neural Network
% Blender CSV Labels & Images ---> Matlab Ground Truth Object

function ground_truth = blender_CSV_Image_2_matlab_GroundTruth(im_folder_path, path_and_blender_csv_name)

    % Create Object for Storing Ground Truth Data Sources from Folder Containing Image Files
    dataSource = groundTruthDataSource(im_folder_path);
    
    % Label Definitions Table _-_-_-_-_-_-_-
    ldc = labelDefinitionCreator;
    % Dial Bounding -Box Label
    addLabel(ldc, 'Dial', labelType.Rectangle, 'labelColor', [1 0 0],'Description', "Circular Dial with Pointer Needle");
    % Pointer Angle Attribute
    addAttribute(ldc, 'Dial', 'Pointer_Angle', attributeType('Numeric'), 0,'Description', '0° <-> 360° with 0°/360° starting at the top (like a clock) and moving counter clockwise');
    % Create Label Definitions Table
    labelDefs = create(ldc);
    
    % Create Matrix from Blender Export CSV File
    blender_mat = readmatrix(path_and_blender_csv_name);
    
    obj_column = 1;     % column of data with object (dial) number
    frame_column = 2;   % column of data with frame number
    rot_column = 3;     % leftmost column of needle rotation data
    bbox_column = 6;    % leftmost column of bounding-box data
    
    % Number of Frames
    num_frames = length(dataSource.Source);
    
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
    rot_mat = zeros(num_frames, 3, num_dials);  % Rotation (XYZ) Matrices
    rot_vec = zeros(num_frames, num_dials);     % Rotation Vectors
    bbox_mat = zeros(num_frames, 4, num_dials); % Bounding-Box Matrices
    
    % For Each Dial . . .
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
    
    % Format From Matrices into Cell Array of Structure Arrays into Label Data
    
    % Preallocate
    cellarray = cell(num_frames,1); % one cell array for all frames/images
    s(1).Position = []; s(1).Pointer_Angle = 0;        % create example struct array to copy size
    sturctarray = s([]);            % one strcut array for each frame/image
    frame_width = 256;
    frame_height = 256;
    
    % For Each Frame/Image
    for frame_i = 1:num_frames
        % For Each Dial . . .
        for dial_i = 1:num_dials
            % Discard bounding boxes outside the frame
            bbox_pos = bbox_mat(frame_i, :, dial_i); % bounding box vector
            tl_w = ((bbox_pos(1) < frame_width) & (bbox_pos(1) > 0));   % top left width check
            tl_h = ((bbox_pos(2) < frame_height) & (bbox_pos(2) > 0));  % top left height check
            br_w = (( bbox_pos(1) + bbox_pos(3) ) < frame_width) & (( bbox_pos(1) + bbox_pos(3) ) > 0); % bottom right width check
            br_h = (( bbox_pos(2) + bbox_pos(4) ) < frame_height) & (( bbox_pos(2) + bbox_pos(4) ) > 0);% bottom right height check);
            % If the bounding box is within the frame: add it
            if ( (tl_w && tl_h) && (br_w && br_h) )
                % Bounding Box Position
                sturctarray(dial_i).Position = bbox_mat(frame_i, :, dial_i);
                % Pointer Angle
                sturctarray(dial_i).Pointer_Angle = rot_vec(frame_i, dial_i);
            end
        end
        % Put the sample data (structure array) into the data array (cell array)
        cellarray(frame_i) = {sturctarray};

        % Reset Structure Array
        sturctarray = s([]);
    end
    
    % Create Table of Labels
    labelData = table;
    labelData.Dial = cellarray;    % Assign Bounding Box - Pointer Angle cell array to table
    
    ground_truth = groundTruth(dataSource, labelDefs, labelData);


end