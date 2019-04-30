
clear;
clc;
%%
%����BOC����
c=CA_code(1);%�õ�CA������1
L_CA=length(c);%CA�����г���
m=10;n=5;
Rc=n*1.023e6;%������
Tc=1/Rc;%��Ƭ����
f_sample=100e6;%����Ƶ��
T_sample=1/f_sample;
Tp=1e-3-T_sample;%��ɻ���ʱ��1ms
fs=m*1.023e6;
Ts=1/fs/2;
%%
%%%��������
BW=30*1.023e6;d_Subcarrier=0.1*Tc;d_code=Ts;%BOC(10,5)��������%shiyan2
Dz_code  = 7.509e-4;%K_code=5.3129
Dz_Subcarrier  =1.3331e-4;%K_Subcarrier=29.9243
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N_BW=10000;
f=linspace(-BW/2,BW/2,N_BW);
PSD_BOC=PSDcal_BOCs(f, fs, Tc);
power_loss_filter_dB=10*log10(trapz(f,PSD_BOC));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
C=1;%�ز�����

% N_C=60; %delta=0.5 dB-Hz
% n_loop=10000;
% C_N0_dB=linspace(20,50,N_C)-power_loss_filter_dB;
% C_N0_dB=45;
% C_N0=10.^(C_N0_dB/10);
% N0=C./C_N0;%���������������ܶ�
% I_NoisePower=N0*BW*f_sample/BW;%�ڽ��մ����ڵ���������,��Ϊ���˲����������ʼ�Ϊ�˴���BW/fsample��Ϊ��ʹ�˲����������ʱ���2N0*BW(��Ƶ������������ܶȱ�2��)���ڴ˴�����fsample/BW
% Q_NoisePower=N0*f_sample;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t0=0.0*Ts;%��ʵ����ʱ�䣬��ʼ�����һ����Ƭ��
% t0=-0.9648*Tc;%��introduce false lock
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
Dz=5.27e-4;
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
        t0=0.0*Ts;%��ʵ����ʱ�䣬��ʼ�����һ����Ƭ��

        t_begin=t0;
        t_end=t_begin+Tp;
        
        t_code_ref_begin=t0;
        t_Subcarrier_ref_begin=t0;
        t_estimate_begin=0;
%         t_ref_begin=t0;
%         t_ref_begin=t_ref_begin_scan(m);
%         Counter_VE=0;%VE������
%         Counter_VL=0;%VL������
        for n=1:n_loop
            
            % ȷ����ǰn��CNo�Ĳ�����λ��
%         N_CNo_sampling=mod(     n   ,    floor(  n_loop/length(C_N0_dB)    )    ) ;
        N_CNo_sampling = floor(n/(  n_loop/length(C_N0_dB)))+1;
        %���ݵ�ǰCNo�Ӷ�Ӧ���ʵ�����
        C_N0=10.^(C_N0_dB(N_CNo_sampling)/10);
        N0=C./C_N0;%���������������ܶ�
        I_NoisePower=N0*BW*f_sample/BW;%�ڽ��մ����ڵ���������,��Ϊ���˲����������ʼ�Ϊ�˴���BW/fsample��Ϊ��ʹ�˲����������ʱ���2N0*BW(��Ƶ������������ܶȱ�2��)���ڴ˴�����fsample/BW
        Q_NoisePower=N0*f_sample;

            t_Subcarrier_ref_end=t_Subcarrier_ref_begin+Tp;t_code_ref_end=t_code_ref_begin+Tp;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%
    [s_code_ref_E,t]=yt_BOCs_function_Dual_Estimate_Solution(c,t_code_ref_begin+d_code/2,t_code_ref_end+d_code/2,t_Subcarrier_ref_begin,t_Subcarrier_ref_end,Tc,fs,f_sample);
    [s_code_ref_L,t]=yt_BOCs_function_Dual_Estimate_Solution(c,t_code_ref_begin-d_code/2,t_code_ref_end-d_code/2,t_Subcarrier_ref_begin,t_Subcarrier_ref_end,Tc,fs,f_sample);    
    [s_Subcarrier_ref_E,t]=yt_BOCs_function_Dual_Estimate_Solution(c,t_code_ref_begin,t_code_ref_end,t_Subcarrier_ref_begin+d_Subcarrier/2,t_Subcarrier_ref_end+d_Subcarrier/2,Tc,fs,f_sample);
    [s_Subcarrier_ref_L,t]=yt_BOCs_function_Dual_Estimate_Solution(c,t_code_ref_begin,t_code_ref_end,t_Subcarrier_ref_begin-d_Subcarrier/2,t_Subcarrier_ref_end-d_Subcarrier/2,Tc,fs,f_sample);   

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

             N_zong=length(t);
             %%%%%%%%%%%%%%%%%%%%%%%%%%   
             %%
            S_receiver_I=sqrt(2*C)*S_CA_receiver+sqrt(I_NoisePower)*randn(1,N_zong);
            S_receiver_Q=sqrt(Q_NoisePower)*randn(1,N_zong);

            fft_sig  = fft(S_receiver_I + 1i*S_receiver_Q);
            L_res   = round(BW/f_sample/2*N_zong);
            fft_sig(L_res+1:end-L_res)  = 0;
            sigBandL = ifft(fft_sig);
            RecSigI = real(sigBandL);
            RecSigQ = imag(sigBandL);

        Int_code_Ie = sum(s_code_ref_E.* RecSigI)/N_zong;Int_code_Il = sum(s_code_ref_L.* RecSigI)/N_zong;
        Int_code_Qe = sum(s_code_ref_E.* RecSigQ)/N_zong;Int_code_Ql = sum(s_code_ref_L.* RecSigQ)/N_zong;
        
        Int_Subcarrier_Ie = sum(s_Subcarrier_ref_E.* RecSigI)/N_zong;Int_Subcarrier_Il = sum(s_Subcarrier_ref_L.* RecSigI)/N_zong;
        Int_Subcarrier_Qe = sum(s_Subcarrier_ref_E.* RecSigQ)/N_zong;Int_Subcarrier_Ql = sum(s_Subcarrier_ref_L.* RecSigQ)/N_zong;



            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
        DiscrimOut_code= (Int_code_Ie^2+Int_code_Qe^2)-(Int_code_Il^2+Int_code_Ql^2);%
        DiscrimOut_Subcarrier= (Int_Subcarrier_Ie^2+Int_Subcarrier_Qe^2)-(Int_Subcarrier_Il^2+Int_Subcarrier_Ql^2);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%
        error_code_x(n)=(t_begin-t_code_ref_begin)/Tc;%��ʵ���
        error_code_y(n)=DiscrimOut_code;%���������
        error_Subcarrier_x(n)=(t_begin-t_Subcarrier_ref_begin)/Tc;%��ʵ���
        error_Subcarrier_y(n)=DiscrimOut_Subcarrier;%���������
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
        Filter_code_output=DiscrimOut_code*Dz_code;%һ�׻�·�˲���
        Filter_Subcarrier_output=DiscrimOut_Subcarrier*Dz_Subcarrier;%һ�׻�·�˲���

       %%
        %����ʱ�ӹ���
        t_code_ref_begin=t_code_ref_begin+Filter_code_output*Tc;
        t_Subcarrier_ref_begin=t_Subcarrier_ref_begin+Filter_Subcarrier_output*Tc;
       %%
        t_estimate_begin=t_Subcarrier_ref_begin+round((t_code_ref_begin-t_Subcarrier_ref_begin)/Ts)*Ts;%��ʵ����ʱ��
        real_error(n)=(t_begin-t_estimate_begin)/Tc;%�������
        
        temp_state(n)=abs(round((t_code_ref_begin-t_Subcarrier_ref_begin)/Ts));

            temp_string=['������' num2str(    n/n_loop*100  ) '%'];
            waitbar((n)/(n_loop),h_wait,temp_string);
%             toc;
        end
%         TrackErrSTD(k)=std(error_x);
        
%     end
    
% end
savefile='CNo_desrease_test_DET_method_BOC_10_5_30M_01Tc.mat';
save(savefile);


close(h_wait);
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% plot false lock index
figure;plot(n_loop,real_error,n_loop,error_code_x,n_loop,error_Subcarrier_x,'Linwidth',2);grid on;
xlabel('Time (ms)');
ylabel('Code tracking error (chips)');
legend('real DET','code loop','subcarrier loop');
saveas(gcf,'CNo_desrease_test_DET_method_BOC_10_5_30M_01Tc');
