% Video To Images Converter

% Select original video file
[vid_name,path] = uigetfile('*.*');

% Create objects to read and write the video
v_reader = VideoReader(strcat(path, vid_name));

% Preallocate
frame_new = zeros(v_reader.Height, v_reader.Width, 3);    % new frame size
incr = 1;                                   % increment

% # of frames to skip between saving to images
frame_step = 15;

% Create new video
while hasFrame(v_reader)

    % get current frame
    frame = readFrame(v_reader);

    % If the frame is in the frame step . . .
    if multiple_check(incr, frame_step)
        % Print the frame to be saved
        fprintf("\nFrame %d", incr);

%         % get current frame
%         frame = readFrame(v_reader);

        % write frame to image file
        imwrite(frame, sprintf("frame%d__%s_.png", incr, vid_name), "png");
    end

    % increment frame count
    incr = incr + 1;
end

fprintf("\n[DONE]")



function answer = multiple_check(int1, int2)
    % find if int1 is a multiple of int2
    answer = ( int2 * round(double(int1)/int2) == int1 );
end