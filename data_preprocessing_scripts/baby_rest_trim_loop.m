% ********************************************************************** %
% Baby Preprocessing Script 4B: Automatic Trim Loop
% Authors: Armen Bagdasarov
% Institution: Duke University
% Date Last Modified: 2023-06-04
% ********************************************************************** %

% Before getting started, make sure EEGLAB folder is in path
% Edit fields as needed and then press Run
% This will run the baby_rest_trim_subject.m script in a loop through all subjects

%% Prepare workspace for preprocessing

% Clear workspace, start EEGLAB, and declare variables as global
clear all;
clc;
eeglab;
global proj

% Path of folder with data saved from the preparation.m script
% Data should be in .set format
proj.data_location = 'INSERT PATH HERE';

% Get file names
proj.set_filenames = dir(fullfile(proj.data_location, '*.set'));
proj.set_filenames = { proj.set_filenames(:).name };

%% Loop over subjects and run baby_rest_trim_subject.m

for i = 1:length(proj.set_filenames)
    proj.currentSub = i;
    proj.currentId = proj.set_filenames{i};
    
    % Subject ID will be filename up to first underscore, or up to first '.'
    % This part may need to be changed depending on how your files are named 
    space_ind = strfind(proj.currentId, '_');
    if ~isempty(space_ind)
        proj.currentId = proj.currentId(1:(space_ind(1)-1)); 
    else
        set_ind = strfind(proj.currentId, '.set');
        proj.currentId = proj.currentId(1:(set_ind(1)-1));
    end
    
    if i == 1
        summary_info = baby_rest_trim_subject;
        summary_tab = struct2table(summary_info);
    else
        summary_info = baby_rest_trim_subject;
        summary_row = struct2table(summary_info); % 1-row table
        summary_tab = vertcat(summary_tab, summary_row); % Append new row to table
    end
       
end
