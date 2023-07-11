EEG Run Log README

eeg_run_log.xlsx

Data segments are 90 seconds long, each representing a video that was played during which EEG was recorded. 

Codes:
1 = entire segment usable
2 = only part of segment usable (next to dash is which part to keep; for example, 2 - first 45s, indicates to keep only the first 45 out of the 90 seconds)
3 = segment was recorded, but entire segment is not usable and should be removed
4 = no data recorded

duration_collected = approximate sum of segments representing codes 1 and 2 above

After Preprocessing: 
duration_clean = number of surviving seconds after preprocessing
ratio_clean = duration_collected / duration_clean
