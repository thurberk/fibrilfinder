% Enhancement of the 2D fibril structure
function Img_enhanced = fibril_vesselness2D(I, winSize)
%global winSize

% preprocess the input a little bit
Ip = single(I);
thr = prctile(Ip(Ip(:)>0),1) * 0.9;
Ip(Ip<=thr) = thr;
Ip = Ip - min(Ip(:));
Ip = Ip ./ max(Ip(:));    

% compute enhancement for two different tau values
% V1 = vesselness2D(Ip, 2.5:0.5:5.5, [1;1], 1, false);

% original
V1 = vesselness2D(Ip, (winSize/2)-1.5:0.5:(winSize/2)+1.5, [1;1], 1, false);
% V1 = vesselness2D_new(Ip, (winSize/2)-1.5:0.5:(winSize/2)+1.5, [1;1], 1, false);

Img_enhanced = V1;

