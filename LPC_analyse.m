clc
clear
close all

[x, Fs] = audioread('好好学习天天向上.wav');
%soundsc(x,Fs);
M = max(x);
for i=1:length(x)
    x(i)=x(i)/M;
end
% 绘制原始信号的图像
subplot(3,2,1);
plot(x);
title('Original Signal');

%% 分帧数
frame_length = 0.025;  % 帧长（单位：秒）
frame_shift = 0.01;    % 帧移（单位：秒）
frame_length = round(frame_length*Fs);  % 帧长（单位：样本数）
frame_shift = round(frame_shift*Fs);    % 帧移（单位：样本数）
frames = buffer(x, frame_length, frame_length-frame_shift, 'nodelay');

%% 计算LPC系数
order = 14;  % LPC阶数
lpc_coeffs = zeros(order+1, size(frames, 2));    %存储LPC系数的矩阵

for i = 1:size(frames, 2)
    lpc_coeffs(:, i) = lpc(frames(:, i), order); %注意LPC函数反回值是A(z)的参数
end
lpc_coeffs(isnan(lpc_coeffs))=0;                 %除去LPC函数返回值的非数值

%% 计算预测信号
predicted_frames = zeros(size(frames));  % 存储预测信号的矩阵

for i = 1:size(frames, 2)
    % 滤波器函数输入不同，此处为线性预测器P(z)参数由lpc_coeffs计算而来，
    % 所以第一项为0剩余相关取相反数；其中lpc_coeffs为预测误差滤波器A(z)的参数
    predicted_frames(:, i) = filter([0;-lpc_coeffs(2:order, i)], 1, frames(:, i));
end

err_frames = predicted_frames-frames;
err = reform(frame_length,frame_shift,err_frames,frames);

%% 由分帧预测信号恢复为时域原始信号
% 绘制预测信号的图像
predicted_frames(isnan(predicted_frames)) = 0;
signal = reform(frame_length,frame_shift,predicted_frames,frames);
%归一化
M = max(signal);
for i=1:length(signal)
   signal(i)=signal(i)/M;
end
subplot(3,2,2);
plot(signal);
title('Predicted Signal');
%% 改变激励信号进行预测（可将声道模型的输入改为自定义的音频文件读入）
%由文件读入
% [newx,Fs_n]=audioread("trumpet-C4.wav");
% newx=newx(:,1);
% newx=resample(newx,Fs,Fs_n);
%% 周期脉冲信号（手动改变频率）
% 确定参数
N = length(x); % 信号长度和预测原信号的长度相同 
n = 1:1:N;
f = 130;       % 周期冲击信号频率(hz)
reserve_n =round(Fs/f);
Periodic_impuse = ones(1,length(n)); %全一数组，输入的信号频率生成不同频率的周期冲激信号
for i=1:length(n)
    if mod(i,reserve_n)==0
        Periodic_impuse(i)=1;
    else 
        Periodic_impuse(i)=0;
    end
end
newx =Periodic_impuse;
subplot(3,2,3);
plot(newx);
title("Periodic_impuse");
%% 白噪声
 noise = randn(length(x), 1);
 M = max(noise);
 for i=1:length(noise)
     noise(i)=noise(i)/M;
 end
 subplot(3,2,5);
 plot(noise);
 title("white noise");

%% 利用声道模型对信号进行处理周期冲激信号
[newy_frames,newx_frames] = track_module(frame_length,frame_shift,newx,lpc_coeffs);
% 合帧
new_signal = reform(frame_length,frame_shift,newy_frames,newx_frames);
%归一化
M = max(new_signal);
for i=1:length(new_signal)
   new_signal(i)=new_signal(i)/M;
   new_signal(i)=new_signal(i);
end
%绘制并且播放声道模型输出
%soundsc(new_signal,Fs);
subplot(3,2,4);
plot(new_signal);
title('Signal out from Periodic impuse');
%% 利用声道模型对信号进行处理白噪声
[noisey_frames,noisex_frames] = track_module(frame_length,frame_shift,noise,lpc_coeffs);
% 合帧
noise_signal = reform(frame_length,frame_shift,noisey_frames,noisex_frames);
%归一化
M = max(noise_signal);
for i=1:length(noise_signal)
   noise_signal(i)=noise_signal(i)/M;
end
%绘制并且播放声道模型输出
% soundsc(noise_signal,Fs);
subplot(3,2,6);
plot(noise_signal);
title(' Signal out from noise');
figure
plot(err);
title("预测误差")

%% 信号通过声道模型
function [newy_frames,newx_frames] = track_module(frame_length,frame_shift,newx,lpc_coeffs)
%参数为（窗长，窗移，输入信号，LPC系数矩阵）
newx_frames = buffer(newx, frame_length, frame_length-frame_shift, 'nodelay');%分帧
newy_frames = zeros(size(newx_frames));%准备输出矩阵

for i = 1:size(newx_frames, 2)
    %滤波器输入参数不同，注意此处为声道模型LPC函数返回的是预测误差滤波器A(z)的参数
    newy_frames(:, i) = filter(1,lpc_coeffs(:, i), newx_frames(:, i));
end

newy_frames(isnan(newy_frames)) = 0;   %去除输出矩阵中的非数值
end

%% 将分帧后的信号恢复（没有做fft变换），该函数没有ifft处理
function signal = reform(frame_length,frame_shift,in_frames,source_frames)
% 参数为（窗长，窗移，处理后的分帧信号，处理前的分帧信号）
% 构造一个N点汉宁窗
N=frame_length;
w = hann(N);
% 将每个帧乘以窗函数
windowed_frames = in_frames .* w;
hop_size =frame_shift;
signal = zeros(1, size(source_frames, 2) * hop_size + N - hop_size);
for i = 1:size(source_frames, 2)
    start_idx = (i-1) * hop_size + 1;
    end_idx = start_idx + N - 1;
    signal(start_idx:end_idx) = signal(start_idx:end_idx) + windowed_frames(:,i)';
end
signal = signal / size(source_frames, 2);
end


