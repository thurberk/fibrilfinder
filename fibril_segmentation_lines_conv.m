% Segmentation of fibril

function [Img_skel, lines, Img_smooth2, Img_bw_final] = fibril_segmentation_lines_conv(Img, winSize, convlength, ignore_sm, boxsize, resize_factor, T)
%global Img_bw_final winSize dir

%%%%%%%%%%%%%%%%%%%%%%% Pre-processing %%%%%%%%%%%%%%%%%%%%%%%%%%

%Img_smooth = Img;
Img_smooth = imgaussfilt(Img,2); % was 5 with 6x reduction
%figure,imagesc(Img_smooth);
%title('smooth');

%filtered = Img_smooth;
% noise reduction
%winsize = 4*floor(winSize/4) + 1; % half of fibril width (in pixel), can only be 4*k+1, k = 1,2,...,3..
filtered = Kuwahara(Img_smooth,5);%winsize);%winsize will be 5, 9 too big!
%figure,imagesc(filtered);
%title('Kuwahara');

% bottom-hat filtering: subtract the background to correct illumination
se = strel('disk',25);  % was 50
Img_rmbg = 1-imbothat(filtered,se);
% xxx 
% figure;
% hold on;
% set(gca,'YDir','reverse');
% axis equal;
% set(gca,'visible','off');
% imagesc(Img_rmbg);
% colormap(gray);
%title('bottom-hat');
%saveas(gcf,strcat(dir,'/bottomhat.fig'));
%saveas(gcf,strcat(dir,'/bottomhat.png'));
hold off;
Img_smooth2 = Img_rmbg;
% Img_smooth2 = imgaussfilt(Img_rmbg,3);
% figure,imagesc(Img_smooth2);
% title('smooth2');
% enhancement of the tubulous structure
%[Img_enhanced, eigv] = fibril_vesselness2D_ev(Img_smooth2);
[Img_enhanced] = fibril_vesselness2D(Img_smooth2,winSize);
% xxx 
% figure;
% hold on;
% set(gca,'YDir','reverse');
% axis equal;
% set(gca,'visible','off');
% imagesc(Img_enhanced);
% colormap(gray);
%title('vesselness');
%saveas(gcf,strcat(dir,'/vesselness.fig'));
%saveas(gcf,strcat(dir,'/vesselness.png'));
hold off;

% convolve image with thin rectangle (linear object)
% input variables image, rectangle width, length, degree step for rectangle
% angle
% output new image and best angle for each pixel
% if you want this alone 1-Img_smooth2
% this alone will tend to go past the ends
[Img_enhanced2, convd] = conv_ev(Img_enhanced,winSize/4,convlength,2);
% xxx 
% figure;
% hold on;
% set(gca,'YDir','reverse');
% axis equal;
% set(gca,'visible','off');
% imagesc(Img_enhanced2);
% colormap(gray);
%title('convolution');
%saveas(gcf,strcat(dir,'/convolution.fig'));
%saveas(gcf,strcat(dir,'/convolution.png'));
%drawnow;
hold off;

Img_smooth_edge = Img_enhanced2;
%Img_smooth_edge = imgaussfilt(Img_enhanced2,2);  % was 3
%figure,imagesc(Img_smooth_edge);
%title('smooth_edge');

%%%%%%%%%%%%%%%%%%%%%%% Segmentation %%%%%%%%%%%%%%%%%%%%%%%%%%

%T = graythresh(Img_smooth_edge);
%T = 0.60;
BW_edge = imbinarize(Img_smooth_edge,T);

% remove tiny objects induced by noise
se = strel('disk',1); 
Img_close = imopen(BW_edge,se);
%figure,imagesc(Img_close);
%title('close');
Img_bw_final = bwareaopen(Img_close,ignore_sm);  % now 200 was 400
% xxx 
% figure;
% hold on;
% set(gca,'YDir','reverse');
% axis equal;
% set(gca,'visible','off');
% imagesc(Img_bw_final);
% colormap(gray);
%title('bw final');
%saveas(gcf,strcat(dir,'/bw_final.fig'));
%saveas(gcf,strcat(dir,'/bw_final.png'));
%drawnow;
hold off;

%%%%%%%%%%%%%%%%%%%%%%% Post-processing %%%%%%%%%%%%%%%%%%%%%%%%%%

% create lines
min_ll = boxsize / resize_factor;
buffer = round(boxsize / (2*resize_factor));
min_area = 1.5*ignore_sm;
[Img_skel, lines] = create_lines_v4(Img_smooth_edge,Img_bw_final,convd,1.3*winSize,T,min_ll,buffer,min_area);

