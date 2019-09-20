
%run simulink file 
sim('test_20171220');

%extract what is it in scopedata.

time = ScopeData.time;
sine = ScopeData.signals(1).values;
sine_dig_1 = ScopeData.signals(2).values;
sine_dig_2 = ScopeData.signals(3).values;
sine_dig_3 = ScopeData.signals(4).values;


figure('units','normalized','outerposition',[0 0 1 1])
hold on
    plot(time,sine);
    plot(time,sine_dig_1);
    plot(time,sine_dig_2);
    plot3 = plot(time,sine_dig_3,'--');
    title('Comparison output between output from scope1 and scope2')
    xlabel('Time (s)')
    set(gca,'FontSize',30)
    set(findall(gca, 'Type', 'Line'),'LineWidth',2);
    set(plot3,'LineWidth',5);
    legend('S: Original sine wave S','S_{zoh}[k]','S_{zoh}[k-1]','alternative S_{zoh}[k-1]','Interpreter','Latex','Location','southwest');
hold off
formatOut = 'yymmddHHMMSS';
print(strcat('sine_',datestr(now,formatOut)),'-dsvg')
    %save(strcat('clk_',folder{x,y},datestr(now,formatOut)),'clk')
saveas(gcf,strcat('sine_',datestr(now,formatOut),'.png'))

