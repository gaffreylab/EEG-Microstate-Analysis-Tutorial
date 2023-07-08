% ********************************************************************** %
% Baby Preprocessing Script 1: Preparation
% Authors: Armen Bagdasarov
% Institution: Duke University
% Date Last Modified: 2023-06-04
% ********************************************************************** %

% This is not an automated script (do not press Run)
% Follow each step one by one and do not skip any
% Before getting started, make sure EEGLAB folder is in path

% 1. Clear workspace, start EEGLAB, and declare variables as global
clear all;
clc;
eeglab;
global proj;

% 2. Import .mff data by hand in EEGLAB

% 3. Edit to current subject ID
proj.currentId = 'ENTER SUBJECT ID HERE'; 

% 4. Remove 24 outer ring channels
outer_chans = {'E17' 'E38' 'E43' 'E44' 'E48' 'E49' 'E113' 'E114' ...
    'E119' 'E120' 'E121' 'E125' 'E126' 'E127' 'E128' 'E56' 'E63' 'E68' ...
    'E73' 'E81' 'E88' 'E94' 'E99' 'E107'};
EEG = pop_select(EEG, 'nochannel', outer_chans);

% 5. Downsample data from 1000 to 250 Hz 
EEG = pop_resample(EEG, 250);

% 6. Insert events
% This is a function pulling from another script
% Make sure this script is in your path
[EEG, info] = create_events(EEG); 

% 7. Keep only the actual data
% The first 3 seconds are the attention getter, so remove this
% Each trial is 90 seconds
EEG = pop_rmdat(EEG, {'start'}, [3 93] ,0);
% After this step, data should be 900 seconds if all 10 trials were collected
% Not the case for most participants

% 8. Refresh EEGLAB to update data duration
eeglab redraw

% 9. Based on EEG run log, delete trials that are not needed by hand
% Tools -> Inspect/reject data by eye

% 10. Save files in .set format
set_path = 'ENTER PATH HERE'; 
set_name = [proj.currentId '_1_prep'];
pop_saveset(EEG, fullfile(set_path, set_name));
