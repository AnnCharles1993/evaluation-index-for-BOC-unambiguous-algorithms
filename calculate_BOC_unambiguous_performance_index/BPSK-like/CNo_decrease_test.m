
clear;
clc;
%%
%正弦BOC参数
c=CA_code(1);%得到CA码序列1
L_CA=length(c);%CA码序列长度
m=10;n=5;
Rc=n*1.023e6;%码速率
Tc=1/Rc;%码片长度
f_sample=100e6;%采样频率
T_sample=1/f_sample;
Tp=1e-3-T_sample;%相干积分时间1ms
fs=m*1.023e6;
Ts=1/fs/2;
%%
%%%相关器间隔
BW=30*1.023e6;d=0.2*Tc;Dz  = 1.814e-3;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N_BW=10000;
f=linspace(-BW/2,BW/2,N_BW);
PSD_BOC=PSDcal_BOCs(f, fs, Tc);
power_loss_filter_dB=10*log10(trapz(f,PSD_BOC));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
C=1;%载波功率

% N_C=60; %delta=0.5 dB-Hz
% n_loop=10000;
% C_N0_dB=linspace(20,50,N_C)-power_loss_filter_dB;
% C_N0_dB=45;
% C_N0=10.^(C_N0_dB/10);
% N0=C./C_N0;%单边噪声功率谱密度
% I_NoisePower=N0*BW*f_sample/BW;%在接收带宽内的噪声功率,因为在滤波后，噪声功率减为此处的BW/fsample，为了使滤波后噪声功率保持2N0*BW(射频变基带噪声谱密度变2倍)，在此处乘以fsample/BW
% Q_NoisePower=N0*f_sample;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t0=0.0*Ts;%真实传播时间，初始误差在一个码片内
% t0=-0.9648*Tc;%真introduce false lock
t_begin=t0;
t_end=t_begin+Tp;
t_ref_begin_scan=0;
n_loop=100000;
% n_loop=50000;

%% set CNo decrease model

CNo_drop_delta_per_changes=7;%how many (dB-Hz) CNo drops during one time change
drop_times=(50-15)/CNo_drop_delta_per_changes;

C_N0_dB_drop=linspace(50,20,drop_times)-power_loss_filter_dB;

CNo_increase_delta_per_changes=15;%how many (dB-Hz) CNo increases during one time change
increase_times=(50-20)/CNo_increase_delta_per_changes;
C_N0_dB_increase=linspace(20,50,increase_times)-power_loss_filter_dB;

C_N0_dB=zeros(1,drop_times+increase_times);
C_N0_dB(1:drop_times)=C_N0_dB_drop;
C_N0_dB(drop_times+1:end)=C_N0_dB_increase;

Trackerror=zeros(1,n_loop);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%%%%%%BOC(14,2)%%%%%%%%%
% Dz=1.652e-4;
% Dz=5.27e-4;
%%
error_x=zeros(1,n_loop);
error_y=zeros(1,n_loop);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[S_CA_receiver,t]=yt_BOCs_function(c,t_begin,t_end,Tc,fs,f_sample);
N_zong=length(t);

TrackErrRMS=zeros(1,n_loop);
h_wait=waitbar(0);

% Num_false_acquisition=200;
% t_ref_begin_scan=linspace(-1*Tc,Tc,Num_false_acquisition);

% for m=1:Num_false_acquisition
%     for k=1:CNo_change_times
%         tic;
        t0=0.0*Ts;%真实传播时间，初始误差在一个码片内

        t_begin=t0;
        t_end=t_begin+Tp;
        t_ref_begin=t0;
%         t_ref_begin=t_ref_begin_scan(m);
%         Counter_VE=0;%VE计数器
%         Counter_VL=0;%VL计数器
        for n=1:n_loop
            
            % 确定当前n对CNo的采样点位置
%         N_CNo_sampling=mod(     n   ,    floor(  n_loop/length(C_N0_dB)    )    ) ;
        N_CNo_sampling = floor(n/(  n_loop/length(C_N0_dB)))+1;
        %根据当前CNo加对应功率的噪声
        C_N0=10.^(C_N0_dB(N_CNo_sampling)/10);
        N0=C./C_N0;%单边噪声功率谱密度
        I_NoisePower=N0*BW*f_sample/BW;%在接收带宽内的噪声功率,因为在滤波后，噪声功率减为此处的BW/fsample，为了使滤波后噪声功率保持2N0*BW(射频变基带噪声谱密度变2倍)，在此处乘以fsample/BW
        Q_NoisePower=N0*f_sample;

            t_ref_end=t_ref_begin+Tp;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%
        [s_E,t]=yt_BPSK_function(c,t_ref_begin+d/2,t_ref_end+d/2,Tc,f_sample);
        [s_L,t]=yt_BPSK_function(c,t_ref_begin-d/2,t_ref_end-d/2,Tc,f_sample);  
        [s_P,t_P]=yt_BPSK_function(c,t_ref_begin,t_ref_end,Tc,f_sample);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

             N_zong=length(t);
             %%%%%%%%%%%%%%%%%%%%%%%%%%   
             %%
            S_receiver_I=sqrt(2*C)*S_CA_receiver+sqrt(I_NoisePower)*randn(1,N_zong);
            S_receiver_Q=sqrt(Q_NoisePower)*randn(1,N_zong);

           %%    下边带
    fft_sig  = fft((S_receiver_I+1i*S_receiver_Q).*exp(1i*2*pi*fs*t_P));
    L_res   = round(BW/f_sample/2*N_zong);
    fft_sig(L_res+1:end-L_res)  = 0;
    sigBandL = ifft(fft_sig); 
    RecSigI_down = real(sigBandL);
    RecSigQ_down = imag(sigBandL);
    %%    上边带
    fft_sig  = fft((S_receiver_I+1i*S_receiver_Q).*exp(-1i*2*pi*fs*t_P));
    L_res   = round(BW/f_sample/2*N_zong);
    fft_sig(L_res+1:end-L_res)  = 0;
    sigBandL = ifft(fft_sig); 
    RecSigI_up = real(sigBandL);
    RecSigQ_up = imag(sigBandL);
    %% 积分清零器
        IE_up = sum(s_E.* RecSigI_up)/N_zong;QE_up = sum(s_E.* RecSigQ_up)/N_zong;
        IL_up = sum(s_L.* RecSigI_up)/N_zong;QL_up = sum(s_L.* RecSigQ_up)/N_zong;   
        
        IE_down = sum(s_E.* RecSigI_down)/N_zong;QE_down = sum(s_E.* RecSigQ_down)/N_zong;
        IL_down = sum(s_L.* RecSigI_down)/N_zong;QL_down = sum(s_L.* RecSigQ_down)/N_zong;
   
        %% 鉴别器
        DiscrimOut = (IE_up.^2 + QE_up.^2)-(IL_up.^2 + QL_up.^2)+(IE_down.^2 + QE_down.^2)-(IL_down.^2 + QL_down.^2);

        %%
            error_x(n)=(t_begin-t_ref_begin)/Tc;%真实误差
            error_y(n)=DiscrimOut;%鉴别器输出


            Filter_output=DiscrimOut*Dz;%一阶环路滤波器

            t_ref_begin=t_ref_begin+Filter_output*Tc;

            Trackerror(n)=(t_ref_begin-t_begin)*3e8;%跟踪误差

            temp_string=['已运行' num2str(    n/n_loop*100  ) '%'];
            waitbar((n)/(n_loop),h_wait,temp_string);
%             toc;
        end
%         TrackErrSTD(k)=std(error_x);
        
%     end
    
% end
savefile='CNo_desrease_test_BPSK_like_method_BOC_10_5_30M_02Tc.mat';
save(savefile);


close(h_wait);
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% plot false lock index
figure;plot(n_loop,Trackerror/3e8/Tc,'Linwidth',2);grid on;
xlabel('Time (ms)');
ylabel('Code tracking error (chips)');
saveas(gcf,'CNo_desrease_test_BPSK_like_method_BOC_10_5_30M_02Tc');
