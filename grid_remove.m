function [Img_out,mask] = grid_remove(Img_raw,grid_edge)

discard = 0;
X = imresize(Img_raw,(1/4));
%X=Img_raw;
nrows = size(X,1);
ncols = size(X,2);
nrows_raw = size(Img_raw,1);
ncols_raw = size(Img_raw,2);
% edge detection with threshold and gradient output
[BW1, threshout, GV, GH] = edge(X,'sobel', grid_edge);
% 0 default for contraction bias, 0 for smoothing
BW2 = activecontour(X,BW1,'Chan-Vese','SmoothFactor',0,'ContractionBias',0);

%figure;
%imagesc(BW1); 
%colormap(gray);
%axis equal;
%figure;
%imagesc(BW2); 
%colormap(gray);
%axis equal;

[regions, n] = bwlabel(BW2);
maxarea= 1;
% if too many regions, take largest as possible grid
if (n>1)
    stats = regionprops(regions,'Area');
    arealist = zeros(n,1);
    for a=1:n
        arealist(a) = stats(a).Area;
    end
    [~, maxarea] = max(arealist);
    for a=1:nrows
        for b=1:ncols
            if (regions(a,b)==maxarea)
                BW2(a,b)=1;
            else
                BW2(a,b)=0;
            end
        end
    end
end

%figure;
%imagesc(BW2); 
%colormap(gray);
%axis equal;

%if no BW2 result is on edge discard = 1
discard = 1;
for a=1:nrows
    if (BW2(a,1)==1 || BW2(a,ncols)==1)
        discard=0;
        break;
    end
end
if (discard==1)
    for b=2:(ncols-1)
        if (BW2(1,b)==1 || BW2(nrows,b)==1)
            discard=0;
            break;
        end
    end
end
        
% grid or not grid by comparing with edge detection
% for each pixel, is direction to each edge pixel in the same 
% or opposite to gradient of edge pixel 
% weighted by d^-2 to edge pixel

dirtotal = zeros(nrows,ncols);
grid = zeros(nrows,ncols);
if (discard~=1)
for a=1:nrows
    for b=1:ncols
        if (BW1(a,b) && BW2(a,b))
            for c=1:nrows
                for d=1:ncols
                    distw = ((a-c)*(a-c)+(b-d)*(b-d));
                    if (distw==0)
                        grid(c,d)=1;
                    else
                        dirtotal(c,d)= dirtotal(c,d) + ...
                            ((a-c)*GH(a,b) + (b-d)*GV(a,b))/(distw);
                    end
                end
            end
        end
    end
end
end
% remove pixels that are in grid region, or in an additional region not
% part of grid 
dirnorm=zeros(nrows,ncols);
for c=1:nrows
    for d=1:ncols
        if (dirtotal(c,d)<0 || grid(c,d)==1 || (regions(c,d)>0 && (regions(c,d)~=maxarea || discard==1)))
            dirnorm(c,d)=0;
        else
            dirnorm(c,d)=1;
        end
    end
end
% Erode mask with disk
radius = 2;
decomposition = 0;
se = strel('disk', radius, decomposition);
dirnorm = imerode(dirnorm, se);
% dirnorm has 0 for grid, 1 otherwise 
mask = imresize(dirnorm,[nrows_raw,ncols_raw]);
mask = imbinarize(mask);

%figure;
%imagesc(mask); 
%colormap(gray);
%axis equal;

% set removed pixels to average of pixels closest to them
Xmask = X;
for a=1:nrows
    for b=1:ncols
        if (dirnorm(a,b)==0)
            mindist=9999;
            for c=1:nrows
                for d=1:ncols
                    if (dirnorm(c,d)==1)
                        distsq = (a-c)*(a-c) + (b-d)*(b-d);
                        if (distsq<mindist)
                            mindist=distsq;
                            Xmask(a,b)=X(c,d);
                        end
                    end
                end
            end
        end
    end
end
 
count=0;
total=0;
 for a=1:nrows
     for b=1:ncols
         if (dirnorm(a,b)==0)
             count=count+1;
             total=total+Xmask(a,b);
         end
     end
 end
 avmask = total/count;
 for a=1:nrows
     for b=1:ncols
         if (dirnorm(a,b)==0)
            Xmask(a,b)=avmask;
         end
     end
 end
 Xmask_final=imresize(Xmask,[nrows_raw,ncols_raw]);
 
 for a=1:nrows_raw
        for b=1:ncols_raw
            if (mask(a,b)==0)
                Img_out(a,b)=Xmask_final(a,b);
            else
                Img_out(a,b)=Img_raw(a,b);
            end
        end
 end
 
% xxx 
% figure;
% hold on;
% set(gca,'YDir','reverse');
% axis equal;
% set(gca,'visible','off');
% imagesc(Img_out);
% colormap(gray);  
% hold off;
