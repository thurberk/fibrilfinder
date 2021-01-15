function Img_skel_final = shift_ends(Img_skel,lines,boxsize,resize_factor,orig_size)
% calculate line segment ends on full scale image
% shift line segment ends in by 0.5 real boxsize

%global dir

Img_skel_final = Img_skel;
for a=1:lines   
    for b=1:2
        Img_skel_final(a,b,2) = resize_factor*(Img_skel(a,b,2) - 0.5);
        Img_skel_final(a,b,1) = resize_factor*(Img_skel(a,b,1) - 0.5);
    end
    dy = Img_skel_final(a,1,2) - Img_skel_final(a,2,2);
    dx = Img_skel_final(a,1,1) - Img_skel_final(a,2,1);
    dl = sqrt(dx*dx + dy*dy);
    dld = 0.5*boxsize/dl;
    Img_skel_final(a,1,2) = round(Img_skel_final(a,1,2) - dld*dy);
    Img_skel_final(a,2,2) = round(Img_skel_final(a,2,2) + dld*dy);
    Img_skel_final(a,1,1) = round(Img_skel_final(a,1,1) - dld*dx);
    Img_skel_final(a,2,1) = round(Img_skel_final(a,2,1) + dld*dx);
    for b=1:2
        % sanity check
        if (Img_skel_final(a,b,2)<1 || Img_skel_final(a,b,2)>orig_size(2) || ...
            Img_skel_final(a,b,1)<1 || Img_skel_final(a,b,1)>orig_size(1))
            error(strcat('final end points outside of image bound ',dir));
        end
    end
end

