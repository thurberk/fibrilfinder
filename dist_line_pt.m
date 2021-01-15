function output=dist_line_pt(p1,p2,x,y)
% distance from point x,y to line defined by p1 & p2

output=(abs((p2(2)-p1(2))*x - (p2(1)-p1(1))*y + p2(1)*p1(2) - ...
    p2(2)*p1(1)))/sqrt((p2(2)-p1(2))^2 + (p2(1)-p1(1))^2);

    