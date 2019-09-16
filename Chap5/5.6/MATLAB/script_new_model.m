%
%24/12/2018 add this new script.
% Simulate model from Chapter 13, page 552, 
Ts = 1/120
z = tf('z',Ts);
Gc = 150*(z-0.72)/(z+0.4);
%Gc = 90*(z-0.72)/z;
% Gc = 90*(z-0.72)/z;
Gp = 0.00133*(z+0.75)/(z*(z-1)*(z-0.72));
cl = feedback(Gc*Gp,1);
cl2 = feedback(cl,1)
% subplot(2,1,1)
step(cl)
% subplot(2,1,2)
% impulse(cl)
set(gca,'FontSize',30)
set(findall(gca, 'Type', 'Line'),'LineWidth',2);
xlabel('Time','FontSize',30)
ylabel('Amplitude','FontSize',30)
title('STEP RESPONSE','FontSize',30)
[A,B,C,D] = ssdata(cl);

% rlocus(cl)
% axis([-1.5 1.5 -1 1])
%% 25/12/2018 Run simulation multiple time and save to response mat file

%set runtime for simulink model
runtime = 0.2;

%set number of runs
n_run = 10000;

%load clk source from hardware
file ='clk_BB_1_120s_norm20181225221250.mat'; 
load(file);

%split clock source into different pattern enough for runtime.
clock_array_len = length(clk);

tic
pattern_index = find(clk(:,1)<runtime);
pattern = clk(pattern_index,:);

% pre-create memory to storage data.
sim('Tape_motion_dynamic');% run the first time to check the size of response data
if n_run*2>=clock_array_len
    Q2 ='CLOCK DATA IS TOO SHORT, PRESS CTRL+C NOW !';
    y =input(Q2);
else
    response = zeros(length(ScopeData1.time),n_run+1,'double');    
end


% first column is time axes
response(:,1)=ScopeData1.time;

for i=1:n_run
    
    %return each index pattern which enough for runtime.
    pattern = clk(pattern_index,:);
    
    %set 0 for the start value of time axe 
    pattern(:,1)=pattern(:,1)-pattern(1,1);
    
    %call simulink
    sim('Tape_motion_dynamic');
    %plot(ScopeData1.time,ScopeData1.signals.values);
    
    response(:,i+1) = ScopeData1.signals.values;
    
    %increase index to 2, we start from rising edge
    pattern_index = pattern_index +2;
end
save(strcat('response_',file),'response');
toc
%% test draw from matrix file
% load data from random jitter
file ='response_clk_Opi_1_120s_norm20181225230330.mat' ;
load(file);
% draw output response - RANDOM JITTER
tic
hold on
count=0
for i=2:5%length(response(1,:))
    
    plot(response(:,1),response(:,i));
    count = count +1
end
% format plot
xlabel('Time (s)')
% ylabel('Speed (rpm)')
title('ENVELOP OF OUTPUT RESPONSE')
% legend('NO JITTER','JITTER');%,'JITTER 20%','JITTER 30%','JITTER 40%','Location','southeast');
% set(gca,'FontSize',30)
%set(findall(gca, 'Type', 'Line'),'LineWidth',3);
hold off
grid on
% set(gcf, 'Position', [100, 100, 1280, 720])
%axis([0 inf 0 1.3])
clear response

formatOut = 'yyyymmddHHMMSS';
print(file(1:(end-4)),'-dpng')
toc
%% find stepinfo and save to csv file.
MEAN=[];
STD=[];

n=1;
data_risetime = [];
data_settletime = [];
for file_list=[...
        "response_clk_BB_1_120s_high20181225215231.mat" ...
        "response_clk_BB_1_120s_norm20181225221250.mat" ...
        "response_clk_BB_1_120s_low20181225225238.mat" ...
        "response_clk_Opi_1_120_high20181225233058.mat" ...
        "response_clk_Opi_1_120s_norm20181225230330.mat"...
        "response_clk_Opi_1_120_low20181225230436.mat"...
        ]
    file =convertStringsToChars(file_list)
    header = "RiseTime,SettlingMax,SettlingMin,SettlingTime,Peak,PeakTime,Overshoot,Undershoot\n";
    fileID = fopen(strcat(file(1:(end-4)),'.csv'),'w');
    fprintf(fileID,header);
    fclose(fileID);
    clear fileID;
    clear header;
    pause(2);
    tic
    load(file);
    toc
    pause(2);
    tic
    data_size = size(response,2)-1;
    
    RiseTime=zeros(1,data_size);
    SettlingTime=zeros(1,data_size);
    SettlingMin=zeros(1,data_size);
    SettlingMax=zeros(1,data_size);
    Overshoot=zeros(1,data_size);
    Undershoot=zeros(1,data_size);
    Peak=zeros(1,data_size);
    PeakTime=zeros(1,data_size);   
    for i=1:data_size
        s= stepinfo(response(:,i+1),response(:,1));   
        RiseTime(i) = s.RiseTime;
        SettlingMax(i)=s.SettlingMax;
        SettlingMin(i)=s.SettlingMin;
        SettlingTime(i)=s.SettlingTime;
        Peak(i)=s.Peak;
        PeakTime(i)=s.PeakTime;
        Overshoot(i)=s.Overshoot;
        Undershoot(i)=s.Undershoot;
    end
    toc
    data_settletime = [data_settletime,SettlingTime'];
    data_risetime = [data_risetime,RiseTime'];
    formatOut = 'yyyymmddHHMMSS';
     %csvwrite(strcat(file(1:(end-4)),'.csv'),overshoots);
%     dlmwrite(strcat(file(1:(end-4)),'.csv'),[RiseTime',SettlingMax'...
%    SettlingMin', SettlingTime',Peak',PeakTime',Overshoot',Undershoot']...
%     ,'delimiter',',','-append');
dlmwrite(strcat(file(1:(end-4)),'.csv'),[RiseTime',SettlingMax'...
   SettlingMin', SettlingTime',Peak',PeakTime',Overshoot',Undershoot']...
    ,'delimiter',',','-append');

    subplot(3,4,n);
    histogram(SettlingTime,40);
    set(gca,'YScale','log')
    set(gca,'FontSize',14)
    title(strcat('SettlingTime_',file(1:(end-18))),'Interpreter','none');
    n= n+1;
    subplot(3,4,n);
    histogram(RiseTime,40);
    set(gca,'YScale','log')
    set(gca,'FontSize',14)
    title(strcat('RiseTime_',file(1:(end-18))),'Interpreter','none');
    n = n+1;
    %MEAN=[MEAN,mean(overshoots)];
    %STD=[STD,std(overshoots)];
end
% figure;
% subplot(2,1,1);
% boxplot(data_risetime,'Labels',{'BeagleBone - high priority','BeagleBone - low priority',...
%     'BeagleBone - default priority','Orange Pi - high priority','Orange Pi - low priority',...
%     'Orange Pi - normal priority'},'orientation', 'horizontal');
% title('Risetime');
% set(gca,'FontSize',20)
% subplot(2,1,2);
% boxplot(data_settletime,'Labels',{'BeagleBone - high priority','BeagleBone - low priority',...
%     'BeagleBone - default priority','Orange Pi - high priority','Orange Pi - low priority',...
%     'Orange Pi - normal priority'},'orientation', 'horizontal');title('Settletime');
% set(gca,'FontSize',20)
clear RiseTime SettlingMax SettlingMin SettlingTime Peak PeakTime Overshoot Undershoot
clear s data_size i file file_list
clear MEAN STD
clear response
clear n
%% boxplot data - re-run 12/06/2019 - horizontal - logarit scale
subplot(2,1,1);
temp = data_risetime
indices = find(temp(:,:)<0.03);
% [I,J] = ind2sub(size(temp),indices);
temp(indices)=NaN;

% boxplot(data_risetime,'Labels',{'BeagleBone - high priority','BeagleBone - default priority',...
%     'BeagleBone - low priority','Orange Pi - high priority','Orange Pi - default priority',...
%     'Orange Pi - low priority'},'orientation', 'horizontal');

boxplot(temp,'Labels',{'BeagleBone - high priority','BeagleBone - default priority',...
    'BeagleBone - low priority','Orange Pi - high priority','Orange Pi - default priority',...
    'Orange Pi - low priority'},'orientation', 'horizontal');

%title('Risetime');
xlabel('Time (s)');
set(gca,'FontSize',20)

 set(gca,'FontSize',20,'xscale','log') % test log scale
 grid on
subplot(2,1,2);
boxplot(data_settletime,'Labels',{'BeagleBone - high priority','BeagleBone - default priority',...
    'BeagleBone - low priority','Orange Pi - high priority','Orange Pi - default priority',...
    'Orange Pi - low priority'},'orientation', 'horizontal');
%title('Settletime');
xlabel('Time (s)');
set(gca,'FontSize',20)
set(gca,'FontSize',20,'xscale','log')
 grid on
 %% boxplot data - re-run 12/06/2019 - vertical
subplot(1,2,1);
temp = data_risetime
indices = find(temp(:,:)<0.03);
% [I,J] = ind2sub(size(temp),indices);
temp(indices)=NaN;

% boxplot(data_risetime,'Labels',{'BeagleBone - high priority','BeagleBone - default priority',...
%     'BeagleBone - low priority','Orange Pi - high priority','Orange Pi - default priority',...
%     'Orange Pi - low priority'},'orientation', 'horizontal');
colors = [1 0 0; 0 1 0; 0 0 1; 0 1 1; 0 0 0; 1 0 1;];
legend_label = {'a.BeagleBone - high priority','b.BeagleBone - default priority',...
    'c.BeagleBone - low priority','d.Orange Pi - high priority','e.Orange Pi - default priority',...
    'f.Orange Pi - low priority'}
box_var={'BB_H','BB_D','BB_L','OPi_H','OPi_D','OPi_L'}
box_var={'a','b','c','d','e','f'}
boxplot(temp,'Labels',box_var,'orientation', 'vertical','Colors',colors);
% hLegend = legend(findall(gca,'Tag','Box'), fliplr(legend_label));
%title('Risetime');
xlabel('Time (s)');
set(gca,'FontSize',20)

 set(gca,'FontSize',20,'yscale','log') % test log scale
 grid on
subplot(1,2,2);
% boxplot(data_settletime,'Labels',{'BeagleBone - high priority','BeagleBone - default priority',...
%     'BeagleBone - low priority','Orange Pi - high priority','Orange Pi - default priority',...
%     'Orange Pi - low priority'},'orientation', 'vertical');
%title('Settletime');
boxplot(data_settletime,'Labels',box_var,'orientation', 'vertical','Colors',colors);
xlabel('Time (s)');
set(gca,'FontSize',20)
set(gca,'FontSize',20,'yscale','log')

hLegend = legend(findall(gca,'Tag','Box'), fliplr(legend_label));
 grid on

 
 
 
 %% get ideal data
runtime = 0.2;
sim('Tape_motion_dynamic_ideal');
plot(ScopeData1.time, ScopeData1.signals.values);
s=stepinfo(ScopeData1.signals.values,ScopeData1.time);

%% create pattern test
a= 0:10;
a = power(2,a);
a = 1./a
a1  =a/2
a2 = a/2
b  = zeros(1,length(a)*2)
c = b;
b(1:2:end)=a1;
b(2:2:end)=a2;
b = cumsum(b)
c(1:2:end)=1
clk = [[0;b'],[0;c']]
sim('pattern_test');
    header = "Times,Data\n";
    fileID = fopen('pattern_test.csv','w');
    fprintf(fileID,header);
    fclose(fileID);
    clear fileID;
    clear header;
dlmwrite('pattern_test.csv',[ScopeData.time,ScopeData.signals.values]...
    ,'delimiter',',','-append');
%%
%histfit(data_settletime(:,1),50,'normal')
%pd=fitdist(data_settletime(:,1),'beta')
h = histogram(data_settletime(:,2));
y = h.BinCounts;
x = conv(h.BinEdges, [0.5 0.5], 'valid')
plot(x,y);
clk = [x',y'];
sim('pattern_test');
[ScopeData.time,ScopeData.signals.values]