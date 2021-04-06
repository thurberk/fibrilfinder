function image_proc_v2(Img_raw,resize_factor,grid_edge,winSize,convlength,ignore_sm,boxsize,T,maskT,relion_file,output_file,mout,maskin,Img_mask)
% container function for image processing

orig_size = size(Img_raw);

Img_resize = imresize(Img_raw, double(1)/double(resize_factor));
mask_resize = imresize(Img_mask, double(1)/double(resize_factor));
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
    
    figure;
    hold on;
    set(gca,'YDir','reverse');
    axis equal;
    set(gca,'visible','off');
    imagesc(mask_resize);
    colormap(gray);
    saveas(gcf,strcat(erase(output_file,".mat"),"mask.fig"));
    saveas(gcf,strcat(erase(output_file,".mat"),"mask.png"));
end

% adjust the values because of image reduction
%Img_resize_resolution = resize_factor * Img_resolution;
winSize = winSize / resize_factor;
convlength = convlength / resize_factor;
ignore_sm = ignore_sm / (resize_factor*resize_factor);

%%%%%%%%%%%%%%%%%%%%%%%%%%%  Main function  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% remove bad regions identified in mask
if (maskin==1)
    Img_mask_out = mask_img(Img_resize,mask_resize,maskT,boxsize/resize_factor);
else
    Img_mask_out = Img_resize;
end
if (mout>1)
    figure;
    hold on;
    set(gca,'YDir','reverse');
    axis equal;
    set(gca,'visible','off');
    imagesc(Img_mask_out);
    colormap(gray);
    saveas(gcf,strcat(erase(output_file,".mat"),"masked.fig"));
    saveas(gcf,strcat(erase(output_file,".mat"),"masked.png"));
end
% Remove grid regions, output new image and mask
[Img_remove, grid_mask] = grid_remove(Img_mask_out,grid_edge);
if (mout>1)
    figure;
    hold on;
    set(gca,'YDir','reverse');
    axis equal;
    set(gca,'visible','off');
    imagesc(Img_remove);
    colormap(gray);
    saveas(gcf,strcat(erase(output_file,".mat"),"grid_rem.fig"));
    saveas(gcf,strcat(erase(output_file,".mat"),"grid_rem.png"));
end
% convert matrix to an intensity image
Img_intensity = mat2gray(Img_remove);
%Img_intensity = Img_remove;

% I: fibril segmentation and centerline detection
[Img_skel, lines, Img_smooth2, Img_bw_final] = ...
    fibril_segmentation_lines_conv(Img_intensity, winSize, convlength, ignore_sm, boxsize, resize_factor, T, output_file, mout);

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