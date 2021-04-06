function Img_out = mask_img(Img_raw,Img_mask,maskT,boxsize)
% read in image and mask, mask the image according to maskT (mask threshold
% spread by 1/4 box size

spacing = round(boxsize/4);
spacing2 = round(boxsize/8);
bin_mask = imbinarize(Img_mask,maskT);
se = strel('disk',spacing);  % disk with radius boxsize/4
bin_mask_dil = imdilate(bin_mask,se);

[nrows, ncols]=size(Img_mask);

mask_value=zeros(nrows,ncols);
for a=1:nrows
    for b=1:ncols
        if (bin_mask_dil(a,b)==1)
            marker=1;
            bound=spacing;
            while (marker==1)
                sum=0;
                counter=0;
                if (a>bound)
                    starta=a-bound;
                else
                    starta=1;
                end
                if (nrows>=a+bound)
                    enda=a+bound;
                else
                    enda=nrows;
                end
                if (b>bound)
                    startb=b-bound;
                else
                    startb=1;
                end
                if (ncols>=b+bound)
                    endb=b+bound;
                else
                    endb=ncols;
                end
                for c=starta:enda
                    for d=startb:endb
                        if (bin_mask_dil(c,d)==0)
                            sum=sum + Img_raw(c,d);
                            counter=counter + 1;
                        end
                    end
                end
                if (counter>10) % more than 10 pixels averaged
                    mask_value(a,b)=sum/counter;
                    marker=0;
                else
                    bound = bound + spacing2;
                end
            end
        end
    end
end
      
Img_out = size(nrows,ncols);
for a=1:nrows
    for b=1:ncols
        if (bin_mask_dil(a,b)==1)
            Img_out(a,b)=mask_value(a,b);
        else
            Img_out(a,b)=Img_raw(a,b);
        end
    end
 end