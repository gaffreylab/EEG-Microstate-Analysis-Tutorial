% ********************************************************************** %
% Baby Preprocessing Script 3A: Preprocessing Single Subject
% Authors: Armen Bagdasarov
% Institution: Duke University
% Date Last Modified: 2023-06-04
% ********************************************************************** %

% You will never run this function
% But you will modify fields as needed
% Run baby_rest_process_loop.m script to run this function in a loop for each subject

function summary_info = baby_rest_process_subject(varargin)

%% Declare variables as global
% Global variables are those that you can access in other functions
global proj

% ********************************************************************** %

%% Reset the random number generator to try to make the results replicable 
% This produces consistent results for clean_rawdata functions 
% and ICA which can vary by run
rng('default');

% ********************************************************************** %

%% Import data
set_filename = proj.set_filenames{proj.currentSub};
EEG = pop_loadset('filename', {set_filename}, 'filepath',...
    'INSERT PATH HERE');
summary_info.currentId = {proj.currentId};

% ********************************************************************** %

%% Filter

% Low-pass filter at 40 Hz and high-pass filter at 1 Hz
EEG = pop_eegfiltnew(EEG, 'hicutoff', 40); 
    % Because low-pass filter is applied at 40 Hz (needed for microstates), 
    % we don't have to worry too much about line noise at 60 Hz
    % However, there will still be some line noise which we will deal with later
EEG = pop_eegfiltnew(EEG, 'locutoff', 1); % 1 Hz needed for microstates

% ********************************************************************** %

%% CleanLine to remove 60 Hz line noise

EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',1:EEG.nbchan ,'computepower',1,...
    'linefreqs',60,'newversion',0,'normSpectrum',0,'p',0.01,'pad',2,...
    'plotfigures',0,'scanforlines',1,'sigtype','Channels','taperbandwidth',2,...
    'tau',50,'verb',1,'winsize',4,'winstep',1);
% All are default parameters, except tau changed from 100 to 50, 
% which is recomended by the authors for continuous unepoched data

% ********************************************************************** %

%% Reject bad channels

% Save variable with reduced (105) channel locations (WITH Cz/E129)
all_chan_locs = EEG.chanlocs;

% Remove online reference (Cz/E129), which is flat (we will add it back in later when re-referencing)
EEG = pop_select(EEG, 'nochannel', {'E129'});

% Save variable with reduced (104) channel locations (but WITHOUT Cz/E129)
% This will be needed later when interpolating bad channels
reduced_chan_locs = EEG.chanlocs;

EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8,...
    'LineNoiseCriterion',4,'Highpass','off','BurstCriterion','off',...
    'WindowCriterion','off','BurstRejection','off','Distance','Euclidian',...
    'MaxMem', 60); 
        % All default settings
        % Only rejecting bad channels, everything else (ASR) turned off
        % MaxMem = 60gb for reproducibility (this will vary based on RAM...
        % so you should adjust accordingly)


% Save which channels were bad in summary info
if isempty(EEG.chaninfo.removedchans) % If no bad chans...
    summary_info.bad_chans = {[]}; % ...then leave blank
else
    bad_chans = {EEG.chaninfo.removedchans(:).labels};
    summary_info.bad_chans = {strjoin(bad_chans)};

    % Plot bad channels to identify whether there are clusters of bad channels
    bad_chan_ind = find(ismember({reduced_chan_locs(:).labels}, bad_chans));
    figure; topoplot(bad_chan_ind, reduced_chan_locs, 'style', 'blank', ...
        'emarker', {'.','k',[],10}, 'electrodes', 'ptslabels');

    % Save bad channels plot
    set(gcf, 'Units', 'Inches', 'Position', [0, 0, 10, 10], 'PaperUnits', ...
        'Inches', 'PaperSize', [10, 10])
    bad_chan_plot_path = 'INSERT PATH HERE'; 
    bad_chan_plot_name = [proj.currentId '_2_prep'];
    saveas(gca, fullfile(bad_chan_plot_path, bad_chan_plot_name), 'png');
    close(gcf);
end

% Save number of bad channels in summary info
summary_info.n_bad_chans = length(EEG.chaninfo.removedchans);

% ********************************************************************** %

%% Interpolate removed bad channels, add Cz/E129 back in, and re-reference to the average
EEG = pop_interp(EEG, reduced_chan_locs, 'spherical');
EEG.data(105,:) = zeros(1, EEG.pnts);
EEG.chanlocs = all_chan_locs;
EEG = pop_reref( EEG, []);

% ********************************************************************** %

%% Remove large artifacts

% Artifact Subspace Reconstruction (ASR) + 
% additional removal of bad data periods

% First, save data before ASR
% ICA will be run later on the data post-ASR
% But ICA fields will be applied to the to the pre-ASR data
EEG_no_rej = EEG;

% ASR
% All default settings
% Most importantly the burst criterion is set conservatively to 20 
% and burst rejection is set to on (meaning remove instead of fix bad data)
EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off',...
    'LineNoiseCriterion','off','Highpass','off','BurstCriterion',20,...
    'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian',...
    'WindowCriterionTolerances',[-Inf 7], 'MaxMem', 60); 
        % MaxMem set to 60gb for reproducibility 
        % But you should modify based on your machine

% Save how many seconds of data is left after ASR in summary info
% This will be important later for excluding participants 
% For example, if ICA was run only on 30 seconds of data because ASR cut
% out the rest, we should get rid of the file (i.e., their
% data was probably very noisy)... not enough data for ICA to be reliable
summary_info.post_ASR_data_length = EEG.xmax;

% Rereference again to reset the data to zero-sum across channels
EEG = pop_reref( EEG, []);

% ********************************************************************** %

%% ICA
% Extended infomax ICA with PCA dimension reduction
% PCA dimension reduction is necessary because of the large number of 
% channels and relatively short amount of data
EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'pca', 50);
    % This number (50) will depend on your data so you will have to modify
    % And accordingly modify saving of components below 

% Save ICA plot
ica_plot_path = 'INSERT PATH HERE'; 
ica_plot_name = [proj.currentId '_3_prep'];
pop_topoplot(EEG, 0, [1:50], 'Independent Components', 0, 'electrodes','off');
set(gcf, 'Units', 'Inches', 'Position', [0, 0, 10, 10], 'PaperUnits', ...
    'Inches', 'PaperSize', [10, 10])
saveas(gca, fullfile(ica_plot_path, ica_plot_name), 'png');
close(gcf);

% ********************************************************************** %

%% Select IC components related to eye or muscle artifact only

% Automatic classification with ICLabel
EEG = pop_iclabel(EEG, 'default');

% Flag components with >= 70% of being eye or muscle
EEG = pop_icflag(EEG, [NaN NaN; 0.7 1; 0.7 1; NaN NaN; NaN NaN; ...
    NaN NaN; NaN NaN]);

% Select components with >= 70% of being eye or muscle
eye_prob = EEG.etc.ic_classification.ICLabel.classifications(:,3);
muscle_prob = EEG.etc.ic_classification.ICLabel.classifications(:,2);
eye_rej = find(eye_prob >= .70);
muscle_rej = find(muscle_prob >= .70);
eye_muscle_rej = [eye_rej; muscle_rej];
eye_muscle_rej = eye_muscle_rej';

% Save retained variance post-ICA in summary info
[projected, pvar] = compvar(EEG.data, {EEG.icasphere, EEG.icaweights}, EEG.icawinv, eye_muscle_rej);
summary_info.var_retained = 100-pvar;

% Plot only the removed components
ica_rej_plot_path = 'INSERT PATH HERE'; 
ica_rej_plot_name = [proj.currentId '_4_prep'];
figure % This line is necessary for if there is only 1 component to plot
pop_topoplot(EEG, 0, eye_muscle_rej, 'Independent Components', 0, ...
    'electrodes','off');
set(gcf, 'Units', 'Inches', 'Position', [0, 0, 10, 10], 'PaperUnits', ...
    'Inches', 'PaperSize', [10, 10])
saveas(gca, fullfile(ica_rej_plot_path, ica_rej_plot_name), 'png');
close(gcf); close(gcf); % Need to close twice if there is only 1 component to plot

% ********************************************************************** %

%% Copy EEG ICA fields to EEG_no_rej and remove ICs with >= 70% of being eye or muscle
% Basically, back-projecting the ICA information from the ASR-reduced data 
% to the full pre-ASR data

EEG_no_rej.icawinv = EEG.icawinv;
EEG_no_rej.icasphere = EEG.icasphere;
EEG_no_rej.icaweights = EEG.icaweights;
EEG_no_rej.icachansind = EEG.icachansind;

EEG = EEG_no_rej; % Set EEG to the one with full data length, pre-ASR

% Remove components with >= 70% of being eye or muscle
EEG = pop_subcomp(EEG, eye_muscle_rej , 0);

if isempty(eye_muscle_rej) % If no ICs removed...
    summary_info.ics_removed = {[]}; % ...then leave blank
else
    % Save which components were removed in summary info
    summary_info.ics_removed = {num2str(eye_muscle_rej)};
end

% Save the number of components removed in summary info
summary_info.n_ics_removed = length(eye_muscle_rej);

% ********************************************************************** %

%% Additional artifact rejection
% At this point, the file is still the original length
% But it likely contians artifact 
% Epoch the data and use the TBT plug-in to reject epochs
% This plug-in also does epoch-by-epoch channel interpolation, which is nice
% You might want to change some fields here depending on your preferences

% First epoch the data into 1 second segments
EEG = eeg_regepochs(EEG, 'recurrence', 1, 'rmbase', NaN);

% 1. Abnormal values
% Simple voltage thresholding of -150/+150 uV
EEG = pop_eegthresh(EEG, 1, 1:EEG.nbchan, -150 , 150 ,0 , 0.996, 1, 0);

% 2. Improbable data
% Based on joint probability, SD = 3 for both local and global thresholds 
EEG = pop_jointprob(EEG, 1, 1:EEG.nbchan, 3, 3, 1, 0, 0);

% Reject based on the epochs selected above
EEG = pop_TBT(EEG, EEG.reject.rejthreshE | EEG.reject.rejjpE, 10, 1, 0);
    % Do epoch interpolation on both types of artifact rejection at once
    % Criteria must be met in at least 10 channels for the epoch to be rejected
    % Don't want to remove channels, so criteria must be met in all 
    % channels for the channel to be removed, which is unlikely to happen

% Save how many epochs are left 
summary_info.n_epochs = EEG.trials;

% ********************************************************************** %

%% Plot Channel Spectra
spectra_time = EEG.xmax * 1000;
figure; pop_spectopo(EEG, 1, [0  spectra_time], 'EEG' , 'freqrange',...
    [2 80],'electrodes','off');

% Save channel spectra plot
spectra_plot_path = 'INSERT PATH HERE'; 
spectra_plot_name = [proj.currentId '_5_prep'];
saveas(gca, fullfile(spectra_plot_path, spectra_plot_name), 'png');
close(gcf);

% ********************************************************************** %

%% Save final preprocessed files
% in .set format
set_path = 'INSERT PATH HERE'; 
set_name = [proj.currentId '_6_prep_complete'];
pop_saveset(EEG, fullfile(set_path, set_name));

% ****************************** THE END ******************************* %
