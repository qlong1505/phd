function clk = jitter(L, Sample_period, jitter_amplitude, random_type)
    %JITTER Summary of this function goes here
    %   Detailed explanation goes here
    sigma = 6;
    rng('shuffle');
    % select uniform or gaussian random distribution
    %-----------------------------------------------
    %random_type = uniform;
    %-----------------------------------------------
    %L = 500; %length of pattern
    if random_type == "gaussian"
        jit_period = randn(L, 1) * jitter_amplitude * Sample_period / 100 / sigma + Sample_period;
    else
        jit_period = (rand(L, 1) * 2 - 1) * jitter_amplitude * Sample_period / 100 + Sample_period;
    end

    jit_half_period = jit_period / 2;
    % x = d(1:length(d)-1)+d(2:length(d))

    d = ones(L * 2, 1);
    d(1:2:end, :) = jit_half_period;
    d(2:2:end, :) = jit_half_period;
    jit_period_cumsum = cumsum(d);

    %-------------------------------------------------------------------
    %create clock signal with 0,1,0,1,0,1,0,1,0,1,0,1
    %-------------------------------------------------------------------
    b2 = zeros(L, 1);  %array zero
    b1 = ones(L, 1);  %array one
    c = ones(size([b1; b2]));  % initiate array c with 1000 elements
    c(1:2:end, :) = b1;
    c(2:2:end, :) = b2;
    %after step above, c is a clock signal
    clock_signal = c;
    %-------------------------------------------------------------------

    temp = jit_period_cumsum(1:end - 1);
    temp = [0, temp'];
    d = temp';
    d = [d, clock_signal];
    d(1:20);
    % clk_jitter = d;
    clk = d;
    % temp = 0:Sample_period/2:(2*L-1)*Sample_period/2;
    % clk = [temp',clock_signal];

    clear b1;
    clear b2;
    clear c;
    clear d;
    clear temp;
    clear clock_signal;
    clear jit_half_period;
    %#histogram(jit_period);
    clear jit_period;
    clear jit_period_cumsum;
    clear ran_delay_time_array;
    clear L
    clear sigma
end
