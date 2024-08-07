function RxSpectrogramforCellID(cell_id) 

% Generate waveform containing SS burst and SIB1
    % Configure the cell identity
    config = struct();
    config.NCellID = cell_id;

    % Configure an SS burst
    config.BlockPattern = 'Case B';         % FR1: 'Case A','Case B','Case C'. FR2: 'Case D','Case E'
    config.TransmittedBlocks = ones(1,8);   % Bitmap of SS blocks transmitted
    config.SubcarrierSpacingCommon = 15;    % SIB1 subcarrier spacing in kHz (15 or 30 for FR1. 60 or 120 for FR2)
    config.EnableSIB1 = 1;                  % Set to 0 to disable SIB1

    % Set the minimum channel bandwidth for the NR band required to
    % configure CORESET 0 in FR1 (See TS 38.101-1 Table 5.3.5-1)
    config.MinChannelBW = 5; % 5, 10, 40 MHz

    % Introduce a beamforming gain by boosting the power (and therefore
    % SNR) of one SSB and associated SIB1 PDCCH and PDSCH
    boost = 6; % SNR boost in dB
    config.Power = zeros(size(config.TransmittedBlocks));
    config.Power(1) = boost; % boost the first SSB

    % Configure and generate a waveform containing an SS burst and SIB1
    wavegenConfig = hSIB1WaveformConfiguration(config);
    [txWaveform,waveInfo] = nrWaveformGenerator(wavegenConfig);
    txOfdmInfo = waveInfo.ResourceGrids(1).Info;

    % Add white Gaussian noise to the waveform. Note that the SNR only
    % applies to the boosted SSB / SIB1
    rng('default'); % Reset the random number generator
    SNRdB = 20; % SNR for AWGN
    rxWaveform = awgn(txWaveform,SNRdB-boost,-10*log10(double(txOfdmInfo.Nfft)));

    % Configure receiver
    % Sample rate
    sampleRate = txOfdmInfo.SampleRate;

    % Symbol phase compensation frequency (Hz). The function
    % nrWaveformGenerator does not apply symbol phase compensation to the
    % generated waveform.
    fPhaseComp = 0; % Carrier center frequency (Hz)

    % Minimum channel bandwidth (MHz)
    minChannelBW = config.MinChannelBW;

    % Configure necessary burst parameters at the receiver
    refBurst.BlockPattern = config.BlockPattern;
    refBurst.L_max = numel(config.TransmittedBlocks);


% Get OFDM information from configured burst and receiver parameters
nrbSSB = 20;
scsSSB = hSSBurstSubcarrierSpacing(refBurst.BlockPattern);
rxOfdmInfo = nrOFDMInfo(nrbSSB,scsSSB,'SampleRate',sampleRate);

% Display spectrogram of received waveform
figure;
nfft = rxOfdmInfo.Nfft;
spectrogram(rxWaveform(:,1),ones(nfft,1),0,nfft,'centered',sampleRate,'yaxis','MinThreshold',-130);
title('Spectrogram of the Received Waveform')

end