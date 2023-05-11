% Dial Reader Function

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

Cut Out Dials
*   Use circle radius to cut out each dial as its own image
*   Mask out pixels outside circle radius

Pointer Detection
*   Use Hough line transform to detect lines within a given length range
*   Choose the longest line as the dial pointer

%}

function [centers, radii, im_overlays, xy_long] = dial_read(im_original, im_name, disp_toggle, dialPoint_toggle, downsamp, downsamp_fact, gaussBlur, sigma, bilat_filt, edge_adapt, neighborhood, erode)
    %{
    im_original      =  input image
    im_name          =  name of input image
    disp_toggle      =  toggle for displaying intermediate steps in figures
    dialPoint_toggle =  toggle for finding dial pointers
    downsamp         =  toggle for downsampling the image
    downsamp_fact    =  factor to downsample by (for downsampling)
    gaussBlur        =  toggle for gaussian blur (for downsampling)
    sigma            =  standard deviation of gaussian filter blur (for downsampling)
    bilat_filt       =  bilateral filter toggle
    edge_adapt       =  toggle for edge detection, adaptive thresholding, or both
    neighborhood     =  neighborhood size (for edge detection)
    erode            =  toggle for eroding the binary cutout image
    %}

    % ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
    %% Preliminary   ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
    xy_long = int8.empty(2, 2, 0); % preallocate empty array

    
    % ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
    %% Load Image   ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
    
    %im_original = imnoise(im_original, "gaussian", 0, 0.1);
    
    % New Image Name
    print_text = strcat("Processing ",im_name, " . . .\n");
    fprintf(print_text)
    
    % Image Dimensions
    dim_OG = size(im_original);
    
    
    % ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
    %% Downsample   ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
    
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
    
        if (disp_toggle == 1)
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
        end
    else
        im = im_original;
    end
    
    % Convert to uint8
    im = uint8(im);
    
    % Downsampled Image Dimensions
    dim = size(im);
    
    % Create Output to Get Rid of Errors 
    % (correct size depending on if downsampling is toggled)
    im_overlays = im;
    
    
    % ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
    %% BILATERAL FILTERING   ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
    
    if (bilat_filt == 1)
        im_bilat = imbilatfilt(im);
        
        if (disp_toggle == 1)
            % Display
            figure('Name',"Bilateral Filtering Process")
            subplot(1,2,1)
            imshow(im); title("Before")
            subplot(1,2,2)
            imshow(im_bilat);  title("After Bilateral Filtering")
        end
    
        im = im_bilat;
    end
    
    
    % ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
    %% EDGE DETECTION /[OR]/ ADAPTIVE THRESHOLDING   ~%%%%%%%%%%%%%%%%%%%%%%%~
    
    % CONVERT TO GRAYSCALE   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (length(dim_OG) == 3)
        im_bw = rgb2gray(im);
    else
        im_bw = im;
    end
    
    % ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
    % EDGE DETECTION ~ ~ ~ ~ ~ ~ ~ ~ ~
    if (edge_adapt == 1) || (edge_adapt == 3)
        
        % DETECT IMAGE EDGES   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        im_edge = double(edge(im_bw));
        
    
        % WIDEN EDGE-DETECTED IMAGE   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
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
    
        % Invert Widened Edge-Detected Image   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        im_preCirc_A = not(im_preCirc);
    end
    
    % ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
    % ADAPTIVE THRESHOLDING ~ ~ ~ ~ ~ ~ ~ ~ ~
    if (edge_adapt == 2) || (edge_adapt == 3)
        % ADAPTIVE THRESHOLD   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        
        % Find the adaptive threshold at each pixel based on neighborhood mean
        thresh = adaptthresh(im_bw, 0.35, 'Statistic','gaussian', 'ForegroundPolarity','bright');
        
        % Convert into a binary image based on the threshold
        im_preCirc = imbinarize(im_bw, thresh); % Adaptive-Thresholded Image
    
        % Invert   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        im_preCirc_B = not(im_preCirc);
    end
    
    % ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
    % Determine Final Binary Image
    if (edge_adapt == 1)
        im_preCirc_inv = im_preCirc_A;  % Widened Edge-Detected
    elseif (edge_adapt == 2)
        im_preCirc_inv = im_preCirc_B;  % Adaptive-Thresholded
    elseif (edge_adapt == 3)
        im_preCirc_inv = (im_preCirc_A & im_preCirc_B); % Both
        
        if (disp_toggle == 1)
            % Display
            figure('Name','Combining Edge-Detection & Adaptive-Thresholding')
            subplot(2,2,1)
            imshow(im_preCirc_A)
            subplot(2,2,2)
            imshow(im_preCirc_B)
            subplot(2,2,[3,4])
            imshow(im_preCirc_inv)
        end
    end
    
    
    % ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
    %% FIND CIRCLES   ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
    
    % Find Radius Circle Range   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    short_dim = min(size(im,[1,2]));   % Shortest dimension of image
    min_radius_perc = 0.05; % minimum radius (as a percent of short_dim)
    radius_range = [round(min_radius_perc*short_dim), short_dim]; % Circle Radius Range
    
    % Find Circles   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    [centers, radii, ~] = imfindcircles(im_preCirc_inv, radius_range);
    
    % IF CIRCLES ARE FOUND ~~*~~*~~*~~*~~*~~*~~*~~*~~*~~*~~*~~*~~*~~*~~*~~
    if (~isempty(centers)) && (~isempty(radii))

    % Create Rectangle Bounding Box Parameters   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        x_rec = round( centers(:,1) - radii ); % lower left corner x-value
        y_rec = round( centers(:,2) - radii ); % lower left corner y-value
        w_rec = round(2*radii);     % horizontal width
        h_rec = w_rec;              % vertical height
        
        
        % ~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~%~
        % DISPLAY THE DETECTED CIRCLES ~ ~ ~ ~ ~ ~ ~ ~ ~
        
        if (disp_toggle == 1)
            % Display
            figure('Name', 'Circle Detection Process')
            
            % Edge Detection   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
            
            % Adaptive Thresholding   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            elseif (edge_adapt == 2)
                subplot(2,2,[1,2])
                imshow(im_preCirc)
                title("Adaptive-Thresholded Image")
                subplot(2,2,3)
                imshow(im_preCirc_inv)
                title("Inverted Adaptive-Thresholded Image")
            end
    
            % Circles (& Bounding Boxes) Overlayed on OG Image   ~~~~~~~~~~~~~~~~~~~~
            subplot(2,2,4)
            imshow(im)
            % Rectangles ~ ~ ~ ~ ~ ~ ~
            % For each detected circle . . .
            for i = 1:size(x_rec, 1)
                rectangle('Position',[x_rec(i), y_rec(i), w_rec(i), h_rec(i)], 'EdgeColor','r', 'LineWidth',2)
            end
    
            % Circles ~ ~ ~ ~ ~ ~ ~
            viscircles(centers, radii,'EdgeColor','b'); % circle circumferences
            viscircles(centers, ones(size(centers,1),1),'EdgeColor','b'); % circle centers
            title("Detected Circles")
    
        elseif (disp_toggle == 2)
            % Draw circles on image pixels
            im_overlays = circles_draw(im, centers, radii, 4);
            
        end
        
        % IF YOU WANT TO TRY TO FIND DIAL POINTERS TOO
        if (dialPoint_toggle == 1)
            % ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
            %% CUT EACH CIRCLE OUT   ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
            
            % Preallocate
            circles_cutout = cell(1, size(x_rec, 1));     % Modified Circle Cutout list
            circles_cutout_OG = cell(1, size(x_rec, 1));  % Unmodified Circle Cutout list
            
            % For each detected circle . . .
            for i = 1:size(x_rec, 1)
            
                % Get x & y ranges for square dial cutouts
                x_range = round( centers(i,1) - radii(i) ) : round( centers(i,1) + radii(i) );
                y_range = round( centers(i,2) - radii(i) ) : round( centers(i,2) + radii(i) );
            
                % Range too low fix
                x_range(x_range <= 0) = 1;  % width
                y_range(y_range <= 0) = 1;  % height
                % Range too high fix
                x_range(x_range > dim(2)) = dim(2);  % height
                y_range(y_range > dim(1)) = dim(1);  % width
            
                % Create grid around dial for mask
                [y_grid, x_grid] = ndgrid(y_range - round(centers(i,2)), x_range - round(centers(i,1)));
                % Create mask (pixels outside circle radius)
                rad_frac = 0.7; % fraction of radius to stop at
                mask = (x_grid.^2 + y_grid.^2) > (rad_frac*radii(i)^2);
            
                % Cut out dial
                im_cutout = im_preCirc(y_range, x_range);
                % Apply mask
                im_cutout(mask) = 0;
                
                if (erode == 1)
                    % Create structuring element
                    se = strel('square', 2);
                    % Erode the image with the structuring element.
                    im_cutout = imerode(im_cutout, se);
                end
            
                % Put modified cutout into list of images
                circles_cutout{1, i} = im_cutout;
            
                % Cutout corresponding spot in original image
                circles_cutout_OG{1, i} = im(y_range, x_range,:);
            end
            
            if (disp_toggle == 1)
                % Display
                figure('Name','Cut-Out Circles (Dials)')
                montage(circles_cutout)
            end
            
            
            % ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
            %% FIND LINES   ~%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~
            
            numLines = 10;                      % # of lines to find
            c_num = size(circles_cutout, 2);    % # of circles
            
            if (disp_toggle == 1)
                % Display
                figure('Name', 'Detected Lines in Cut-Out Circles')
            end
        
            % For each circle . . .
            for i = 1:c_num
            
                % Compute Hough line transform
                [H,theta,rho] = hough(circles_cutout{i});
                
                % Find peaks in the Hough line transform matrix
                P = houghpeaks(H,numLines);%,'threshold',ceil(0.3*max(H(:))));
                
                % Find lines
                lines = houghlines(circles_cutout{i},theta,rho,P, 'FillGap', 30, 'MinLength',radii(i)/3.5);
            
                % Only keep the lines that have a length of less than the circle radius
                keep = vecnorm(vertcat(lines.point1)-vertcat(lines.point2),2,2) < radii(i);
                lines = lines(keep);
                
                if (disp_toggle == 1)
                    % Display lines over dial cutout image
                    subplot(2, c_num, i)
                    imshow(circles_cutout{i}), hold on
                end
                max_len = 0;
            
                % For each line . . .
                for k = 1:length(lines)
                   xy = [lines(k).point1; lines(k).point2];
                   if (disp_toggle == 1)
                       plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');
                    
                       % Plot beginnings and ends of lines
                       plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
                       plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');
                   end
                
                   % Determine the endpoints of the longest line
                   len = norm(lines(k).point1 - lines(k).point2);
                   if ( len > max_len)
                      max_len = len;
                      xy_long = xy;
                   end
                end
            
                if (disp_toggle == 1)
                    if not(isempty(lines))
                        % Highlight the longest line segment
                        plot(xy_long(:,1),xy_long(:,2),'LineWidth',2,'Color','red');
                    end
            
                    % Title of 1st image plot
                    title(strcat("Top Lines: Dial #", num2str(i)))
                    hold off;
                
                    % Display Pointer line on original dial image cutouts
                    subplot(2, c_num, c_num + i)
                    imshow(circles_cutout_OG{i}), hold on
                    if not(isempty(lines))
                        % Overlay the longest line segment
                        plot(xy_long(:,1),xy_long(:,2),'LineWidth',2,'Color','red');
                    end
                
                    % Title of 2nd image plot
                    title(strcat("Longest Line: Dial #", num2str(i)))
                end
            end
        end
    end
end
