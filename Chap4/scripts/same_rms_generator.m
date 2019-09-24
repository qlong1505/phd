% RMS from bruteforce is about 0.098
% --> must generate Gaussian and Uniform at the same RMS and run again. 
% how to do it. Gaussian call normrnd(mean,RMS,row,column)
%Uniform, base on RMS = sqrt(1/12 (b-a)^2). Find a and b then generate
%them.
%% Gaussian generator
MEAN = 0.4;
RMS = 0.098;
data_size = 10000;
array = ones(10,data_size);
for i=1:data_size
rng('shuffle');
array(:,i) = RMS.*randn(10,1) + MEAN;
% x = RMS.*randn(10,1) + MEAN;
% [mean(x) std(x) var(x) rms(MEAN-x)]
end
formatOut = 'yyyymmddHHMMSS';
save(strcat('gaussian_clock_',num2str(data_size),'_',datestr(now,formatOut)),'array');
%% uniform - update 30/10/2018
%Uniform, base on RMS = sqrt(1/12 (b-a)^2). Find a and b then generate
rng('shuffle');
MEAN = 0.4;
RMS = 0.062;
data_size_array=[100 1000 10000 3^10];
formatOut = 'yyyymmddHHMMSS';
for k=4:4
    data_size = data_size_array(k);
    array = zeros(10,data_size);
    % if a=-b check equation --> RMS = sqrt(b^2/3)
    b = sqrt(3*RMS^2);
    for i=1:data_size
    rng('shuffle');
    % x = rand(10,1)*b*2-b+0.4;
    % [mean(x) std(x) var(x) rms(MEAN-x)]
    array(:,i) = rand(10,1)*b*2-b+0.4;
    end
    
    save(strcat('uniform_clock_',num2str(data_size),'_',datestr(now,formatOut)),'array');
end
%%
RMS = 0.098;
MEAN = 0.4;
x = RMS.*randn(50000,1) + MEAN;
[mean(x) std(x) var(x) rms(MEAN-x)]
%% test truncated gaussian data
RMS = 0.098;
MEAN =0.4;
l = ones(10,1)*(-MEAN*0.3)/RMS;
u = ones(10,1)*(MEAN*0.3)/RMS;
% x=trandn(l,u);
% Z=x*RMS+MEAN;
% hist(Z);
% RMS=rms(Z)
data_size_array=[3^10];
formatOut = 'yyyymmddHHMMSS';
for k=1:3
    tic
    data_size = data_size_array(k);
    array = zeros(10,data_size);
    for j=1:data_size
        rng('shuffle');
        x=trandn(l,u);
        array(:,j)=x*RMS+MEAN;
    end
    toc
save(strcat('gaussian_clock_',num2str(data_size),'_',datestr(now,formatOut)),'array');
% rms(rms(array()))
end

%%
b = sqrt(3*RMS^2);
Z = rand(10000,1)*2*b-b;
rms(Z)
%% brute-force data
data_size_array=[100 1000 10000];
formatOut = 'yyyymmddHHMMSS';
for k=1:3
    tic
    data_size = data_size_array(k);
    array = zeros(10,data_size);
    for j=1:data_size
        for i=1:10
            rng('shuffle');
            x=rand;
            if x<2/15
              array(i,j)=0.28;
            elseif x>13/15
              array(i,j)=0.52;
            else
              array(i,j)=0.4;
            end
        end
    end
    toc
save(strcat('bruteforce_clock_',num2str(data_size),'_',datestr(now,formatOut)),'array');
% rms(rms(array()))
end

%%
x = [
    1 8
    2 2
    3 3
    4 4
    2 1
    3 3
    3 3
    ];
[u,I,J] = unique(x, 'rows', 'first')
hasDuplicates = size(u,1) < size(x,1)
ixDupRows = setdiff(1:size(x,1), I)
dupRowValues = x(ixDupRows,:)