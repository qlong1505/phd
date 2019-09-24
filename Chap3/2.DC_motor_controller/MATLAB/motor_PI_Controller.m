%SETTING PARAMETER FOR MOTOR
b=1.02633E-07;
% J =6.5e-8; %moment of inertia of the rotor 
 J =9e-8; %moment of inertia of the rotor 
%  J = 6e-8;
% K = 0.0036; %electromotive force constant (Ke) = motor torque constant(Kt)=K
K = 0.003; %electromotive force constant (Ke) = motor torque constant(Kt)=K
R = 13.24; %electric resistance
L = 0.00362; %electric inductance       
pre_speed = 50;

%SETTING FOR SIMULATION SYSTEM
en_delay = 1;
delay_t = 0.0025; %only work when en_delay =1;

%based on http://ctms.engin.umich.edu/CTMS/index.php?example=MotorSpeed&section=SystemModeling
%we can build a transfer function for the motor in S domain
s = tf('s');
P_motor = K*0.5/((J*s+b)*(L*s+R)+K^2);

% zpk(P_motor)
% ltiview('step', P_motor, 0:0.005:2);
 figure;
step(P_motor);

%PI controller parameter should match with real controller in OUSB board
% Kp = 0.06;
% Kp = 0.1; %20170314
%   Kp = 0.046378;
%  Ki = 2.6969;
%  Kp = 0.046378;
Kp = 0.04;
Ki=0.9;
C = pid(Kp,Ki)

sys_cl = feedback(C*P_motor,1);
figure;
step(sys_cl);
 
%this part is to convert S-domain to Z-domain
Ts = 0.01; %sampling time  = 10ms
z = tf('z',Ts);
dP_motor = c2d(P_motor,Ts,'zoh');
dC = c2d(C,Ts,'tustin');

% dC = 0.02*(z-0.78)/(z-1);
sys_cl = feedback(dC*dP_motor,1);
[A,B,C,D] =ssdata(dC);
% figure;
opt = stepDataOptions('InputOffset',11,'StepAmplitude',50-11);
figure;
step(sys_cl,opt);