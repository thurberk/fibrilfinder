function output_relion(lines,Img_skel,relion_file)
%global dir
% output the line segments in relion v3.1 format

%real_resize = resize_factor*3;
%mkdir(strcat(dir,'/relionout'));
fileID = fopen(relion_file,'w');

% header text
fprintf(fileID,'\n# version 30001\n\n');
fprintf(fileID,'data_\n\n');
fprintf(fileID,'loop_\n');
fprintf(fileID,'_rlnCoordinateX #1\n');
fprintf(fileID,'_rlnCoordinateY #2\n');
fprintf(fileID,'_rlnClassNumber #3\n');
fprintf(fileID,'_rlnAnglePsi #4\n');
fprintf(fileID,'_rlnAutopickFigureOfMerit #5\n');
% end of header
for a=1:lines   % start and end points have own output line
    for b=1:2
        fprintf(fileID,'%12.6f %12.6f %12d %12.6f %12.6f\n', Img_skel(a,b,1), ...
            Img_skel(a,b,2), 2, -999, -999);
    end
end
fprintf(fileID,'\n');

fclose(fileID);
