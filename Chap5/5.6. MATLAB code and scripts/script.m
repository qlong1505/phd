file = 'acq0003.csv';
% x = csvread(file);
x = readtable(file)
%%
histogram(x,1000)
mean
%%
meanx = mean(x);
x = x(x<1.1*meanx & x>0.9*meanx);
histogram(x,30);

%% histogram of hardware measure jitter
folder ={'BB_1_120s_high','BB_1_120s_norm','BB_1_120s_low';...
    '1ms_rasp_high_priority','1ms_rasp_normal_priority','1ms_rasp_low_priority';...
    'Opi_1_120_high','Opi_1_120s_norm','Opi_1_120_low'}

Q1 = 'Which platform?\n1.Beagle Bone Black (single core)\n2.Raspberry pi (multi cores)\n3.Orange Pi (multicores)\n';
x = input(Q1);
Q2 ='Choose priority level:\n1.High\n2.Normal\n3.Low\n';
y =input(Q2);
Q3 ='2- Save figure with a special name, 1 - Save data, 0 - No save';
z =input(Q3);
if z==2
    name = input('name of svg file: ','s');
%     print(name,'-dsvg')
end
file = listACQ(folder{x,y});

total_jitter=[];
for i=1:length(file)
    data=readtable(file{i})

    % Logic data in 2nd column
    V = data{:,2};
    
    % Time stamp data in Time_s_ column
    T = data.Time_s_;
    
    jitter  = process(V,T);
    total_jitter = [total_jitter;jitter];
end

clk = clock_generator(total_jitter);

total_jitter = total_jitter(1:10000,1)
%histogram(total_jitter,50);
histfit(total_jitter,100);
%set(gca,'YScale','log')
xlabel('Value') 
ylabel('Counts') 
set(gca,'FontSize',20)
set(gcf, 'Position', [100, 100, 1280, 720])
pd = fitdist(total_jitter,'Normal')
hold on

% normal distribution with mean is 1ms
%     x = normrnd(0.001,std(total_jitter),length(total_jitter),1);
%     histogram(x,50);
%     set(gca,'YScale','log')

% Normal distribution with mean is data mean
%     x = normrnd(mean(total_jitter),std(total_jitter),length(total_jitter),1);
%     histogram(x,50);
%     set(gca,'YScale','log')

% Half normal distribution
%         pd2 = makedist('HalfNormal','mu',mean(total_jitter),'sigma',std(total_jitter));
%         x = random(pd2,length(total_jitter),1)
%         histogram(x,50);
%         set(gca,'YScale','log')

hold off
if z==1
    formatOut = 'yyyymmddHHMMSS';
    print(strcat('hist_',folder{x,y},datestr(now,formatOut)),'-dsvg')
    save(strcat('clk_',folder{x,y},datestr(now,formatOut)),'clk')
end
axis([0.005 0.01 0 inf])
xlabel('Sample time value');
if z==2
    %name = input('name of svg file: ','s');
    print(name,'-dsvg')
end


%% open loop step response - load data
OLdata=readtable('open_loop.csv');
%%
load('open_loop.mat');
%% process data to plot open loop reponse
T = OLdata.Time_s_(OLdata.Time_s_>=0);
EncoderA = OLdata.Channel1_V_(find(OLdata.Time_s_>=0));
EncoderB = OLdata.Channel2_V_(find(OLdata.Time_s_>=0));
%
EncoderA(EncoderA<1.5)=0;
EncoderA(EncoderA>=1.5)=1;
EncoderA = diff(EncoderA);
EncoderA(EncoderA==-1)=1;

EncoderB(EncoderB<1.5)=0;
EncoderB(EncoderB>=1.5)=1;
EncoderB = diff(EncoderB);
EncoderB(EncoderB==-1)=1;

T1 = T(find(EncoderA==1));
T2 = T(find(EncoderB==1));
%
T = zeros(length(T1)+length(T2),1);
T(1:2:end)=T1;
T(2:2:end)=T2;
%
T = diff(T);
T = diff(T1);
%git push
Speed = T*24;
%
Speed = 1./Speed;
Speed = Speed*60; %rpm
%
T = cumsum(T);
%
plot(T(T<0.5),Speed(find(T<0.5)));
%% Plot the emperical model 
K = 4543/5;
tau = 0.042
sys = tf(K,[tau 1])
step(sys*5)

%% testing disk writer model with 0.0001 sampling time
A = [-20 0;1 0]
B = [1;0]
C = [0 1]
D = 0;
T = 0.0001;
[b,a] = ss2tf(A,B,C,D);
G = tf(b,a)
dG = c2d(G,T)
[A1,B1,C1,D1]=ssdata(dG)
dG2 = ss(A,B,C,D,T)
step(G)

%% script to draw histogram of 10000 recorded sample.
folder ={'BB_1_120s_high','BB_1_120s_norm','BB_1_120s_low';...
    '1ms_rasp_high_priority','1ms_rasp_normal_priority','1ms_rasp_low_priority';...
    'Opi_1_120_high','Opi_1_120s_norm','Opi_1_120_low'}

Q1 = 'Which platform?\n1.Beagle Bone Black (single core)\n2.Raspberry pi (multi cores)\n3.Orange Pi (multicores)\n';
x = input(Q1);
if x==1
    Xmax = 0.08
    Xmin = 0
else
    Xmax = 0.01
    Xmin = 0.005
end
% Q2 ='Choose priority level:\n1.High\n2.Normal\n3.Low\n';
% y =input(Q2);
% Q3 ='2- Save figure with a special name, 1 - Save data, 0 - No save';
% z =input(Q3);
% if z==2
%     name = input('name of svg file: ','s');
% %     print(name,'-dsvg')
% end
for y = 1:3
    file = listACQ(folder{x,y});
    total_jitter=[];
    for i=1:length(file)
        data=readtable(file{i})

        % Logic data in 2nd column
        V = data{:,2};

        % Time stamp data in Time_s_ column
        T = data.Time_s_;

        jitter  = process(V,T);
        total_jitter = [total_jitter;jitter];
    end

    clk = clock_generator(total_jitter);
    total_jitter = total_jitter(1:10000,1)
    %histogram(total_jitter,50);
    histfit(total_jitter,50);
    %set(gca,'YScale','log')
    xlabel('Value') 
    ylabel('Counts') 
    set(gca,'FontSize',20)
    set(gcf, 'Position', [100, 100, 1280, 720])
    pd = fitdist(total_jitter,'Normal')
    hold on
    hold off
    axis([Xmin Xmax 0 inf])
    xlabel('Sample time value(s)');
    name=strcat('hist_',folder{x,y});
    print(name,'-dsvg')
end