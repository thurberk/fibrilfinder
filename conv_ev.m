function [Img_conv, angles] = conv_ev(I, width, length, step)
% convolve image with line kernels

[n1,n2]=size(I);
angles = zeros(n1,n2);
% create line kernels
line_no = round(180/step);
angle = zeros(line_no,1);
%disk = strel('disk',round(width));
rl = round(length);
rw = round(width);
lmax = max(rl,rw);
nhood_temp = zeros(lmax);
nhood = zeros(line_no,lmax,lmax);
for a=1:lmax
    if (abs(a-(lmax+1)/2)<=(rl/2))
        for b=1:lmax
            if (abs(b-(lmax+1)/2)<=(rw/2))
                nhood_temp(a,b) = 1;
            end
        end
    end
end

%se = zeros(line_no,lmax,lmax);
for k=1:line_no
    angle(k) = (k-1)*step;
    nhood(k,:,:) = imrotate(nhood_temp, angle(k), 'crop');
    %se(k,:) = strel(round(nhood)); 
end

for k=1:line_no
    se2 = squeeze(nhood(k,:,:));
    % 2d convolution but fix assumption of zeros at edges
    response = conv2(I,se2,'same') ./ conv2(ones(size(I)),se2,'same');
    %max response over multiple convolutions
    if(k==1)
        Img_conv = response;
        for a=1:n1
            for b=1:n2
                angles(a,b) = angle(k);
            end
        end
    else    
        for a=1:n1
            for b=1:n2
                temp = Img_conv(a,b);
                temp2 = response(a,b);
                [temp3, vindex]= max([temp temp2]);
                Img_conv(a,b) = temp3;
                if (vindex==1)
                    angles(a,b) = angles(a,b);
                else
                    angles(a,b) = angle(k);
                end
            end
        end
    end   
    clear response 
end

Img_conv = Img_conv ./ max(Img_conv(:)); % should not be really needed   
Img_conv(Img_conv < 1e-2) = 0;
           
        
