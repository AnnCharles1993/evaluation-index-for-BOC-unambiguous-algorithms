
clear;
clc;
%%
%����BOC����
c=CA_code(1);%�õ�CA������1
L_CA=length(c);%CA�����г���
m=14;n=2;
Rc=n*1.023e6;%������
Tc=1/Rc;%��Ƭ����
f_sample=100e6;%����Ƶ��
T_sample=1/f_sample;
Tp=1e-3-T_sample;%��ɻ���ʱ��1ms
fs=m*1.023e6;
Ts=1/fs/2;
%%
%%%��������
BW=36*1.023e6;d=0.03*Tc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
N_BW=10000;
f=linspace(-BW/2,BW/2,N_BW);
PSD_BOC=PSDcal_BOCs(f, fs, Tc);
power_loss_filter_dB=10*log10(trapz(f,PSD_BOC));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
C=1;%�ز�����

N_C=1;
% C_N0_dB=linspace(20,45,N_C)-power_loss_filter_dB;
C_N0_dB=45;
C_N0=10.^(C_N0_dB/10);
N0=C./C_N0;%���������������ܶ�
I_NoisePower=N0*BW*f_sample/BW;%�ڽ��մ����ڵ���������,��Ϊ���˲����������ʼ�Ϊ�˴���BW/fsample��Ϊ��ʹ�˲����������ʱ���2N0*BW(��Ƶ������������ܶȱ�2��)���ڴ˴�����fsample/BW
Q_NoisePower=N0*f_sample;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t0=0.0*Ts;%��ʵ����ʱ�䣬��ʼ�����һ����Ƭ��
% t0=-0.9648*Tc;%��introduce false lock
t_begin=t0;
t_end=t_begin+Tp;
t_ref_begin_scan=0;
% n_loop=100000;
n_loop=10000;

Trackerror=zeros(1,n_loop);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%%%%%%BOC(14,2)%%%%%%%%%
% Dz=1.652e-4;
Dz=2.34e-4;
%%
error_x=zeros(1,n_loop);
error_y=zeros(1,n_loop);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[S_CA_receiver,t]=yt_BOCs_function(c,t_begin,t_end,Tc,fs,f_sample);
N_zong=length(t);

TrackErrRMS=zeros(1,N_C);
h_wait=waitbar(0);

Num_false_acquisition=200;
t_ref_begin_scan=linspace(-1*Tc,Tc,Num_false_acquisition);

for m=1:Num_false_acquisition
    for k=1:N_C
        tic;
        t0=0.0*Ts;%��ʵ����ʱ�䣬��ʼ�����һ����Ƭ��

        t_begin=t0;
        t_end=t_begin+Tp;
        t_ref_begin=t_ref_begin_scan(m);
        
        for n=1:n_loop

            t_ref_end=t_ref_begin+Tp;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%
         [s_ref1_E,s_ref2_E,t_E]=yt_WPC_reference_waveform_function(c,t_ref_begin+d/2,t_ref_end+d/2,Tc,fs,f_sample);
         [s_ref1_L,s_ref2_L,t_L]=yt_WPC_reference_waveform_function(c,t_ref_begin-d/2,t_ref_end-d/2,Tc,fs,f_sample);
         [s_ref1_P,s_ref2_P,t_P]=yt_WPC_reference_waveform_function(c,t_ref_begin,t_ref_end,Tc,fs,f_sample);    

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
             %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

             N_zong=length(t);
             %%%%%%%%%%%%%%%%%%%%%%%%%%   
             %%
            S_receiver_I=sqrt(2*C)*S_CA_receiver+sqrt(I_NoisePower(k))*randn(1,N_zong);
            S_receiver_Q=sqrt(Q_NoisePower(k))*randn(1,N_zong);

            fft_sig  = fft(S_receiver_I + 1i*S_receiver_Q);
            L_res   = round(BW/f_sample/2*N_zong);
            fft_sig(L_res+1:end-L_res)  = 0;
            sigBandL = ifft(fft_sig);
            RecSigI = real(sigBandL);
            RecSigQ = imag(sigBandL);

            IE1 = sum(s_ref1_E .* RecSigI)/N_zong;IE2 = sum(s_ref2_E .* RecSigI)/N_zong;
            IL1 = sum(s_ref1_L.* RecSigI)/N_zong;IL2 = sum(s_ref2_L.* RecSigI)/N_zong;
            QE1 = sum(s_ref1_E.* RecSigQ)/N_zong;QE2 = sum(s_ref2_E.* RecSigQ)/N_zong;
            QL1 = sum(s_ref1_L.* RecSigQ)/N_zong;QL2= sum(s_ref2_L.* RecSigQ)/N_zong;



            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
            %% ������1
            DiscrimOut  =IE1*IE2+QE1*QE2-IL1*IL2-QL1*QL2;%������1

        %%
            error_x(n)=(t_begin-t_ref_begin)/Tc;%��ʵ���
            error_y(n)=DiscrimOut;%���������


            Filter_output=DiscrimOut*Dz;%һ�׻�·�˲���

            t_ref_begin=t_ref_begin+Filter_output*Tc;

            Trackerror(n)=(t_ref_begin-t_begin)*3e8;%�������

            temp_string=['������' num2str(floor(((k-1)*n_loop+n+m)/(N_C*n_loop*Num_false_acquisition)*10000)/100) '%'];
            waitbar(((k-1)*n_loop+n+m)/(N_C*n_loop*Num_false_acquisition),h_wait,temp_string);
        end
    end
    TrackErrSTD(m)=std(error_x);
    error_recorder(m,:)=error_x;
    toc;
end
savefile='false_lock_index_yans_method_BOC_10_5_30M_01Tc_45dBHz.mat';
save(savefile);


close(h_wait);
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% plot false lock index
figure;plot(t_ref_begin_scan/Tc,TrackErrSTD,'Linwidth',2);grid on;
xlabel('false acuiqisition results (chips)');
ylabel('code tracking error std (chips)');
saveas(gcf,'false_lock_index_yans_method_BOC_10_5_30M_01Tc_45dBHz');
