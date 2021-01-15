function [s]=ReadSTARfile_f(filename)
% function to read data.star file with arbitrary variables, up to ~100
% outputs structure s with data variables in it, and header info
% variables must be in the lists of variable types

string_vars = ["_rlnImageName", "_rlnMicrographName", "_rlnCtfImage"];

int_vars = ["_rlnHelicalTubeID", "_rlnGroupNumber", "_rlnClassNumber", ...
    "_rlnNrOfSignificantSamples", "_rlnRandomSubset", "_rlnAreaId", ...
    "_rlnAnglePsiFlip"]; 

float_g_vars = ["_rlnMagnification", "_rlnMaxValueProbDistribution"]; 

float_vars = ["_rlnCoordinateX", "_rlnCoordinateY", "_rlnAngleRotPrior", ...
    "_rlnAngleTiltPrior", "_rlnAnglePsiPrior", "_rlnHelicalTrackLength", ... 
    "_rlnAnglePsiFlipRatio", "_rlnVoltage", "_rlnDefocusU", "_rlnDefocusV", ...
    "_rlnDefocusAngle", "_rlnSphericalAberration", "_rlnCtfBfactor", ... 
    "_rlnCtfScalefactor", "_rlnPhaseShift", "_rlnAmplitudeContrast", ... 
    "_rlnDetectorPixelSize", "_rlnCtfMaxResolution", ...
    "_rlnCtfFigureOfMerit", "_rlnAngleRot", "_rlnAngleTilt", "_rlnAnglePsi", ...
    "_rlnOriginX", "_rlnOriginXPrior", "_rlnOriginY", "_rlnOriginYPrior", ...
    "_rlnNormCorrection", "_rlnLogLikeliContribution", "_rlnHelicalTubePitch", ...
    "_rlnParticleSelectZScore", "_rlnAngleRotFlipRatio", "_rlnBeamTiltX", ...
    "_rlnBeamTiltY", "_rlnCtfAstigmatism"];

fileID = fopen(filename);
% read in some of the file to test for header and variable info
for a=1:200
    text(a)=textscan(fileID,'%s',1);
end
% test for header, variable, and data info
first_var_num=0;
last_var_num=0;
for a=1:200
    if ((a~=1) && (contains(text{a},"#")))
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
s.totalparticles=size(s.(s.var_names_m(1)),1);
   
fclose(fileID);

% counter=1;
% while (~feof(fileID))  % not end of file
%     for a=1:s.nvariables
%         switch s.var_type(a)
%             case "float"
%                 s.(s.var_names_m(a))(counter)=textscan(fileID, '%f ',1);
%             case "int"
%                 s.(s.var_names_m(a))(counter)=textscan(fileID, '%d ',1);
%             case "string"
%                 s.(s.var_names_m(a))(counter)=textscan(fileID, '%s ',1);
%             otherwise
%                 error('Variable type not assigned');
%         end
%     end
%     counter=counter+1;
% end
%s.totalparticles=counter;



  
