function [s, micrographs, mic_names]=SortSTARfile3_1_f(v)
% function to take unsorted Relion particle data structure and sort it 
% KThurber 2020Apr27
% takes in structure and outputs sorted structure
% sorts on MicrographName, then HelicalTubeID, then HelicalTrackLengthAngst
% also determines how many micrographs there are, and their names

% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

for a=1:v.totalparticles
    temp(a,:) = v.rlnMicrographName{a};
end

[~, i] = sortrows([temp v.rlnHelicalTubeID v.rlnHelicalTrackLengthAngst]);

s = v;

for a=1:v.totalparticles 
    for b=1:v.nvariables
        s.(v.var_names_m{b})(a)=v.(v.var_names_m{b})(i(a));
    end
end

% determine how many micrographs there are, and their names
mic_names=string.empty;
micrographs=0;
for a=1:s.totalparticles
    [mem, mic(a)] = ismember(s.rlnMicrographName{a},mic_names);
    if (~mem)
        micrographs=micrographs+1;
        mic_names = [mic_names, s.rlnMicrographName{a}];
        mic(a) = micrographs;
    end
end
