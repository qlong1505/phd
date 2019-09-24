%% Declare sampling perido and jitter percentage
Sample_period = 0.4 ;%ms
jitter_amplitude = 19;% percent of period
%% There are 3 level : HIGH/LOW/NO_JITTER
level = [Sample_period*(1-jitter_amplitude/100) Sample_period Sample_period*(1+jitter_amplitude/100) ];
number_level = length(level);
number_of_step = 10;% number of step during rise time is about 10

%%
array=zeros(number_of_step,3^number_of_step);
index = 1;
for i0 = 1:number_level
    for i1=1:number_level
        for i2=1:number_level
            for i3=1:number_level
                for i4=1:number_level
                    for i5=1:number_level
                        for i6=1:number_level
                            for i7=1:number_level
                                for i8=1:number_level
                                    for i9=1:number_level
                                        fprintf('%d %d %d %d %d %d %d %d %d %d\n',level(i0),level(i1),level(i2),...
                                        level(i3),level(i4),level(i5),level(i6),level(i7),level(i8),level(i9));
                                        array(:,index) =[level(i0);level(i1);level(i2);...
                                        level(i3);level(i4);level(i5);level(i6);level(i7);level(i8);level(i9)];
                                    
                                    
                                        index = index + 1;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
%     fprintf('%d\n',level(level_index));
end
save('bruteforce_clock_19','array');

%% test to save data to file
load('matlab.mat');
%% brute force run
% hold on
rand_response = [];
rand_control = [];
for i=1:length(array)
    temp = array(:,i)/2;
    l = length(temp);
    temp2 = zeros(l*2+1,1);
    temp2(2:2:end)=temp;
    temp2(3:2:end)=temp;
    temp = cumsum(temp2);
    l = length(temp);
    time = [temp(l)+Sample_period/2:Sample_period/2:22]';
%     disp(temp);
%     disp(time');
    temp3=([temp;time]);
    l = length(temp3);
    clk_bin = ones(l,1);
    l = length(clk_bin(2:2:end));
    clk_bin(2:2:end)=zeros(l,1);
    clk = [temp3,clk_bin];
    clear ScopeData
    sim('DCmotor_model_jitter');
    rand_response = [rand_response,ScopeData.signals(1).values];
    rand_control = [rand_control,ScopeData.signals(2).values];
%     subplot(2,1,1);
%     hold on
%     plot(ScopeData.time,ScopeData.signals(1).values)
%     subplot(2,1,2);
%     hold on
%     plot(ScopeData.time,ScopeData.signals(2).values)
end
clear temp
clear temp2
clear i
clear l
clear time
clear temp3
clear clk_bin
rand_response = [ScopeData.time,rand_response]
rand_control = [ScopeData.time,rand_control]
% xlswrite('testdata.xlsx',file1,1)
% xlswrite('testdata.xlsx',file2,2)
% clear file1
% clear file2
% hold off

