% Circles Drawing Function

function [im_circles, mask_final] = circle_draw(im, centers, radii, ring_width)
    
    mask = logical(zeros([size(im),3])); % preallocate
    
    im_circles = im;
    
    for in_mid_out = [0,1,-1]
        
        if (in_mid_out == 0)
            se = strel('disk', ring_width, 0);
            rgb = [0,0,255];
        else
            se = strel('disk', 1, 0);
            rgb = [255,255,255];
            if (in_mid_out == -1) % if it is the inner border ring
                ring_width = -ring_width + 1; % set the correct radius
            end
        end
    
        for i = 1:length(centers)
            roi = drawcircle('Center', centers(i,:), 'Radius', radii(i)+(ring_width/2));
        
            mask_new = roi.createMask();
            smallerMask = imerode(mask_new, se);
            % Erase it from original.
            mask_new = mask_new & ~smallerMask;
            % Or alternative way to do it that gives the same result:
            % mask(smallerMask) = false;
        
            % Add ring to mask
            mask(:,:,:,in_mid_out+2) = mask(:,:,:,in_mid_out+2) | mask_new;
        end
    
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
end