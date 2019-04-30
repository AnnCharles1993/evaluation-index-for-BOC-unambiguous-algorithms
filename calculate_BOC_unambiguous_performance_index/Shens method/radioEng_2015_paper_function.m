function [s1,s2,t]=radioEng_2015_paper_function(c,t_begin,t_end,Tc,fs,fsample,K)
%c��һ�������ڵ���Ƶ������
%t_begin��ʼʱ��
%t_end��ֹʱ��
%Tc��Ƭ���
%fs���ز�Ƶ��
%fsample����Ƶ��
L_code=length(c);
t=t_begin:1/fsample:t_end;
N_Tc=mod(floor(t/Tc),L_code)+1;%ÿ��ʱ����Ӧ����
code=c(N_Tc);
% Subcarrier=sign(sin(floor(t*fs*2)*pi+pi/2));
% s=code.*Subcarrier;
subcarrier1=zeros(1,length(t));
subcarrier2=zeros(1,length(t));

Ts=1/2/fs;
k_index=Tc/Ts;
level=sqrt(k_index);
t_temp=mod(t,Tc);
index1=t_temp<Ts;
index2=t_temp>Tc-Ts;
subcarrier1(index1)=level/sqrt(1+K^2);
subcarrier1(index2)=-K*level/sqrt(1+K^2);


subcarrier2(index1)=K*level/sqrt(1+K^2);
subcarrier2(index2)=-level/sqrt(1+K^2);


s1=code.*subcarrier1;
s2=code.*subcarrier2;