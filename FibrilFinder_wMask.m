%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   FibrilFinder.m
%	automatic picking of amyloid fibrils from cryo-EM images
%	output designed for RELION 3.1 or 4 or 5
%	
%   Author: Kent Thurber
%   Version: 1  xx date
%   References:  xx
%		abeta40 xx
%
%   For input parameters, see input_test text file or parameter setting below
%
%   Based on:  
%    Fibril tool: automated analysis of fibril morphology	
%      Author: Yi Yin, INRIA Paris (current affiliation: Uni. Oxford)
%      Version: April2020
%      References: 
%      Yi Yin et al., "Automated Quantification of Amyloid Fibrils 
%      Morphological Features by Image Processing Techniques",IEEE ISBI, 2019
%   
%      Joan Torrent et al., "Pressure Reveals Unique Conformational Features 
%      in Prion Protein Fibril Diversity", Scientific Reports, 9(1), 2019.
%  
%   Also includes:  
%    Kuwahara filter, Luca Balbi, 2007
% 	References:
% 	http://www.ph.tn.tudelft.nl/DIPlib/docs/FIP.pdf 
% 	http://www.incx.nec.co.jp/imap-vision/library/wouter/kuwahara.html
%
%    "Vesselness" filter (enhance features roughly based on width, more
%	specifically based on eigenvalues of 2D Hessian matrix (second derivatives))
% 	Function written by T. Jerman, University of Ljubljana (October 2014)
% 	Based on code by D. Kroon, University of Twente (May 2009)
% 	also, S.-F. Yang and C.-H. Cheng, �Fast computation of Hessian-based
% 	enhancement filters for medical images,� Comput. Meth. Prog. Bio., vol.
% 	116, no. 3, pp. 215�225, 2014.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
clear;
close all;
%profile off;
%profile on;
%tStart=tic;

% miclist only used if chosen
%miclist = {'20190730_02172.mrc'; '20190730_00932.mrc'; '20190730_00721.mrc'};% ...
%      '20190730_00776.mrc'; '20190730_00932.mrc'; '20190730_01076.mrc'; ...
%      '20190730_01247.mrc'; '20190730_01361.mrc'; '20190730_01557.mrc'; ...
%      '20190730_01751.mrc'; '20190730_01858.mrc'; '20190730_02041.mrc'; ...
%      '20190730_02172.mrc'};
miclist = {'20220425_00004.mrc'; '20220425_00956.mrc'; '20220425_01629.mrc'; ...
    '20220425_02000.mrc'; '20220425_02247.mrc'; '20220425_02397.mrc'};
%    '20190204_00925.mrc'; '20190204_01034.mrc'; '20190204_01113.mrc'; ...
%    '20190206_00029.mrc'; '20190206_00143.mrc'; '20190206_00243.mrc'; ...
%    '20190206_00312.mrc'; '20190206_00328.mrc'; '20190206_00490.mrc'; ...
%    '20190206_00570.mrc'; '20190206_00637.mrc'}; 
%relionpath = 
%listpath = '/reliondir/MotionCorr/job010/micrographs';
%listoutpath = '/reliondir/MatlabPick/2020aug26';

answer=inputdlg('Note: if desired, start a Relion manual pick job, create masks with Micrograph Cleaner & know how many computer cores you have before starting this program (enter anything)'); 

% parameter setting
% parameters currently in pixels (before resize)
%Img_resolution = 1; % set image resolution (nm/pixel)
%resize_factor = 12;  % how much to rescale image at beginning
%boxsize = 400;  % expected pixels for Relion boxes/particles
%winSize = 90; % pixels slightly smaller than fibril width 
%convlength = 800; % pixels length for thin rectangle convolution 
%grid_edge = 0.05; % threshold for sobel edge detection of grid
%ignore_sm = 144*200;  % area size in pixels to ignore (not try to fit fibril segment)
%T = 0.6;            % threshold for binary image
resize_factor = 0;
boxsize = 0;
winSize = 0;
convlength = 0;
grid_edge = 0;
ignore_sm = 0;
T = 0;
maskT = 0;
winDelta = 0;	% "vesselness" checked for winSize +- winDelta

[file,path] = uigetfile('','Select the input parameters file');
fileID = fopen(strcat(path,file));
% %*[^\n] means skip the rest of line, allows for comments
% 1 means read one line only
temp = textscan(fileID, 'resize_factor = %f %*[^\n]', 1);
resize_factor = temp{1};
temp = textscan(fileID, 'boxsize = %f %*[^\n]', 1);
boxsize = temp{1};
temp = textscan(fileID, 'winSize = %f %*[^\n]', 1);
winSize = temp{1};
temp = textscan(fileID, 'convlength = %f %*[^\n]', 1);
convlength = temp{1};
temp = textscan(fileID, 'grid_edge = %f %*[^\n]', 1);
grid_edge = temp{1};
temp = textscan(fileID, 'ignore_sm = %f %*[^\n]', 1);
ignore_sm = temp{1};
temp = textscan(fileID, 'T = %f %*[^\n]', 1);
T = temp{1};
temp = textscan(fileID, 'maskT = %f %*[^\n]', 1);
maskT = temp{1};
temp = textscan(fileID, 'winDelta = %f %*[^\n]', 1);
winDelta = temp{1};
fclose(fileID);

if ((resize_factor==0) || (boxsize==0) || (winSize==0) || (convlength==0) || (grid_edge==0) || (ignore_sm==0) || (T==0) || (maskT==0) || (winDelta==0))
    error ('Input parameter read problem.  At least one value still 0');
end

answer=inputdlg('Read micrographs from micrographs star file (enter 0) or list in Matlab (enter 1) or from directory (enter 2)'); 
listm=str2num(answer{1});
if (listm~=0 && listm~=1 && listm~=2)
    error('entry not 0 or 1 or 2');
end
answer=inputdlg('Do you want to use a mask (such as from Micrograph Cleaner)? 1=yes, 0=no'); 
maskin=str2num(answer{1});
if (maskin~=0 && maskin~=1)
    error('entry not 0 or 1');
elseif (maskin==1)
    maskpath = uigetdir(path,'Select the masks directory');
end     
answer=inputdlg('Do you want FibrilFinder to try to remove grid regions from images? 1=yes, 0=no. Probably not useful if using masks'); 
gridrem=str2num(answer{1});
if (gridrem~=0 && gridrem~=1)
    error('entry not 0 or 1');
end   
answer=inputdlg('Do you want just Relion file output (enter 0) or both Relion & Matlab output (enter 1) or Relion, Matlab, & figures (enter 2) or masked figure only (enter -1)'); 
mout=str2num(answer{1});
if (mout~=0 && mout~=1 && mout~=2 && mout~=-1)
    error('entry not 0 or 1 or 2 or -1');
else 
    switch listm
    case 2
        [file,relionpath] = uigetfile(path,'Select the micrographs','MultiSelect','on');
        pathout = uigetdir(path,'Select the output directory');
        miclist = file';
        mics = length(miclist);
    case 1
        mics = length(miclist);
        %inputpath = listpath;
        relionpath = listpath;
        pathout = listoutpath;
        mkdir(pathout);
    case 0
        relionpath = uigetdir(path,'Select the relion directory');
        pathout = uigetdir(relionpath,'Select the manual pick micrographs directory');
        %pathout = strcat(pathout,'/Micrographs');
        %mkdir(pathout);
        [file,path] = uigetfile(relionpath,'Select the micrographs star file');
        [s, o] = ReadSTARfile3_1_f(strcat(path,file));
        %s = ReadSTARfile_f(strcat(path,file));
        mics = s.totalparticles; % here this is the number of micrographs
        miclist = s.rlnMicrographName;
        prompt = strcat(num2str(mics),' micrographs listed.  Analyze how many?');
        answer=inputdlg(prompt); 
        mics = str2num(answer{1});
    end
end

for a=1:mics
    % just retain the micrograph file names, not directories or extension
    if (listm==0)
        match = wildcardPattern + "/";
        %miclist2{a} = eraseBetween(miclist{a},"MotionCorr","KT-2021-03-25/",'Boundaries','inclusive');
        miclist2{a} = erase(miclist{a},match);
        miclist2{a} = erase(miclist2{a},".mrc");
    else
        miclist2{a} = erase(miclist{a},".mrc");
    end
end

answer=inputdlg('How many computer cores do you have?'); 
cores=str2num(answer{1});
tStart=tic;

% two similar loops, just one for single core, and one for parallel
% computing
if (cores==1)
    for m=1:mics
        mic = miclist{m};
        mic2 = miclist2{m};
        relion_file = strcat(pathout,'/',mic2,'_manualpick.star');
        output_file = strcat(pathout,'/',mic2,'.mat');

        if (~isfile(relion_file)) %only do if doesn't already exist
          [Img_raw,s,hdr,extraHeader]=ReadMRC(strcat(relionpath,'/',mic));
          if (maskin==1)
            [Img_mask,ms,mhdr,mextraHeader]=ReadMRC(strcat(maskpath,'/',mic2,'.mrc'));
            %Img_mask=Img_mask+maskadd;
          else 
            Img_mask=0;
          end
          if (gridrem==0)
            image_proc_v3_nogrid(Img_raw,resize_factor,grid_edge,winSize,convlength,ignore_sm,boxsize,T,maskT,relion_file,output_file,mout,maskin,Img_mask,winDelta);
          else
            image_proc_v3(Img_raw,resize_factor,grid_edge,winSize,convlength,ignore_sm,boxsize,T,maskT,relion_file,output_file,mout,maskin,Img_mask,winDelta);
	  end
        end
    end
else
    % actually may need to edit environment>parallel>preferences to get 
    % number of workers, & use Cluster profile manager
    try parpool(cores) 
    end
    parfor m=1:mics
        mic = miclist{m};
        mic2 = miclist2{m};
        relion_file = strcat(pathout,'/',mic2,'_manualpick.star');
        output_file = strcat(pathout,'/',mic2,'.mat');
        
        if (~isfile(relion_file)) %only do if doesn't already exist
            [Img_raw,s,hdr,extraHeader]=ReadMRC(strcat(relionpath,'/',mic));
            if (maskin==1)
                [Img_mask,ms,mhdr,mextraHeader]=ReadMRC(strcat(maskpath,'/',mic2,'.mrc'));
                %Img_mask=Img_mask+maskadd;
            else 
                Img_mask=0;
            end
            if (gridrem==0)
              image_proc_v3_nogrid(Img_raw,resize_factor,grid_edge,winSize,convlength,ignore_sm,boxsize,T,maskT,relion_file,output_file,mout,maskin,Img_mask,winDelta);
            else
              image_proc_v3(Img_raw,resize_factor,grid_edge,winSize,convlength,ignore_sm,boxsize,T,maskT,relion_file,output_file,mout,maskin,Img_mask,winDelta);
	    end
        end    
    end
end
%% runtime
%toc
tElapsed = toc(tStart);
t_text = 'The running time is %4.2f seconds \n';
fprintf(t_text,tElapsed);
%profsave;
