% Circles Drawing Function

function [im_circles, mask_final] = circles_draw(im, centers, radii, ring_width)
    
    mask = logical(zeros([size(im),3])); % preallocate


    dims = size(im);

    % For some reason we need to disply the image to make the mask ...
    %fig1 = figure();
    imshow(im);
    
    im_circles = im; % set the base of the new circles image to the source image
    
    % Create Inner, Middle, and Outer Circles
    for in_mid_out = [0,1,-1]
        % If Middle
        if (in_mid_out == 0)
            se = strel('disk', ring_width, 0);
            rgb = [0,0,255]; % make middle colored
        % If Edges
        else
            se = strel('disk', 1, 0);
            rgb = [255,255,255]; % make edges white
            if (in_mid_out == -1) % if it is the inner border ring
                ring_width = -ring_width + 1; % set the correct radius
            end
        end
    
        for i = 1:size(centers,1)
            % Create circle
            % If circle will fit in the image bounds . . .
            uh = centers(i,:);
            if all(  centers(i,:) < ( dims([1,2]) - (radii(i)+(ring_width/2)) )  ) && all( centers(i,:) > (radii(i)+(ring_width/2)) )
                % Draw Circle
                roi = drawcircle('Center', centers(i,:), 'Radius', radii(i)+(ring_width/2));
                % Mask the circle
                mask_new = roi.createMask();
                % Create inner mask
                mask_new_inner = imerode(mask_new, se);
                % Erase inner mask from the original mask
                mask_new(mask_new_inner) = false;
                % Add ring to overall mask
                mask(:,:,:,in_mid_out+2) = mask(:,:,:,in_mid_out+2) | mask_new;
            end
        end
    
        % Draw circles
        im_R = im_circles(:,:,1);
        im_G = im_circles(:,:,2);
        im_B = im_circles(:,:,3);
        im_R(mask(:,:,1,in_mid_out+2)) = rgb(1);
        im_G(mask(:,:,2,in_mid_out+2)) = rgb(2);
        im_B(mask(:,:,3,in_mid_out+2)) = rgb(3);
        im_circles(:,:,1) = im_R;
        im_circles(:,:,2) = im_G;
        im_circles(:,:,3) = im_B;
    end
    
    mask_final = mask(:,:,:,2);

    %close(fig1);
end