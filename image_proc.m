function image_proc(Img_raw,resize_factor,grid_edge,winSize,convlength,ignore_sm,boxsize,T,relion_file,output_file,mout)
% container function for image processing

orig_size = size(Img_raw);
% reduce the image size
% improves signal to noise and speeds calculations
%resize_factor = 12;
%Img_resize = impyramid(Img_original, 'reduce');
%Img_resize1 = imresize(Img_raw, 1/3);
%Img_intensity = mat2gray(Img_resize1);
%Img_resize = imresize(Img_intensity, 3/resize_factor);
Img_resize = imresize(Img_raw, 1/resize_factor);
%figure
%imagesc(Img_resize);
%saveas(gcf,strcat(dir,'/resize.fig'));
%saveas(gcf,strcat(dir,'/resize.png'));
% convert matrix to an intensity image
%Img_original = mat2gray(Img_resize);

% adjust the value because of image reduction
%Img_resize_resolution = resize_factor * Img_resolution;
winSize = winSize / resize_factor;
convlength = convlength / resize_factor;
ignore_sm = ignore_sm / (resize_factor*resize_factor);

%%%%%%%%%%%%%%%%%%%%%%%%%%%  Main function  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Remove grid regions, output new image and mask
[Img_remove, grid_mask] = grid_remove(Img_resize,grid_edge);
% convert matrix to an intensity image
Img_intensity = mat2gray(Img_remove);
%Img_intensity = Img_remove;

% I: fibril segmentation and centerline detection
[Img_skel, lines, Img_smooth2, Img_bw_final] = ...
    fibril_segmentation_lines_conv(Img_intensity, winSize, convlength, ignore_sm, boxsize, resize_factor, T);

Img_skel_rescale = shift_ends(Img_skel,lines,boxsize,resize_factor,orig_size);

%%%%%%%%%%%%%%%%%%%%%%%%  Display results  %%%%%%%%%%%%%%%%%%%%%%%%%%% 

%Show_fibril_contour(Img_resize);

if (mout>1)
    figure;
    hold on;
    set(gca,'YDir','reverse');
    axis equal;
    set(gca,'visible','off');
    imagesc(Img_resize);
    colormap(gray);
    saveas(gcf,strcat(erase(output_file,".mat"),"resize.fig"));
    saveas(gcf,strcat(erase(output_file,".mat"),"resize.png"));
    for k=1:lines
        plot(Img_skel(k,:,2),Img_skel(k,:,1),'--*','LineWidth',1,'MarkerSize',10);
    end
    title('final fibrils');
    saveas(gcf,strcat(erase(output_file,".mat"),"fib.fig"));
    saveas(gcf,strcat(erase(output_file,".mat"),"fib.png"));
    hold off;
end 

%%%%%%%%%%%%%%%%%%%%%%%%%  Save results  %%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

if (mout>0)
    save(output_file,'Img_skel_rescale','Img_skel','lines','Img_smooth2','Img_bw_final','Img_resize');
end
output_relion(lines,Img_skel_rescale,relion_file);