function [s, o]=ReadSTARfile3_1_f(filename)
% read Relion 3.1 data.star files 	KThurber 2020Apr27
% have two data structures 
% o contains optics group data
% s contains particles data
% variables must be in the lists of variable names by data type below
% if this program fails, probably because a new variable is being used, that is not in the lists 

% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

% have to scan all optics group variables, but not hit the particle variables 
optics_scan_n = 25;

string_vars = ["_rlnOpticsGroupName", "_rlnImageName", "_rlnMicrographName", ...
"_rlnMtfFileName", "_rlnCtfImage"];

int_vars = ["_rlnOpticsGroup", "_rlnImageSize", "_rlnImageDimensionality", ...
    "_rlnHelicalTubeID", "_rlnGroupNumber", "_rlnClassNumber", ...
    "_rlnNrOfSignificantSamples", "_rlnRandomSubset", "_rlnAreaId", ...
    "_rlnAnglePsiFlip"]; 

float_g_vars = ["_rlnMagnification", "_rlnMaxValueProbDistribution"]; 

float_vars = ["_rlnCoordinateX", "_rlnCoordinateY", "_rlnAngleRotPrior", ...
    "_rlnAngleTiltPrior", "_rlnAnglePsiPrior", "_rlnHelicalTrackLength", ... 
    "_rlnHelicalTrackLengthAngst", ...
    "_rlnAnglePsiFlipRatio", "_rlnVoltage", "_rlnDefocusU", "_rlnDefocusV", ...
    "_rlnDefocusAngle", "_rlnSphericalAberration", "_rlnCtfBfactor", ... 
    "_rlnCtfScalefactor", "_rlnPhaseShift", "_rlnAmplitudeContrast", ... 
    "_rlnDetectorPixelSize", "_rlnImagePixelSize", "_rlnCtfMaxResolution", ...
    "_rlnCtfFigureOfMerit", "_rlnAngleRot", "_rlnAngleTilt", "_rlnAnglePsi", ...
    "_rlnOriginX", "_rlnOriginXPrior", "_rlnOriginY", "_rlnOriginYPrior", ...
    "_rlnOriginXAngst", "_rlnOriginYAngst", ...
    "_rlnNormCorrection", "_rlnLogLikeliContribution", "_rlnHelicalTubePitch", ...
    "_rlnParticleSelectZScore", "_rlnAngleRotFlipRatio", "_rlnBeamTiltX", ...
    "_rlnBeamTiltY", "_rlnMicrographOriginalPixelSize", "_rlnMicrographPixelSize", ...
    "_rlnAnglePsiPriorStart", "_rlnCtfAstigmatism" ];

fileID = fopen(filename);
% start with optics data
% read in some of the file to test for header and variable info
% note 25 number below - need to scan all optics variables
% but not any variable for particle data set (with #)
for a=1:optics_scan_n
    text(a)=textscan(fileID,'%s',1);
end
% test for header, variable, and data info
first_var_num=0;
last_var_num=0;
for a=1:optics_scan_n
    if ((string(text{a})~="#") && (contains(text{a},"#")))
        last_var_num=a;
        if (first_var_num==0)
            first_var_num=a;
        end
    end
end
o.nheader_txt = int32(first_var_num - 2);
o.nvariables = int32((last_var_num - first_var_num + 2)/2);

fclose(fileID);
fileID = fopen(filename);
o.header_txt=textscan(fileID,'%s',o.nheader_txt);
for a=1:o.nvariables
    o.var_names(a)=textscan(fileID,'%s',1);
    dummy = textscan(fileID,'%s',1);
end
% strip starting _ from variable names for matlab
for a=1:o.nvariables
    temp=char(o.var_names{a});
    ltemp=length(temp);
    o.var_names_m(a)=string(temp(2:ltemp));
end
% assign variable type to each variable
for a=1:o.nvariables
    if (ismember(o.var_names{a},float_vars))
        o.var_type(a) = "float";
    else if (ismember(o.var_names{a},int_vars))
            o.var_type(a) = "int";
        else if (ismember(o.var_names{a},float_g_vars))
                o.var_type(a) = "gfloat";
            else if (ismember(o.var_names{a},string_vars))
                    o.var_type(a) = "string";
                else error('Variable %s not assigned a type',o.var_names{a}{1});
                end
            end
        end
    end
end

% create text read string
read_string="";
for a=1:o.nvariables
    switch o.var_type(a)
        case {"float", "gfloat"} 
            read_string=strcat(read_string, "%f ");
        case "int"
            read_string=strcat(read_string, "%d ");
        case "string"
            read_string=strcat(read_string, "%s ");
        otherwise
            error('Variable type not assigned');
    end
end

data = textscan(fileID,read_string);
read_string_o = read_string;
o.totaloptics=size(data{o.nvariables},1);

for a=1:o.nvariables
    o.(o.var_names_m(a))=data{a}(1:o.totaloptics);
end

% close, reopen, and dummy rescan to end of optics variables
fclose(fileID);
fileID = fopen(filename);
dummy = textscan(fileID,'%s',o.nheader_txt);
for a=1:o.nvariables
    dummy = textscan(fileID,'%s',1);
    dummy = textscan(fileID,'%s',1);
end
dummy = textscan(fileID,read_string,o.totaloptics);

%fclose(fileID);
% now start the particle data section
% read in some of the file to test for header and variable info
counter=0;
a=0;
while (counter<10)
%for a=1:200
    a=a+1;
    counter=counter+1;
    text(a)=textscan(fileID,'%s',1);
    if (contains(text{a},"_rln")) % test for variables, if so keep reading
        counter=0;
    end
end
readno=a;
% test for header, variable, and data info
first_var_num=0;
last_var_num=0;
for a=1:readno
%for a=1:200
    if ((string(text{a})~="#") && (contains(text{a},"#")))
        last_var_num=a;
        if (first_var_num==0)
            first_var_num=a;
        end
    end
end
s.nheader_txt = int32(first_var_num - 2);
s.nvariables = int32((last_var_num - first_var_num + 2)/2);

fclose(fileID);
fileID = fopen(filename);
% have to rescan the optics parts too
o.header_txt=textscan(fileID,'%s',o.nheader_txt);
for a=1:o.nvariables
    o.var_names(a)=textscan(fileID,'%s',1);
    dummy = textscan(fileID,'%s',1);
end
% strip starting _ from variable names for matlab
for a=1:o.nvariables
    temp=char(o.var_names{a});
    ltemp=length(temp);
    o.var_names_m(a)=string(temp(2:ltemp));
end
data_dummy = textscan(fileID,read_string_o,o.totaloptics);
% end preread of optics data
s.header_txt=textscan(fileID,'%s',s.nheader_txt);
for a=1:s.nvariables
    s.var_names(a)=textscan(fileID,'%s',1);
    dummy = textscan(fileID,'%s',1);
end
% strip starting _ from variable names for matlab
for a=1:s.nvariables
    temp=char(s.var_names{a});
    ltemp=length(temp);
    s.var_names_m(a)=string(temp(2:ltemp));
end
% assign variable type to each variable
for a=1:s.nvariables
    if (ismember(s.var_names{a},float_vars))
        s.var_type(a) = "float";
    else if (ismember(s.var_names{a},int_vars))
            s.var_type(a) = "int";
        else if (ismember(s.var_names{a},float_g_vars))
                s.var_type(a) = "gfloat";
            else if (ismember(s.var_names{a},string_vars))
                    s.var_type(a) = "string";
                else error('Variable %s not assigned a type',s.var_names{a}{1});
                end
            end
        end
    end
end

% create text read string
read_string="";
for a=1:s.nvariables
    switch s.var_type(a)
        case {"float", "gfloat"} 
            read_string=strcat(read_string, "%f ");
        case "int"
            read_string=strcat(read_string, "%d ");
        case "string"
            read_string=strcat(read_string, "%s ");
        otherwise
            error('Variable type not assigned');
    end
end

data = textscan(fileID,read_string);

for a=1:s.nvariables
    s.(s.var_names_m(a))=data{a}(:);
end
s.totalparticles=size(data{1},1);
   
fclose(fileID);




  
