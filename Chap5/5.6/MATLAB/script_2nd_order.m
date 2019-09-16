%% s domain
P = tf([5],[1 4 8]); %S-domain plant
C = tf([0.5 2.5],[1 2 0]); %S-domain controller
[Kp,Ki,Kd,Tf] = piddata(C);
cl = feedback(P*C,1);
step(cl);

%% test with euler forward
[Kp,Ki,Kd,Tf] = piddata(C);
Ts = 0.4;
dC = pid(Kp,Ki,Kd,Tf,Ts);
zpk(dC)
dP = c2d(P,T);
cl = feedback(dC*dP,1);
step(cl,12)

%% discretize - step response with different sampling time
hold on
for T = [0.05 0.2 0.4 0.001]
%use forward Euler method    
    dC = pid(Kp,Ki,Kd,Tf,T);

%use zoh method
    %dC = c2d(C,T,'zoh'); % 
dP = c2d(P,T);
cl = feedback(dC*dP,1);
step(cl,12);
end
grid on

%% discretize - step response with difference c2d conversion method
hold on
for method = ["zoh" "tustin"]
    for T = [0.4]
        method = convertStringsToChars(method);
        dC = c2d(C,T,method);
        dP = c2d(P,T);
        cl = feedback(dC*dP,1);
        step(cl,12);
    end
end
grid on
%% Z-controller testing on simulink
tic
T=0.001;
% clock generator
L = 20000
pulse = ones(L,1);
pulse(2:2:end)= zeros(L/2,1);
clk = 0:T/2:(L-1)*T/2;
clk=clk';
clk=[clk,pulse]
%----------------------
method = 'zoh';
%dC = c2d(C,T,method);
dC = pid(Kp,Ki,Kd,Tf,T);
[sA,sB,sC,sD,T]=ssdata(dC);
dP = c2d(P,T);
sim('digital_control');
stairs(ScopeData1.time,ScopeData1.signals(1).values);
toc
%% Test with jitter
jitter_amplitude = 20;
Sample_period = T;
jitter_generator;
%----------------------
method = 'zoh';
dC = c2d(C,T,method);
[sA,sB,sC,sD,T]=ssdata(dC);
dP = c2d(P,T);
sim('digital_control');
stairs(ScopeData1.time,ScopeData1.signals.values);

%% envelopes test 
hold on
for i=1:1:20
    clk=jitter(500,T,30,0);
    sim('digital_control');
    stairs(ScopeData1.time,ScopeData1.signals(1).values);
end
hold off

%% Uniform/Gausian distribution random jitter
%update 26/06/2018: removeing plot part. Instead, save in two variable
%rand_response and rand_control
% hold on
tic
T=0.4;
method = 'zoh';
dC = c2d(C,T,method);
[sA,sB,sC,sD,T]=ssdata(dC);
iteration = 3^10+1;
% jitter_amplitude = 20;
% Sample_period = T;
% rand_response = [];
% rand_control = [];
rand_response = zeros(4802,iteration+1,'double');
rand_control = zeros(4802,iteration+1,'double');
random_type = "gaussian";
for i=1:iteration
    clk =jitter(500,T,30,random_type); 
    clear ScopeData1
    sim('digital_control');
%     rand_response = [rand_response,ScopeData1.signals(1).values];
    rand_response(:,i+1) = ScopeData1.signals(1).values;
%     rand_control = [rand_control,ScopeData1.signals(2).values];
    rand_control(:,i+1) = ScopeData1.signals(2).values;
%     subplot(2,1,1);
%     hold on
%     plot(ScopeData.time,ScopeData.signals(1).values)
%     subplot(2,1,2);
%     hold on
%     plot(ScopeData.time,ScopeData.signals(2).values)   
end
% hold off
% rand_response = [ScopeData1.time,rand_response];
rand_response(:,1) = ScopeData1.time;
% rand_control = [ScopeData1.time,rand_control];
rand_control(:,1) = ScopeData1.time;
formatOut = 'yyyymmddHHMMSS';
save(strcat(random_type,datestr(now,formatOut)),'rand_response','rand_control');
toc
%% test draw from matrix file
% load data from random jitter
file ='uniform_10000_20181030231517.mat' ;
load(file);
% draw output response - RANDOM JITTER
tic
hold on
for i=2:length(rand_response(1,:))
    plot(rand_response(:,1),rand_response(:,i));
end
% format plot
xlabel('Time (s)')
% ylabel('Speed (rpm)')
title('ENVELOP OF OUTPUT RESPONSE')
% legend('NO JITTER','JITTER');%,'JITTER 20%','JITTER 30%','JITTER 40%','Location','southeast');
set(gca,'FontSize',30)
%set(findall(gca, 'Type', 'Line'),'LineWidth',3);
hold off
grid on
set(gcf, 'Position', [100, 100, 1280, 720])
axis([0 inf 0 1.6])
clear rand_response
clear rand_control
formatOut = 'yyyymmddHHMMSS';
print(file(1:(end-4)),'-dpng')
toc
%% brute-force run
file ='bruteforce_clock_19.mat'
load(file);
pause(2);
tic
T=0.4;
dC = pid(Kp,Ki,Kd,Tf,T);
% method = 'zoh';
% dC = c2d(C,T,method);
[sA,sB,sC,sD,T]=ssdata(dC);
iteration = length(array);
clk =jitter(500,T,30,"nothing"); 
sim('digital_control');
Storage_size = length(ScopeData1.signals(1).values);
rand_response = zeros(Storage_size,iteration+1,'double');
rand_control = zeros(Storage_size,iteration+1,'double');
toc
tic
for i=1:iteration
    %----------------------------------------------------------------
    %-----------process to get proper clk data before feed to sim----
    %----------------------------------------------------------------
            temp = array(:,i)/2;
            l = length(temp);
            temp2 = zeros(l*2+1,1);
            temp2(2:2:end)=temp;
            temp2(3:2:end)=temp;
            temp = cumsum(temp2);
            l = length(temp);
            time = [temp(l)+T/2:T/2:22]';
            temp3=([temp;time]);
            l = length(temp3);
            clk_bin = ones(l,1);
            l = length(clk_bin(2:2:end));
            clk_bin(2:2:end)=zeros(l,1);
            clk = [temp3,clk_bin];
    %----------------------------------------------------------------
    %-------------end------------------------------------------------
    %----------------------------------------------------------------
    clear ScopeData
    sim('digital_control');
%     rand_response = [rand_response,ScopeData.signals(1).values];
    rand_response(:,i+1) = ScopeData1.signals(1).values;
%     rand_control = [rand_control,ScopeData.signals(2).values];
    rand_control(:,i+1) = ScopeData1.signals(2).values;
end
clear temp
clear temp2
clear i
clear l
clear time
clear temp3
clear clk_bin
rand_response(:,1) = ScopeData1.time;
rand_control(:,1) = ScopeData1.time;
formatOut = 'yyyymmddHHMMSS';
save(strcat('bruteforce_19_',datestr(now,formatOut)),'rand_response','rand_control');
toc

%% test RMS
clk = jitter(10,1,30,"gaussian");
tmp = diff(clk(1:2:end,1));
root_mean_squares = rms(tmp)-1;
%% test RMS on sine wave
x = -pi:0.01:pi;
plot(x,311*sin(x));

%%  test RMS of brute-force value
load('bruteforce_clock.mat');
%% test bruceforce RMS - no use this one. It is before meeting
T = 0.4;
root_mean_squares = zeros(length(array),1);
for i=1:length(array)
    temp = array(:,i)/2;
    l = length(temp);
    temp2 = zeros(l*2+1,1);
    temp2(2:2:end)=temp;
    temp2(3:2:end)=temp;
    temp = cumsum(temp2);
    l = length(temp);
    time = [temp(l)+T/2:T/2:22]';
%     disp(temp);
%     disp(time');
    temp3=([temp;time]);
    tmp = diff(temp3(1:2:20));
    root_mean_squares(i)= rms(T-tmp);    
%     subplot(2,1,1);
%     hold on
%     plot(ScopeData.time,ScopeData.signals(1).values)
%     subplot(2,1,2);
%     hold on
%     plot(ScopeData.time,ScopeData.signals(2).values)
end
clear temp
clear temp2
% clear temp3
clear tmp
clear i
clear l
clear time
clear clk_bin

% xlswrite('testdata.xlsx',file1,1)
% xlswrite('testdata.xlsx',file2,2)
% clear file1
% clear file2
% hold off
root_mean_square = rms(root_mean_squares)

%% 10 Sep 2018  Uniform/Gaussian with same RMS to brute-force - ENVELOPE response
file ='uniform_clock_10000_20181013233200.mat';
load(file);
pause(2);
tic
T=0.4;
% method = 'zoh';
% dC = c2d(C,T,method);
%use forward Euler method    
    dC = pid(Kp,Ki,Kd,Tf,T);


[sA,sB,sC,sD,T]=ssdata(dC);
iteration = size(array,2);
clk =jitter(500,T,30,"nothing"); 
sim('digital_control');
Storage_size = length(ScopeData1.signals(1).values);
rand_response = zeros(Storage_size,iteration+1,'double');
rand_control = zeros(Storage_size,iteration+1,'double');
toc
tic
for i=1:iteration
    %----------------------------------------------------------------
    %-----------process to get proper clk data before feed to sim----
    %----------------------------------------------------------------
    
            temp = array(:,i)/2;
            
            %trim off 2 tails of gaussian
            temp(temp>0.26)=0.26;
            temp(temp<0.14)=0.14;
            
                l = length(temp);
                temp2 = zeros(l*2+1,1);
                temp2(2:2:end)=temp;
                temp2(3:2:end)=temp;
                temp = cumsum(temp2);
                l = length(temp);
                time = [temp(l)+T/2:T/2:22]';
                temp3=([temp;time]);
                l = length(temp3);
                clk_bin = ones(l,1);
                l = length(clk_bin(2:2:end));
                clk_bin(2:2:end)=zeros(l,1);
                clk = [temp3,clk_bin];
            
    %----------------------------------------------------------------
    %-------------end------------------------------------------------
    %----------------------------------------------------------------
    clear ScopeData
    sim('digital_control');
%     rand_response = [rand_response,ScopeData.signals(1).values];
    rand_response(:,i+1) = ScopeData1.signals(1).values;
%     rand_control = [rand_control,ScopeData.signals(2).values];
    rand_control(:,i+1) = ScopeData1.signals(2).values;
end
clear temp
clear temp2
clear i
clear l
clear time
clear temp3
clear clk_bin
rand_response(:,1) = ScopeData1.time;
rand_control(:,1) = ScopeData1.time;
formatOut = 'yyyymmddHHMMSS';
save(strcat(file(1:find(ismember(file,'_'),1)-1),'_',num2str(iteration),'_',datestr(now,formatOut)),'rand_response','rand_control');
toc
clear rand_response
clear rand_control

%% duplicate above - remove one of $ this line for run both
file ='uniform_clock_10000_20181030225154.mat';
load(file);
pause(2);
tic
T=0.4;
%use forward Euler method    
    dC = pid(Kp,Ki,Kd,Tf,T);
% method = 'zoh';
% dC = c2d(C,T,method);
[sA,sB,sC,sD,T]=ssdata(dC);
iteration = size(array,2);
clk =jitter(500,T,30,"nothing"); 
sim('digital_control');
Storage_size = length(ScopeData1.signals(1).values);
rand_response = zeros(Storage_size,iteration+1,'double');
rand_control = zeros(Storage_size,iteration+1,'double');
toc
tic
for i=1:iteration
    %----------------------------------------------------------------
    %-----------process to get proper clk data before feed to sim----
    %----------------------------------------------------------------
    
            temp = array(:,i)/2;
            %trim off 2 tails of gaussian
            temp(temp>0.26)=0.26;
            temp(temp<0.14)=0.14;
            %if isempty(temp(temp<=0))
                l = length(temp);
                temp2 = zeros(l*2+1,1);
                temp2(2:2:end)=temp;
                temp2(3:2:end)=temp;
                temp = cumsum(temp2);
                l = length(temp);
                time = [temp(l)+T/2:T/2:22]';
                temp3=([temp;time]);
                l = length(temp3);
                clk_bin = ones(l,1);
                l = length(clk_bin(2:2:end));
                clk_bin(2:2:end)=zeros(l,1);
                clk = [temp3,clk_bin];
             %end
    %----------------------------------------------------------------
    %-------------end------------------------------------------------
    %----------------------------------------------------------------
    clear ScopeData
    sim('digital_control');
%     rand_response = [rand_response,ScopeData.signals(1).values];
    rand_response(:,i+1) = ScopeData1.signals(1).values;
%     rand_control = [rand_control,ScopeData.signals(2).values];
    rand_control(:,i+1) = ScopeData1.signals(2).values;
end
clear temp
clear temp2
clear i
clear l
clear time
clear temp3
clear clk_bin
rand_response(:,1) = ScopeData1.time;
rand_control(:,1) = ScopeData1.time;
formatOut = 'yyyymmddHHMMSS';
save(strcat(file(1:find(ismember(file,'_'),1)-1),'_',num2str(iteration),'_',datestr(now,formatOut)),'rand_response','rand_control');
toc
clear rand_response
clear rand_control

%% RUN THIS ONE FOR MULTIPLE MATRIX files
for file_list=["gaussian_clock_100_20181031115935.mat"...
     "gaussian_clock_1000_20181031115947.mat" ...
    "gaussian_clock_10000_20181031120140.mat"]

%     file ='uniform_clock_10000_20181030225154.mat';
    file = convertStringsToChars(file_list)
    load(file);
    pause(2);
    tic
    T=0.4;
    %use forward Euler method    
        dC = pid(Kp,Ki,Kd,Tf,T);
    % method = 'zoh';
    % dC = c2d(C,T,method);
    [sA,sB,sC,sD,T]=ssdata(dC);
    iteration = size(array,2);
    clk =jitter(500,T,30,"nothing"); 
    sim('digital_control');
    Storage_size = length(ScopeData1.signals(1).values);
    rand_response = zeros(Storage_size,iteration+1,'double');
    rand_control = zeros(Storage_size,iteration+1,'double');
    toc
    tic
    for i=1:iteration
        %----------------------------------------------------------------
        %-----------process to get proper clk data before feed to sim----
        %----------------------------------------------------------------

                temp = array(:,i)/2;
                %trim off 2 tails of gaussian
                temp(temp>0.26)=0.26;
                temp(temp<0.14)=0.14;
                %if isempty(temp(temp<=0))
                    l = length(temp);
                    temp2 = zeros(l*2+1,1);
                    temp2(2:2:end)=temp;
                    temp2(3:2:end)=temp;
                    temp = cumsum(temp2);
                    l = length(temp);
                    time = [temp(l)+T/2:T/2:22]';
                    temp3=([temp;time]);
                    l = length(temp3);
                    clk_bin = ones(l,1);
                    l = length(clk_bin(2:2:end));
                    clk_bin(2:2:end)=zeros(l,1);
                    clk = [temp3,clk_bin];
                 %end
        %----------------------------------------------------------------
        %-------------end------------------------------------------------
        %----------------------------------------------------------------
        clear ScopeData
        sim('digital_control');
    %     rand_response = [rand_response,ScopeData.signals(1).values];
        rand_response(:,i+1) = ScopeData1.signals(1).values;
    %     rand_control = [rand_control,ScopeData.signals(2).values];
        rand_control(:,i+1) = ScopeData1.signals(2).values;
    end
    clear temp
    clear temp2
    clear i
    clear l
    clear time
    clear temp3
    clear clk_bin
    rand_response(:,1) = ScopeData1.time;
    rand_control(:,1) = ScopeData1.time;
    formatOut = 'yyyymmddHHMMSS';
    save(strcat(file(1:find(ismember(file,'_'),1)-1),'_',num2str(iteration),'_',datestr(now,formatOut)),'rand_response','rand_control');
    toc
    clear rand_response
    clear rand_control
end    
%% print histogram PDF at overshoot point.
file ='uniform_10000_20181030231517.mat';
tic
load(file);
toc
pause(2);
tic
data_size = size(rand_control,2)-1;
overshoots = zeros(1,data_size);
for i=1:data_size
    overshoots(i)= max(rand_response(:,i+1));
end
toc
histogram(overshoots,200);

%% find PDF at overshoot point.\
MEAN=[];
STD=[];
for file_list=["bruteforce_19_20181102002707.mat" ...
        "gaussian_1000_20181031121124.mat" ...
        "gaussian_10000_20181031122316.mat" ...
        "uniform_1000_20181030230334.mat" ...
        "uniform_10000_20181030231517.mat"]
    file =convertStringsToChars(file_list)
    pause(2);
    tic
    load(file);
    toc
    pause(2);
    tic
    data_size = size(rand_control,2)-1;
    overshoots = zeros(1,data_size);
    for i=1:data_size
        overshoots(i)= max(rand_response(:,i+1));
    end
    toc
    MEAN=[MEAN,mean(overshoots)];
    STD=[STD,std(overshoots)];
end
%% ttest2 at overshoot point.\
MEAN=[];
STD=[];
for file_list=["bruteforce_19_20181102002707.mat" ...
        "gaussian_1000_20181031121124.mat" ...
        "gaussian_10000_20181031122316.mat" ...
        "uniform_1000_20181030230334.mat" ...
        "uniform_10000_20181030231517.mat"]
    file =convertStringsToChars(file_list)
    pause(2);
    tic
    load(file);
    toc
    pause(2);
    tic
    data_size = size(rand_control,2)-1;
    overshoots = zeros(1,data_size);
    for i=1:data_size
        overshoots(i)= max(rand_response(:,i+1));
    end
    toc
    csvwrite(strcat(file(1:(end-4)),'.csv'),overshoots);
    MEAN=[MEAN,mean(overshoots)];
    STD=[STD,std(overshoots)];
end


%% find stepinfo and save to csv file.
MEAN=[];
STD=[];

n=1;
for file_list=[...
        "bruteforce_19_20181102002707.mat" ...
        "gaussian_1000_20181031121124.mat" ...
        "gaussian_10000_20181031122316.mat" ...
        "uniform_1000_20181030230334.mat" ...
        "uniform_10000_20181030231517.mat"...
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
    data_size = size(rand_control,2)-1;
    
    RiseTime=zeros(1,data_size);
    SettlingTime=zeros(1,data_size);
    SettlingMin=zeros(1,data_size);
    SettlingMax=zeros(1,data_size);
    Overshoot=zeros(1,data_size);
    Undershoot=zeros(1,data_size);
    Peak=zeros(1,data_size);
    PeakTime=zeros(1,data_size);   
    for i=1:data_size
        s= stepinfo(rand_response(:,i+1),rand_response(:,1));   
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
    %csvwrite(strcat(file(1:(end-4)),'.csv'),overshoots);
    dlmwrite(strcat(file(1:(end-4)),'.csv'),[RiseTime',SettlingMax'...
   SettlingMin', SettlingTime',Peak',PeakTime',Overshoot',Undershoot']...
    ,'delimiter',',','-append');

    subplot(5,2,n);
    histogram(SettlingTime,100);
    title(strcat('SettlingTime_',file(1:(end-4))),'Interpreter','none');
    n= n+1;
    subplot(5,2,n);
    histogram(Peak,200);
    title(strcat('Peak_',file(1:(end-4))),'Interpreter','none');
    n = n+1;
    %MEAN=[MEAN,mean(overshoots)];
    %STD=[STD,std(overshoots)];
end

clear RiseTime SettlingMax SettlingMin SettlingTime Peak PeakTime Overshoot Undershoot
clear s data_size i file file_list
clear MEAN STD
clear rand_control rand_response
%%
header = "RiseTime,SettlingMax,SettlingMin,SettlingTime,Peak,PeakTime,Overshoot,Undershoot\n";
fileID = fopen('hello.csv','w');
fprintf(fileID,header);
fclose(fileID);
clear fileID;
clear header;
dlmwrite('hello.csv',[RiseTime',SettlingMax'...
   SettlingMin', SettlingTime',Peak',PeakTime',Overshoot',Undershoot']...
    ,'delimiter',',','-append');
%% 16 Dec 2018 - HW pattern run
tic
T=0.001;
% clock generator
load('clk_1ms_bb_high_priority20181212141203.mat');
CLK = clk;
Lim = max(CLK(:,1))-15;
Index_max = max(find(CLK(:,1)<Lim));

sim('digital_control');
Storage_size = length(ScopeData1.signals(1).values);
rand_response = zeros(Storage_size,100,'double');
rand_control = zeros(Storage_size,100,'double');

%----------------------
method = 'zoh';
%dC = c2d(C,T,method);
dC = pid(Kp,Ki,Kd,Tf,T);
[sA,sB,sC,sD,T]=ssdata(dC);
dP = c2d(P,T);
L = length(clk)/2;
hold on
Count=2;
toc
tic
for i=1:2:100
    clk = [CLK(i:end,1)-CLK(i,1),CLK(i:end,2)];
    sim('digital_control');
    %stairs(ScopeData1.time,ScopeData1.signals(1).values);
    rand_response(:,Count) = ScopeData1.signals(1).values;
    rand_control(:,Count) = ScopeData1.signals(2).values;
    Count = Count +1;
end
rand_response(:,1) = ScopeData1.time;
rand_control(:,1) = ScopeData1.time;
hold off
toc
%%
hold on
for i=2:50
    plot(rand_response(:,1),rand_response(:,i));
end
hold off

