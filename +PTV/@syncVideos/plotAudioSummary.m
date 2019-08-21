function [] = plotAudioSummary(this)
%PLOTAUDIOSUMMARY Plots a summary of the synced audio tracks
%
% AUTHOR: Stefano Simoncelli <simoncelli@igb-berlin.de>

    T = 0:1/this.audioSamplingFrequency:(length(this.audio1Sample)-1)/this.audioSamplingFrequency;

    %% Figures
    figure;
    subplot(221);
    plot(T, this.audio1Sample, 'k-'); 
    title 'Audio #1';

    subplot(223);
    plot(T, this.audio2Sample, 'b-'); 
    title 'Audio #2';
    xlabel 'Time (secs)'

    % Aligned audio signal
    subplot(222);
    T2 = 0:1/this.audioSamplingFrequency:(length(this.audio1SampleShifted)-1)/this.audioSamplingFrequency;
    plot(T2, this.audio1SampleShifted, 'k-');
    title 'Aligned audio #1';
    xlim(T([1 end]));

    subplot(224);
    T2 = 0:1/this.audioSamplingFrequency:(length(this.audio2SampleShifted)-1)/this.audioSamplingFrequency;
    plot(T2, this.audio2SampleShifted, 'b-'); 
    title 'Aligned audio #2';
    xlabel 'Time (secs)'
    xlim(T([1 end]));

end