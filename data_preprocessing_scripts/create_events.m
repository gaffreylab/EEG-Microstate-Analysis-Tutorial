% ********************************************************************** %
% Baby Preprocessing Script 2: Inserting Events
% Authors: Armen Bagdasarov
% Institution: Duke University
% Date Last Modified: 2023-06-04
% ********************************************************************** %

function [EEG, info] = create_events(EEG)

% From files with 10 'bgin' events this script will:
% - Relabel those events with 'start'
% - Generate "end" events to mark 90 seconds after beginning of event
% - Do checks and warn if any epochs overlap
% - Do checks and warn if any epoch is too short (goes off end of file)

% Read data out of event
evt_codes = {EEG.event(:).code};
evt_types = {EEG.event(:).type};
evt_lats = [EEG.event(:).latency];

% Find 'bgin' events
rs_evt_ind = find(strcmp('bgin', evt_codes));

% Label 'start'
[ EEG.event(rs_evt_ind(1:end)).code ] = deal('start');
[ EEG.event(rs_evt_ind(1:end)).type ] = deal('start');

% Add new events that mark the end of each period
nevt = length(EEG.event);
evt_template = EEG.event(rs_evt_ind(1)); % Make a "template" event from first event
evt_newlats = [EEG.event(rs_evt_ind).latency] + 93*EEG.srate;

% Ensure no event goes off end of the file, move events to within 10 pnts
% of end of file (leaving a little buffer for resampling/filtering)
evt_newlats_from_end = EEG.pnts - evt_newlats;
evt_newlats = min(evt_newlats, EEG.pnts-10);

[~, si] = sort([evt_lats, evt_newlats]); % Need to sort in case a block is shorter than 90s
EEG.event(si <= nevt) = EEG.event(:); % Spread out old events

% Fill in values of new 'end' events
[EEG.event(si > nevt)] = deal(EEG.event(rs_evt_ind(1))); % Generate new events by copying first 'bgin'
[EEG.event(si > nevt).code] = deal('end'); % Fix events by filling in important fields
[EEG.event(si > nevt).type] = deal('end');
[EEG.event(si > nevt).begintime] = deal('');
evt_newlats = mat2cell(evt_newlats, [1], ones(1, length(evt_newlats)));
[EEG.event(si > nevt).latency] = evt_newlats{:};

% See if blocks overlap
begin_ind = ismember({EEG.event(:).code}, {'start'});
end_ind = ismember({EEG.event(:).code}, {'end'});

blocklen = diff([EEG.event(begin_ind).latency EEG.pnts]/EEG.srate);
short_block = find(blocklen < 93);
if ~isempty(short_block)
    warning('Blocks %s too short, length of %s seconds respectively.\n', ...
        mat2str(short_block), mat2str(blocklen(short_block)));
    info.block_overlap = true;
    info.block_int = blocklen;
else
    info.block_overlap = false;
    info.block_int = blocklen;
end

% See if any block has been ended early because it exceeded length of file (or came within 10 points)
if any(evt_newlats_from_end < 10)
    warning('Final %d blocks were truncated by early end of file.', ...
        sum(evt_newlats_from_end <0));
    info.block_truncate = true;
else
    info.block_truncate = false;
end

info.blocklen = ([EEG.event(end_ind).latency] - [EEG.event(begin_ind).latency])/EEG.srate;
