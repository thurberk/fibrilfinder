function WriteSTARfile3_1_f_keep(s, o, filename, keep)
% function to write Relion 3.1 data.star file 
% writing only the particle data marked with keep = 1
% KThurber 2020Apr27
% inputs s = structure with particle data
%	o = structure with optics group data
% 	filename = filename to write
%	keep = list of length s.totalparticles, with particles
% 		to keep marked by 1

% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

fileID = fopen(filename,'w');
% write out header text and variable names for optics group
if (o.nheader_txt>2)
	for a=1:(o.nheader_txt-2)
    		fprintf(fileID,'%s ', o.header_txt{1}{a});
	end
	fprintf(fileID,'\n');
	for a=(o.nheader_txt-1):o.nheader_txt
    		fprintf(fileID,'%s \n', o.header_txt{1}{a});
	end
else
	for a=1:o.nheader_txt
    		fprintf(fileID,'%s \n', o.header_txt{1}{a});
	end
end
for a=1:o.nvariables
    fprintf(fileID,'%s %s\n', o.var_names{a}{1}, strcat('#',num2str(a,'%d')));
end

% just to speed things up a bit, make simpler type variable 
for b=1:o.nvariables
    switch o.var_type(b)
        case "float"
            type(b)=0;
        case "gfloat"
            type(b)=1;
        case "int"
            type(b)=2;
        case "string"
            type(b)=3;
        otherwise
            error('Variable type not assigned');
    end
end

% write out to file
for a=1:o.totaloptics
    for b=1:o.nvariables
        switch type(b)
            case 0  % float
                fprintf(fileID,'%12.6f ',o.(o.var_names_m(b))(a));
            case 1  % gfloat
                fprintf(fileID,'%12.6g ',o.(o.var_names_m(b))(a));
            case 2  % int
                fprintf(fileID,'%12d ',o.(o.var_names_m(b))(a));
            case 3  % string
                fprintf(fileID,'%s ',o.(o.var_names_m(b)){a});
        end
    end
    fprintf(fileID,'\n');
end
fprintf(fileID,'\n');

% write out header text and variable names for particles
if (s.nheader_txt>2)
	for a=1:(s.nheader_txt-2)
    		fprintf(fileID,'%s ', s.header_txt{1}{a});
	end
	fprintf(fileID,'\n');
	for a=(s.nheader_txt-1):s.nheader_txt
    		fprintf(fileID,'%s \n', s.header_txt{1}{a});
	end
else
	for a=1:s.nheader_txt
    		fprintf(fileID,'%s \n', s.header_txt{1}{a});
	end
end
for a=1:s.nvariables
    fprintf(fileID,'%s %s\n', s.var_names{a}{1}, strcat('#',num2str(a,'%d')));
end

% just to speed things up a bit, make simpler type variable 
for b=1:s.nvariables
    switch s.var_type(b)
        case "float"
            type(b)=0;
        case "gfloat"
            type(b)=1;
        case "int"
            type(b)=2;
        case "string"
            type(b)=3;
        otherwise
            error('Variable type not assigned');
    end
end

% write out to file
for a=1:s.totalparticles
    if (keep(a)==1)
    for b=1:s.nvariables
        switch type(b)
            case 0  % float
                fprintf(fileID,'%12.6f ',s.(s.var_names_m(b))(a));
            case 1  % gfloat
                fprintf(fileID,'%12.6g ',s.(s.var_names_m(b))(a));
            case 2  % int
                fprintf(fileID,'%12d ',s.(s.var_names_m(b))(a));
            case 3  % string
                fprintf(fileID,'%s ',s.(s.var_names_m(b)){a});
        end
    end
    fprintf(fileID,'\n');
end
end
fprintf(fileID,'\n');

fclose(fileID);
