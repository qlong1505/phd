 f = load('test.mat');
 sheet  = 6;
 file = f.ans;
 
 col_idx = file(1,:)>=0.2;
 file = file(:,col_idx);
 file(1,:) = file(1,:)-0.2;
% xlswrite('PhD20170104_simulation.xlsx',file,sheet,'B1');


 
%  write label for value
%  long = {'Time'...
%     ,'P3_Jitter40%','P3_Jitter30%','P3_Jitter20%','P3_Jitter10%'...
%     ,'P2_Jitter40%','P2_Jitter30%','P2_Jitter20%','P2_Jitter10%'...
%     ,'P1_Jitter40%','P1_Jitter30%','P1_Jitter20%','P1_Jitter10%'...
%     ,'No_jitter','Step_input'};

long = {'time','No_jitter','step input'}
long = long.'
% xlswrite('PhD20170104_simulation.xlsx',long,sheet,'A1');
% long3 = horzcat(long2,f.ans);

% long2

flie = file(:,1:10:length(file))
stairs(flie(1,:),flie(2,:))