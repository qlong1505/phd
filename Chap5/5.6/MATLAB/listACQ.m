function [outputArg1] = listACQ(folder)
%LISTACQ Summary of this function goes here
%   Detailed explanation goes here

a = ls(folder);
[m n]=size(a)
n=[];
for i=1:m
    k = strfind(a(i,:),'csv');
    b = convertCharsToStrings(a(i,1:k+2));
    b = convertCharsToStrings(folder)+"/"+b;
    if contains(b,"acq")
        n = [n;b];
    end
end
outputArg1 = n;
clear a m n b i k
end

