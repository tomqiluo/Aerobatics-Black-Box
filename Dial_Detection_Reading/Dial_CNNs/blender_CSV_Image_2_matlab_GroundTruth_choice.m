% FUNCTION: Converter to use in Deep Neural Network
% Blender CSV Labels & Images ---> Matlab Ground Truth Object

function ground_truth = blender_CSV_Image_2_matlab_GroundTruth_choice(im_folder_path, path_and_blender_csv_name, path_and_blender_skyBBOX_csv_name)
    % If the user used the Sky Bounding Box Data in the Input Parameters
    % then use that data for the reuslt, if not don't.
    if exist('path_and_blender_skyBBOX_csv_name','var')
        sky_bbox_toggle = 1;
    else
        sky_bbox_toggle = 0;
    end
    

    % Create Image Datastore for images
    imds = imageDatastore(im_folder_path);
    % Create Object for Storing Ground Truth Data Sources from Folder Containing Image Files
    % dataSource = groundTruthDataSource(im_folder_path);
    dataSource = groundTruthDataSource(imds);
    
    % Label Definitions Table _-_-_-_-_-_-_-
    ldc = labelDefinitionCreator;
    % Dial Bounding-Box Label
    addLabel(ldc, 'Dial', labelType.Rectangle, 'labelColor', [1 0 0],'Description', "Circular Dial with Pointer Needle");
    % Pointer Angle Attribute
    addAttribute(ldc, 'Dial', 'Pointer_Angle', attributeType('Numeric'), 0,'Description', '0° <-> 360° with 0°/360° starting at the top (like a clock) and moving counter clockwise');
    
    if (sky_bbox_toggle == 1)
        % Sky Bounding-Box Label
        addLabel(ldc, 'Sky', labelType.Rectangle, 'labelColor', [0 1 0],'Description', "Sky or Outside the Airplane Windows");
    end

    % Create Label Definitions Table
    labelDefs = create(ldc);
    
    % Create Matrix from Blender Export CSV File
    blender_mat = readmatrix(path_and_blender_csv_name);
    
    obj_column = 1;     % column of data with object (dial) number
    frame_column = 2;   % column of data with frame number
    rot_column = 3;     % leftmost column of needle rotation data
    bbox_column = 6;    % leftmost column of bounding-box data
    
    if (sky_bbox_toggle == 1)
        % Create Matrix from Blender Export Sky Bbox CSV File
        sky_mat = readmatrix(path_and_blender_skyBBOX_csv_name);
        sky_bbox_column = 3;    % leftmost column of bounding-box data
    end

    % Number of Frames
    % num_frames = length(dataSource.Source);
    num_frames = length(dataSource.Source.Files);
    
    % EXTRACT & FORMAT DATA _-_-_-_-_-_-_-
    
    % Object Number Vector      | Object # |
    obj_vec = blender_mat(:, obj_column);
    
    % Number of Dials (Selected Blender Objects)
    num_dials = length(unique(obj_vec));
    
    if (sky_bbox_toggle == 1)
        % Number of Sky Bboxes (Selected Blender Objects)
        num_sky_bboxes = length(unique(sky_mat(:,obj_column)));
    end

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
    
    if (sky_bbox_toggle == 1)
        % Skies Matrix (Blender Matrix split up by each sky bbox)
        % row = frame, column = data value, for each sky bbox
        sky_current_bbox_mat = zeros(num_frames, size(sky_mat, 2), num_sky_bboxes);
        sky_bbox_mat = zeros(num_frames, 4, num_sky_bboxes); % Sky Bounding-Box Matrices
        
        % For each Sky Bbox . . .
        for sky_ind = 1:num_sky_bboxes
            % Create Sky BBoxes Matrix
            sky_current_bbox_mat(:,:,sky_ind) = sky_mat(  ( ((num_frames*(sky_ind-1))+1) : (num_frames*sky_ind) ), :  );
        
            % Get Bounding-Box Matrix   | Bound-Box: x, y, width, height |
            sky_bbox_mat(:,:,sky_ind) = sky_current_bbox_mat(:, sky_bbox_column:(sky_bbox_column+3), sky_ind);
        end
    end

    % Format From Matrices into Cell Array of Structure Arrays into Label Data
    
    % Preallocate
    cellarray = cell(num_frames,1); % one cell array for all frames/images
    s(1).Position = []; s(1).Pointer_Angle = 0;        % create example struct array to copy size
    structarray = s([]);            % one strcut array for each frame/image
%     frame_width = 256;
%     frame_height = 256;
    dial_f_count = 0;
    
    if (sky_bbox_toggle == 1)
        sky_cellarray = cell(num_frames,1); % SKY BBOXES: one cell array for all frames/images
        sky_mat_frame = [];                 % matrix for sky bboxes in a frame
        sky_struct(1).Position = [];        % create example struct array to copy si
        sky_structarray = sky_struct([]);   % one strcut array for each frame/image
        sky_f_count = 0;
    end

    % For Each Frame/Image
    for frame_i = 1:num_frames
        
        [frame_height, frame_width, ~] = size(imread(imds.Files{frame_i}));

        % For Each Dial . . .
        for dial_i = 1:num_dials
            % Discard bounding boxes outside the frame
            bbox_pos = bbox_mat(frame_i, :, dial_i); % bounding box vector
    
            % Check if each corner's height & width are in frame
            [tl_w, tl_h, br_w, br_h] = check_bbox_bounds(bbox_pos, frame_width, frame_height);
    
            % If the bounding box is within the frame: add it
            if ( (tl_w && tl_h) && (br_w && br_h) )
                dial_f_count = dial_f_count + 1; % incrment dial counter for frame
                % Bounding Box Position
                structarray(dial_f_count).Position = bbox_pos;
                % Pointer Angle
                structarray(dial_f_count).Pointer_Angle = rot_vec(frame_i, dial_i);
            end
        end

        % Put the sample data (structure array) into the data array (cell array)
        cellarray(frame_i) = {structarray};
    
        % Reset Structure Array
        structarray = s([]);
    
        % Reset counters
        dial_f_count = 0;

        
        if (sky_bbox_toggle == 1)
            % For each SKY BBOX . . .
            for sky_i = 1:num_sky_bboxes
                % Discard SKY bounding boxes outside the frame
                sky_bbox_pos = sky_bbox_mat(frame_i, :, sky_i); % bounding box vector
        
                % Check if each corner's height & width are in frame
                [tl_w_sky, tl_h_sky, br_w_sky, br_h_sky] = check_bbox_bounds(sky_bbox_pos, frame_width, frame_height);
        %         if (sky_i == 1)
        %             sky_bbox_pos
        %         end
                % If the bounding box is within the frame: add it
                if ( (tl_w_sky && tl_h_sky) && (br_w_sky && br_h_sky) )
                    sky_f_count = sky_f_count + 1; % incrment sky counter for frame
                    % Bounding Box Position
        %             sky_mat_frame(sky_i, :) = sky_bbox_pos;
                    sky_structarray(sky_f_count).Position = sky_bbox_pos;
                end
            end
            % Put the sample data (structure array) into the data array (cell array)
            sky_cellarray(frame_i) = {sky_structarray};
            % Reset Structure Array
            sky_structarray = sky_struct([]);
            % Reset counters
            sky_f_count = 0;
        end
        
    end
    
    % Create Table of Labels
    labelData = table;
    labelData.Dial = cellarray;     % Assign DIAL Bounding Box - Pointer Angle cell array to table
    if (sky_bbox_toggle == 1)
        labelData.Sky = sky_cellarray;  % Assign SKY Bounding Box cell array to table
    end

    ground_truth = groundTruth(dataSource, labelDefs, labelData);
    
    
    
%     train_t_test = objectDetectorTrainingData(ground_truth);
    
    
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

end