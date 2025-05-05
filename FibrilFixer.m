% remove_overlap.m
%  remove boxes which have center line of other segments 
%  passing through from Relion Extract job
%  after run have "particles_overlap_removed.star" file
% NOTE: must remove .Nodes/# in file filter to see file inside Relion
%
% KThurber 2020May22
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

clc;clear;close all;
tic

relionpath = uigetdir(path,'Select the relion directory');
[file,pth] = uigetfile('particles.star','Select the relion Extract particles file');
answer=inputdlg('How large a box size to use for overlap detection (in pixels)?'); 
range=0.5 * str2num(answer{1});
answer=inputdlg('Also use a mask for particle removal? 1=yes 0=no'); 
mask=str2num(answer{1});
if (mask==1)
    answer=inputdlg('What is the mask threshold?'); 
    maskT=str2num(answer{1});
    maskpath = uigetdir(path,'Select the masks directory');
elseif (mask~=0)
    error("mask answer not 1 or 0.");
end

file_out(:)='particles_overlap_removed.star'; % data.star file

filename=strcat(pth,file);
filename_out=strcat(pth,file_out);

[v, o]=ReadSTARfile3_1_f(filename);
[s, micrographs, mic_names]=SortSTARfile3_1_f(v);

% first determine segments and their length
segment = zeros(s.totalparticles,1);
countseg=1;
segID=s.rlnHelicalTubeID(1);
segimage(1,:)=s.rlnMicrographName{1};
seglength(1)=1;
helixstart(1)=1;
segment(1)=1;
for a=2:s.totalparticles
    if ((s.rlnHelicalTubeID(a)==segID) && (string(s.rlnMicrographName{a})==string(segimage(segment(a-1),:))))
        seglength(countseg)=seglength(countseg)+1;
        segment(a)=countseg;
    else
        countseg=countseg+1;
        helixstart(countseg)=a;
        segment(a)=countseg;
        seglength(countseg)=1;
        segID=s.rlnHelicalTubeID(a);
        segimage(countseg,:)=s.rlnMicrographName{a};
    end
end

% determine which particles are in each micrograph
mstart = zeros(micrographs,1);
mfinish = zeros(micrographs,1);
pointer=1;
for a=1:s.totalparticles
    if (string(s.rlnMicrographName{a})==string(mic_names(pointer)) && ...
            mstart(pointer)==0)
        mstart(pointer)=a;
        if (pointer>1)
            mfinish(pointer-1) = a-1;
        end
        if (pointer==micrographs)
            mfinish(pointer)=s.totalparticles;
        else
            pointer=pointer+1;
        end
    end
end

% determine which segments are in each micrograph
mfirstseg = zeros(micrographs,1);
mlastseg = zeros(micrographs,1);
pointer=1;
for k=1:countseg
     if (string(segimage(k,:))==string(mic_names(pointer)) && ...
            mfirstseg(pointer)==0)
        mfirstseg(pointer)=k;
        if (pointer>1)
            mlastseg(pointer-1) = k-1;
        end
        if (pointer==micrographs)
            mlastseg(pointer)=countseg;
        else
            pointer=pointer+1;
        end
     end
end

keep = ones(s.totalparticles,1);
for m=1:micrographs
    %m
    for k=mfirstseg(m):mlastseg(m)
        pt1 = [s.rlnCoordinateX(helixstart(k)) s.rlnCoordinateY(helixstart(k))];
        pt2 = [s.rlnCoordinateX(helixstart(k)+seglength(k)-1) s.rlnCoordinateY(helixstart(k)+seglength(k)-1)];
    	for a=mstart(m):mfinish(m)
            if (string(s.rlnMicrographName{a})==string(segimage(k,:)) && segment(a)~=k)
                pta = [(s.rlnCoordinateX(a)+range) (s.rlnCoordinateY(a)+range)];
                ptb = [(s.rlnCoordinateX(a)-range) (s.rlnCoordinateY(a)+range)];
                ptc = [(s.rlnCoordinateX(a)+range) (s.rlnCoordinateY(a)-range)];
                ptd = [(s.rlnCoordinateX(a)-range) (s.rlnCoordinateY(a)-range)];
                if (olap(pt1,pt2,pta,ptb))
                    keep(a)=0;
                elseif (olap(pt1,pt2,ptb,ptd))
                    keep(a)=0;
                elseif (olap(pt1,pt2,ptd,ptc))
                    keep(a)=0;
                elseif (olap(pt1,pt2,ptc,pta))
                    keep(a)=0;
                end
            end
        end
    end
end
  
if (mask==1)
for a=1:micrographs
    % just retain the micrograph file names, not directories or extension
        match = wildcardPattern + "/";
        miclist2{a} = erase(mic_names{a},match);
        %miclist2{a} = erase(miclist2{a},".mrc");
end
   
for m=1:micrographs
    %m
    mic2 = miclist2{m};
    [Img_mask,ms,mmi,mma,mav]=ReadMRC(strcat(maskpath,'/',mic2));
    [nx, ny] = size(Img_mask);
    bin_mask=imbinarize(Img_mask,maskT);
    for a=mstart(m):mfinish(m)
        xs=round(s.rlnCoordinateX(a)-range);
        xf=round(s.rlnCoordinateX(a)+range);
        ys=round(s.rlnCoordinateY(a)-range);
        yf=round(s.rlnCoordinateY(a)+range);
        if (xs>=1 && xf<=nx && ys>=1 && yf<=ny)
            if (sum(bin_mask(xs:xf,ys:yf),'all')~=0)
                keep(a)=0;
            end
        end
    end
end          
end    
  
% test plots on for first nfigures
nfigure=0;
for m=1:nfigure
    %m
    [Img,ms,mmi,mma,mav]=ReadMRC(strcat(relionpath,'/',mic_names{m}));
    % filter the image?  
    % gaussian style
    sigma = 25; % 15 and 2*dev, or 10 and 3*dev work well
    mdev = 2.0;  % color scale range in +- std deviations
    map2 = imgaussfilt(Img, sigma);
    dev = std(map2,0,'all');
    mmap2 = mean(map2,'all');
    
    figure;
    axis equal;
    colormap(gray);
    imagesc(map2, [mmap2-mdev*dev mmap2+mdev*dev]);
    title(mic_names{m});
    
    figure;
    axis equal;
    colormap(gray);
    imagesc(map2, [mmap2-mdev*dev mmap2+mdev*dev]);
    title(mic_names{m});
    hold on;
    for a=mstart(m):mfinish(m)
       if (keep(a)==0)
            scatter(s.rlnCoordinateY(a), s.rlnCoordinateX(a),50,'r');
       else
            scatter(s.rlnCoordinateY(a), s.rlnCoordinateX(a),50,'g');
       end
    end
    hold off;
end        

% now write out #_extract.star files for each micrograph
% first copy old #_extract.star files to extractold.star
for m=1:micrographs
    nameparts = split(s.rlnImageName(mstart(m)),'@');
    extractpart = erase(nameparts{2},'.mrcs');
    extractoldname = strcat(relionpath,'/',extractpart,'_extractold.star');
    extractname = strcat(relionpath,'/',extractpart,'_extract.star');
    movefile(extractname, extractoldname);
    vo.nheader_txt = s.nheader_txt;
    vo.nvariables = s.nvariables;
    vo.header_txt = s.header_txt;
    vo.var_names = s.var_names;
    vo.var_names_m = s.var_names_m;
    vo.var_type = s.var_type;
    counter=0;
    for a=mstart(m):mfinish(m)
        if (keep(a)==1)
    	    counter=counter+1;
            for c=1:s.nvariables
               vo.(s.var_names_m{c})(counter)=s.(s.var_names_m{c})(a);
            end
        end
    end
    vo.totalparticles = counter;
    WriteSTARfile_f(vo, extractname);
end

WriteSTARfile3_1_f_keep(s, o, filename_out, keep);
toc