%% s domain
P = tf([5], [1 4 8]);  %S-domain plant
C = tf([0.5 2.5], [1 2 0]);  %S-domain controller
cl = feedback(P * C, 1);
step(cl);

%% discretize - step response with different sampling time
hold on
for T = [0.05 0.3 0.4]
    dC = c2d(C, T, 'zoh');
    dP = c2d(P, T);
    cl = feedback(dC * dP, 1);
    step(cl, 12);
end
grid on

%% discretize - step response with difference c2d conversion method
hold on
for method = ["zoh""tustin"]
    for T = [0.2]
        method = convertStringsToChars(method);
        dC = c2d(C, T, method);
        dP = c2d(P, T);
        cl = feedback(dC * dP, 1);
        step(cl, 12);
    end
end
grid on
%% Z-controller testing on simulink
T = 0.3;
% clock generator
L = 1000
pulse = ones(L, 1);
pulse(2:2:end) = zeros(L / 2, 1);
clk = 0:T / 2:(L - 1) * T / 2;
clk = clk';
clk = [clk, pulse]
%----------------------
method = 'zoh';
dC = c2d(C, T, method);
[sA, sB, sC, sD, T] = ssdata(dC);
dP = c2d(P, T);
sim('digital_control');
stairs(ScopeData1.time, ScopeData1.signals(1).values);

%% Test with jitter
jitter_amplitude = 20;
Sample_period = T;
jitter_generator;
%----------------------
method = 'zoh';
dC = c2d(C, T, method);
[sA, sB, sC, sD, T] = ssdata(dC);
dP = c2d(P, T);
sim('digital_control');
stairs(ScopeData1.time, ScopeData1.signals.values);

%% envelopes test
hold on
for i = 1:1:20
    clk = jitter(500, 0.3, 30, 0);
    sim('digital_control');
    stairs(ScopeData1.time, ScopeData1.signals(1).values);
end
hold off

%% Uniform/Gausian distribution random jitter
%update 26/06/2018: removeing plot part. Instead, save in two variable
%rand_response and rand_control
% hold on
T = 0.3;
method = 'zoh';
dC = c2d(C, T, method);
[sA, sB, sC, sD, T] = ssdata(dC);
% jitter_amplitude = 20;
% Sample_period = T;
rand_response = [];
rand_control = [];
random_type = "uniform";
for i = 1:3^20
    clk = jitter(500, T, 30, random_type);
    clear ScopeData1
    sim('digital_control');
    rand_response = [rand_response, ScopeData1.signals(1).values];
    rand_control = [rand_control, ScopeData1.signals(2).values];
    %     subplot(2,1,1);
    %     hold on
    %     plot(ScopeData.time,ScopeData.signals(1).values)
    %     subplot(2,1,2);
    %     hold on
    %     plot(ScopeData.time,ScopeData.signals(2).values)
end
% hold off
rand_response = [ScopeData1.time, rand_response];
rand_control = [ScopeData1.time, rand_control];
formatOut = 'yyyymmddHHMMSS';
save(strcat(random_type, datestr(now, formatOut)), 'rand_response', 'rand_control');
%% test draw from matrix file
% load data from random jitter
load('uniform20180928180321.mat');
% draw output response - RANDOM JITTER
hold on
for i = 2:length(rand_response(1, :))
    plot(rand_response(:, 1), rand_response(:, i));
end
% format plot
xlabel('Time (s)')
ylabel('Speed (rpm)')
title('ENVELOP OF OUTPUT RESPONSE')
% legend('NO JITTER','JITTER');%,'JITTER 20%','JITTER 30%','JITTER 40%','Location','southeast');
set(gca, 'FontSize', 12)
%set(findall(gca, 'Type', 'Line'),'LineWidth',3);
hold off
clear rand_response
formatOut = 'yyyymmddHHMMSS';
print(strcat('envelop_response_random_', datestr(now, formatOut)), '-dpng')
