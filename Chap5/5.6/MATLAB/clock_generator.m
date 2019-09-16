function [clk] = clock_generator(total_jitter)
%CLOCK_GENERATOR Summary of this function goes here
%   Detailed explanation goes here
jit_half_period = total_jitter/2;
% x = d(1:length(d)-1)+d(2:length(d))
L=length(total_jitter);
d = ones(L*2,1);
array_1 = [d;0];
array_1(2:2:end) = 0;
d(1:2:end,:)=jit_half_period;
d(2:2:end,:)=jit_half_period;
jit_period_cumsum = cumsum(d);
clk = [0;jit_period_cumsum];
clk = [clk,array_1];
end

