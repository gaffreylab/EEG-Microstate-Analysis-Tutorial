% ********************************************************************** %
% Baby Preprocessing Script 4A: Trim Single Subject
% Authors: Armen Bagdasarov
% Institution: Duke University
% Date Last Modified: 2023-06-04
% ********************************************************************** %

% You will never run this function
% But you will modify fields as needed
% Run baby_rest_trim_loop.m script to run this function in a loop for each subject

function summary_info = baby_rest_trim_subject(varargin)

%% Declare variables as global
global proj

%% Import data
set_filename = proj.set_filenames{proj.currentSub};
EEG = pop_loadset('filename', {set_filename}, 'filepath',...
    'INSERT PATH HERE');
summary_info.currentId = {proj.currentId};

%% Trim data to 180 seconds / 3 minutes
EEG = pop_select( EEG, 'trial',[1:180]); % Modify as you wish

%% Save final preprocessed files

% .bva format (good format for Cartool)
bva_path = 'INSERT PATH HERE'; 
bva_name = [proj.currentId '_1min'];
pop_writebva(EEG, fullfile(bva_path, bva_name));

% ****************************** THE END ******************************* %