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

[file,pth] = uigetfile('particles.star','Select the relion Extract particles file');
answer=inputdlg('How large a box size to use for overlap detection (in pixels)?'); 
range=0.5 * str2num(answer{1});

%pth(:)='/reliondir/Extract/job203/'; % relion path
%file(:)='particles_37removed_forregrelion.star'; % 2d data.star file
file_out(:)='particles_overlap_removed.star'; % data.star file

%range = 150;  % the box used to test for overlap
		% will be +- range = 2*range on a side

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
    m
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
            
WriteSTARfile3_1_f_keep(s, o, filename_out, keep);
toc