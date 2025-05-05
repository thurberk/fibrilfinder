function [Img_skel, lines] = create_lines_v4(Img,BW,eigv,width,T,min_ll,buffer,min_area)
% take processed image, contour regions (black/white) and ~fibril width
%
% 1. pick highest pt within largest region
% 2. create line in direction of eigenvector
% 3. edit line back from ends - if outside BW image remove
% 4. Remove all pts within width of line from Img and BW
% 5. repeat until next line too short to be useful

flag = 0;  % flag to stop, line was too short
%min_ll = 400/12;  % min length to keep
%buffer = 15; % avoid starting search from edges of image
lines = 0; % how many lines picked
[nrows, ncols] = size(Img);
BWmod = BW;
%BWmodt = BW;
Imgmod = Img;
%Imgmodt = Img;
distflag = zeros(nrows,1);
distflag2d = zeros(nrows,ncols);
distlp = zeros(nrows,ncols);
startpt_f = [0 0];

while (flag==0)
    % find largest region of contour
    [regions, n] = bwlabel(BWmod);
    % which regions are outside buffer
    region_out=zeros(n,1);
    for d=buffer:(nrows-buffer)
        for e=buffer:(ncols-buffer)
            if (regions(d,e)>0)
                region_out(regions(d,e))=1;
            end
        end
    end   
    if (min(region_out)==0)
        for a=1:n
            if (region_out(a)==0)
                BWmod(regions==a)=0;
            end
        end
    end
    [regions, n] = bwlabel(BWmod);
    if (n==0)
        flag=1;
        break;
    else
        if (n==1)
            maxarea=1;
            stats = regionprops(regions,'Area');
            maxareavalue = stats(1).Area;
        else
            stats = regionprops(regions,'Area');
            arealist = zeros(n,1);
            for a=1:n
                arealist(a) = stats(a).Area;
            end
            [maxareavalue, maxarea] = max(arealist);
        end
    end
    if (maxareavalue<min_area)   % was 350
        flag=1;
        break;
    end
    Imgmax=zeros(nrows,ncols);
    for d=buffer:(nrows-buffer)
        for e=buffer:(ncols-buffer)
            if (regions(d,e)==maxarea)
                Imgmax(d,e)=Imgmod(d,e);
            end
        end
    end     
    [h, temp] = max(Imgmax);
    [p, b] = max(h);
    if (p<T)
        flag=1;
        break;
    end
    a = temp(b);
    k = 1;%eigv(a,b,1);
    l = 0;%eigv(a,b,2);
    linepts = zeros(2*max(nrows,ncols),2);  % pts on the line
    im_pts = zeros(nrows,ncols);        % the 2d image of the the line pts
    linepts_f = zeros(2*max(nrows,ncols),2);  % best pts on the line
    im_pts_f = zeros(nrows,ncols);        % best the 2d image of the the line pts
    maxpts = 0;                         % the best total pts
    if ((k==0) && (l==0))
        error('eigenvector zero');
    else
        % define all the points on the line createMask(ROI,I)
        %  h = images.roi.Line(gca,'Position',[100 150;400 650]);
        % define end points
        % note currently inefficient & duplication start and end pts are
        % just first and last pts of linepts?
        % how fine to check 0.5 degrees?  +-5 degrees? 21 steps? 
        step = 1;
        range = 10;
        ag = eigv(a,b);
        %text(b, a, sprintf('%0.0f', ag), ...
        %                'FontSize',18, 'Color', 'red');
        for g=(-1*range):step:range
            %g
            cg = cosd(g + ag);
            sg = sind(g + ag);
            kt = cg*k - sg*l;
            lt = sg*k + cg*l;
            % simplify later case options by setting k>=0
            if (kt<0)
                kt = -1*kt;
                lt = -1*lt;
            end
            if (kt==0)
                startpt = [a 1];
                endpt = [a ncols];
                npts_begin = b; % note including pt a,b in begin pts as pt b
                for d=1:b
                    linepts_b(d,:)=[a d];
                    im_pts(a,d)=1;
                end
                npts_end = ncols-b;
                for d=1:npts_end
                    linepts_a(d,:)=[a b+d];
                    im_pts(a,b+d)=1;
                end
            else
                if (lt==0)
                    startpt = [1 b];
                    endpt = [nrows b];
                    npts_begin = a; % note including pt a,b in begin pts as pt a
                    for d=1:a
                        linepts_b(d,:)=[d b];
                        im_pts(d,b)=1;
                    end
                    npts_end = nrows-a;
                    for d=1:npts_end
                        linepts_a(d,:)=[a+d b];
                        im_pts(a+d,b)=1;
                    end
                else
                    if (lt>0)  % k>0 already set above
                        if (((a-1)/kt) <= ((b-1)/lt))
                            startpt = [1 round(b - lt*((a-1)/kt))];
                        else
                            startpt = [round(a - kt*((b-1)/lt)) 1];
                        end
                        if (((nrows-a)/kt) <= ((ncols-b)/lt))
                            endpt = [nrows round(b + lt*((nrows-a)/kt))];
                        else
                            endpt = [round(a + kt*((ncols-b)/lt)) ncols];
                        end
                        npts_begin=0;
                        npts_end=0;
                        ptflag=0; % have we reached the initial pt yet?
                        for d=1:nrows
                            for e=1:ncols
                                if (dist_line_pt(startpt,endpt,d,e)<=0.5)
                                    if (ptflag==0)
                                        npts_begin=npts_begin+1;
                                        linepts_b(npts_begin,:)=[d e];
                                    else
                                        npts_end=npts_end+1;
                                        linepts_a(npts_end,:)=[d e];
                                    end
                                    im_pts(d,e)=1;
                                    if (d==a && e==b)
                                        ptflag=1;
                                    end
                                end
                            end
                        end                     
                    else% l<0 
                        if (((a-1)/kt) <= abs((ncols-b)/lt))
                            startpt = [1 round(b - lt*((a-1)/kt))];
                        else
                            startpt = [round(a + kt*((ncols-b)/lt)) ncols];
                        end
                        if (((nrows-a)/kt) <= abs((b-1)/lt))
                            endpt = [nrows round(b + lt*((nrows-a)/kt))];
                        else
                            endpt = [round(a - kt*((b-1)/lt)) 1];
                        end
                        npts_begin=0;
                        npts_end=0;
                        ptflag=0; % have we reached the initial pt yet?
                        for d=1:nrows
                            for e=1:ncols
                                if (dist_line_pt(startpt,endpt,d,e)<=0.5)
                                    if (ptflag==0)
                                        npts_begin=npts_begin+1;
                                        linepts_b(npts_begin,:)=[d e];
                                    else
                                        npts_end=npts_end+1;
                                        linepts_a(npts_end,:)=[d e];
                                    end
                                    im_pts(d,e)=1;
                                    if (d==a && e==b)
                                        ptflag=1;
                                    end
                                end
                            end
                        end          
                    end
                end
            end
%             for d=1:npts
%                 if (BWmod(linepts(d,1), linepts(d,2))==1)
%                     startpt = linepts(d,:);
%                     break;
%                 end
%             end
%             for d=1:npts
%                 if (BWmod(linepts(npts-(d-1),1), linepts(npts-(d-1),2))==1)
%                     endpt = linepts(npts-(d-1),:);
%                     break;
%                 end
%             end
            for d=1:nrows
                distflag(d)=0;
                for e=1:ncols
                    distflag2d(d,e)=0;
                    distlp(d,e) = dist_line_pt(startpt,endpt,d,e);
                    if (distlp(d,e)<= 0.25*width)
                        distflag(d)=1;
                        distflag2d(d,e)=1;
                    end
                end
            end
            startflag=0;
            endflag=0;
            for d=1:npts_begin
                if (BWmod(linepts_b(d,1), linepts_b(d,2))==1 && startflag==0)
                    startflag=d;
                end
                if (startflag~=0)
                    break;
                end
            end
            for d=1:npts_end
                if (BWmod(linepts_a(npts_end-(d-1),1), linepts_a(npts_end-(d-1),2))==1 ...
                        && endflag==0)
                    endflag=(npts_end-(d-1));
                end
                if (endflag~=0)
                    break;
                end
            end
            if (endflag==0)
                endflag=1;
            end
            %npts = endflag - startflag + 1;
            %linepts_new = linepts(startflag:endflag,:);
            totalp = zeros(npts_begin,1);
            totalq = zeros(endflag,1);
            for d=1:nrows
                if (distflag(d)==1)
                    for e=1:ncols
                        if (distflag2d(d,e)==1)
                            mindistsq = 9e10;
                            for p=npts_begin:-2:startflag
                            %for p=startflag:2:npts_begin
                                pt = linepts_b(p,:);
                                distsq = (pt(1)-d)^2 + (pt(2)-e)^2;
                                if (distsq<mindistsq)
                                    mindistsq = distsq;
                                    closestflag=1;
                                    closestflag2=p;
                                end
                            end
                            for q=1:2:endflag
                                pt = linepts_a(q,:);
                                distsq = (pt(1)-d)^2 + (pt(2)-e)^2;
                                if (distsq<mindistsq)
                                    mindistsq = distsq;
                                    closestflag=2;
                                    closestflag2=q;
                                end
                            end
                            if (sqrt(mindistsq)<= 0.25*width)
                                imagept_temp = Imgmod(d,e);
                                if (imagept_temp~=T)
                                    ptvalue = (imagept_temp - T);
                                else
                                    ptvalue =  -0.05;  % small penalty
                                end
                                if (closestflag==1)
                                    totalp(closestflag2) = totalp(closestflag2) + ptvalue;
                                else
                                    totalq(closestflag2) = totalq(closestflag2) + ptvalue;
                                end
                            end
                        end
                    end
                end
            end   
            totalptsp=0;
            for p=npts_begin:-2:startflag
                totalptsp = totalptsp + totalp(p);
                totalptsq=0;
                for q=1:2:endflag
                    totalptsq = totalptsq + totalq(q);
                    totalpts = totalptsp + totalptsq;
                    if (totalpts>maxpts)
                        maxpts=totalpts;
                        startpt_f(:)=linepts_b(p,:);
                        endpt_f(:)=linepts_a(q,:);
                        Img_skel(lines+1,:,:)=[startpt_f; endpt_f];
                    end
                end
            end
        end
        if (startpt_f(1)==0 && startpt_f(2)==0)
            line_dist=0;
        else
            line_dist = sqrt((startpt_f(1)-endpt_f(1))^2 + (startpt_f(2)-endpt_f(2))^2);
        end
        if (line_dist>min_ll && maxpts>0)
            lines=lines+1;
        end
        BWmod(a,b)=0;
        Imgmod(a,b)=T;
        if (maxpts~=0)
            for d=1:nrows
                for e=1:ncols
                    if (dist_line_pt(startpt_f,endpt_f,d,e)<= 0.75*width && ...
                        line_dist >= sqrt((startpt_f(1)-d)^2 + (startpt_f(2)-e)^2) && ...
                        line_dist >= sqrt((endpt_f(1)-d)^2 + (endpt_f(2)-e)^2))
                            BWmod(d,e)=0;
                            Imgmod(d,e)=T;
                    end
                end
            end
        end
        %figure;
        %imagesc(BWmod);
        %title('BWmod');
        %hold on;
        %drawnow
        %figure;
        %imagesc(Imgmod);
        %title('Imgmod');
    end
end

%hold off;
%figure;
%imagesc(BWmod);
%title('BWmod');
%figure;
%imagesc(Imgmod);
%title('Imgmod');

if (lines==0)
    Img_skel=0;
end
            
        
        
    
                
                
   