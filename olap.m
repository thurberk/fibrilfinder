function output = olap(pt1, pt2, pta, ptb)
% olap
%  function do the line segments pt1 to pt2 & pta to ptb
%  cross, not worrying about collinear segments
%
% KThurber 2020May22
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

% Find the four orientations needed for general and 
% special cases 
o1 = orientation(pt1, pt2, pta); 
o2 = orientation(pt1, pt2, ptb); 
o3 = orientation(pta, ptb, pt1); 
o4 = orientation(pta, ptb, pt2); 
  
% General case 
if (o1 ~= o2 && o3 ~= o4) 
	output = true; 
else output = false;
end


%% To find orientation of ordered triplet (p, q, r). 
%  The function returns following values 
%  0 --> p, q and r are colinear 
%  1 --> Clockwise 
%  2 --> Counterclockwise 
function output = orientation(p, q, r) 
%
% See https://www.geeksforgeeks.org/orientation-3-ordered-points/ 
% for details of below formula. 
val = (q(2) - p(2)) * (r(1) - q(1)) - (q(1) - p(1)) * (r(2) - q(2)); 
  
if (val == 0) 
	output = 0;  %% colinear
end 
if (val > 0)
	output = 1;
else
	output = 2;
end  
		 %% clock or counterclock wise 
