
file_bbg_noload_pd ='acq018.csv'
file_bbg_loaded_pl ='acq011.csv'
file_bbg_loaded_pd ='acq030.csv'
file_bbg_loaded_ph ='acq047.csv'

file_rpi_d_noload_pd ='acq069.csv'
file_rpi_d_loaded_pl ='acq064.csv'
file_rpi_d_loaded_pd ='acq081.csv'
file_rpi_d_loaded_ph ='acq098.csv'


file_rpi_u_noload_pd ='acq120.csv'
file_rpi_u_loaded_pl ='acq115.csv'
file_rpi_u_loaded_pd ='acq132.csv'
file_rpi_u_loaded_ph ='acq149.csv'

file_i5_noload_pd ='acq171.csv'
file_i5_loaded_pl ='acq166.csv'
file_i5_loaded_pd ='acq183.csv'
file_i5_loaded_ph ='acq200.csv'

data_range = 'A10002..B13000'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = csvread(file_bbg_noload_pd,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
figure(1)
subplot(4,1,1)
plot(x,y)
title('NO CPU Stress at Clock priority 0')
data = csvread(file_bbg_loaded_pl,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,2)
plot(x,y)
title('Full CPU Stress at Clock priority 19')
data = csvread(file_bbg_loaded_pd,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,3)
plot(x,y)
title('Full CPU Stress at Clock priority 0')
data = csvread(file_bbg_loaded_ph,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,4)
plot(x,y)
title('Full CPU Stress at Clock priority -19')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = csvread(file_rpi_d_noload_pd,0,0,[data_range])
x= data(:,2);
y= data(:,3);
figure(2)
subplot(4,1,1)
plot(x,y)
title('NO CPU Stress at Clock priority 0')
data = csvread(file_rpi_d_loaded_pl,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,2)
plot(x,y)
title('Full CPU Stress at Clock priority 19')
data = csvread(file_rpi_d_loaded_pd,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,3)
plot(x,y)
title('Full CPU Stress at Clock priority 0')
data = csvread(file_rpi_d_loaded_ph,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,4)
plot(x,y)
title('Full CPU Stress at Clock priority -19')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = csvread(file_rpi_u_noload_pd,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
figure(3)
subplot(4,1,1)
plot(x,y)
title('NO CPU Stress at Clock priority 0')
data = csvread(file_rpi_u_loaded_pl,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,2)
plot(x,y)
title('Full CPU Stress at Clock priority 19')
data = csvread(file_rpi_u_loaded_pd,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,3)
plot(x,y)
title('Full CPU Stress at Clock priority 0')
data = csvread(file_rpi_u_loaded_ph,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,4)
plot(x,y)
title('Full CPU Stress at Clock priority -19')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data = csvread(file_i5_noload_pd,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
figure(4)
subplot(4,1,1)
plot(x,y)
title('NO CPU Stress at Clock priority 0')
data = csvread(file_i5_loaded_pl,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,2)
plot(x,y)
title('Full CPU Stress at Clock priority 19')
data = csvread(file_i5_loaded_pd,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,3)
plot(x,y)
title('Full CPU Stress at Clock priority 0')
data = csvread(file_i5_loaded_ph,0,0,[data_range]);
x= data(:,2);
y= data(:,3);
subplot(4,1,4)
plot(x,y)
title('Full CPU Stress at Clock priority -19')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

