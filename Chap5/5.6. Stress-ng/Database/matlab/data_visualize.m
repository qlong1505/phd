%% only work from Matlab2016a and later

path = '../Database/';

Matlabversion = version('-release');
Matlabversion = str2double(Matlabversion(1:4));
if Matlabversion<=2015
    filelist = dir(strcat(path,'acq*'));
    filelist = struct2cell(filelist);
    filelist = filelist(1,:)';
else 
    filelist = ls(strcat(path,'acq*'));
end
    


% dont use these command anymore as recorded data format has been standardized
%     opts = detectImportOptions(strcat(path,filelist(3,:)));
%     opts.VariableNamesLine = 2;
%     opts.DataLine=3;
%     opts.VariableDescriptionsLine =2;
%     opts.VariableNames = {'second','Volt'};
hold on
figure_quantity=10;
n=2;
m = fix((figure_quantity+1)/n);

% Beagle bone diffrent stresses at priority -19 (highest priority)
select = [35 36 40 44 48];

% Beagle bone diffrent stresses at priority 0
select = [18 19 23 27 31];

for i=1:5%length(filelist)
    subplot(n,m,i);
    filelist(select(i),:)
    
    %obsolete function
    %Data = readtable(strcat(path,filelist(i,:)),opts);
    
    %use this one
    if Matlabversion >2015
        Data = readtable(strcat(path,filelist(select(i),:)));
    else
        Data = readtable(strcat(path,filelist{select(i)}));
    end
    %old one
    %offset_time = Data.second(1)*ones(1,length(Data.second));
    offset_time = Data.Time_s_(1)*ones(1,length(Data.Time_s_));
    
    a=Data.Channel1_V_;
    a(a<=3)=0;
    a(a>3)=1;
    plot(Data.Time_s_-offset_time',a);
    xlim([0 1])
    title(filelist(select(i),:),'Interpreter', 'none');
    
    b = [Data.Time_s_-offset_time',a];
    tmp = diff(a);
    k = find(tmp);
    tmp = b(k+1);
    pattern=diff(tmp);
    subplot(n,m,i+5);
    hist(pattern);
%     plot(Data.second,Data.Volt)
end
hold off
% figure;
% hist(pattern);
%%


%%
% opts = detectImportOptions(strcat(path,filelist(1,:)))
opts.VariableNamesLine = 2;
opts.DataLine=3;
opts.VariableDescriptionsLine =2;
opts.VariableNames = {'second','Volt'};
Data = readtable(strcat(path,'scope_153'),opts);
plot(Data.second,Data.Volt)
%% try dlmread() for matlab 2015b
filelist = dir(strcat(path,'scope*'));
filelist = struct2cell(filelist);
filelist = filelist(1,:)';
% Data = csvread(strcat(path,'scope_0.csv'));

Data = dlmread((strcat(path,filelist{1})),',',2,0);
plot(Data(:,1),Data(:,2));
%% manually draw
path = '../DataBase/';
filelist = 'scope_0.csv'
opts = detectImportOptions(strcat(path,filelist));
opts.VariableNamesLine = 2;
opts.DataLine=3;
opts.VariableDescriptionsLine =2;
opts.VariableNames = {'second','Volt'};
% hold on
figure_quantity=10;
    filelist;
    Data = readtable(strcat(path,filelist),opts);
    offset_time = Data.second(1)*ones(1,length(Data.second));
    a=Data.Volt;
    a(a<=1)=0;
    a(a>=3)=1;
    plot(Data.second-offset_time',a);
    axis([0 1 -0.5 1.5])
    title(filelist,'Interpreter', 'none');
    b = [Data.second-offset_time',a];
    tmp = diff(a);
    k = find(tmp);
    tmp = b(k+1);
    diff(tmp)
%     plot(Data.second,Data.Volt)

