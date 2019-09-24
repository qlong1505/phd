function [data] = process(V,T)
%PROCESS Summary of this function goes here
% %   Detailed explanation goes here
%     V(V<1.5)=0;
%     V(V>=1.5)=1;
%     V = diff(V);
%     T = T(find(V==1));
%     T = diff(T);
%     data = T(2:end-1);
%     
    V = diff(V);
    V(V==-1)=1;
    T = T(find(V==1));
    T = diff(T);
    data = T(2:end-1);
end

