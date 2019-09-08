function data = parseANLData(filename, time_signal)
%% PARSEANLDATA Simple parser for extracting data from ANL's D3 data files
% This function is a simple utility for extracting data from Argonne
% National Laboratory's Downloadable Dynamometer Database (D3). Each test
% is provided as a .txt file with columnar vectors of measurements from the
% test. Test data can be downloaded from:
%   https://www.anl.gov/es/downloadable-dynamometer-database
% 
% This script is a simple utility for extracting the data into a MATLAB
% structure format. Each signal is provided with a .time, .signals.values,
% and .unit field. The time signal is left with its raw test values, and
% may need to be adjusted back to t=0 if required.
% 
% There is plenty of room for optimization of the code, but for now it
% works as expected.
%
% Because signal names may differ between tests, there are two ways to call
% this function:
%
% data = PARSEANLDATA(filename)
%   - filename: [char] Name of file to parse
%   - data: [struct] Signal output structure
%
% data = PARSEANLDATA(filename, time_signal)
%   - filename: [char] Name of file to parse
%   - time_signal: [char] Name of the "time" signal from the test
%   - data: [struct] Signal output structure
% 

%% Parse the text file
fid = fopen(filename);

line = fgetl(fid);
txt = {};
while ischar(line)
    txt{end+1,1} = line;
    line = fgetl(fid);
end

fclose(fid);

%% Read the headers from the data and prep the data structure
headers = strsplit(txt{1},'\t');
[headers, header_idx] = sort(headers);

unit_regex = '\[.*\]';

data = struct;

for i = 1 : numel(headers)
    header = headers{i};
    [unit_idx_start, unit_idx_end] = regexp(header, unit_regex,'ONCE');
    
    if ~isempty(unit_idx_start)
        unit = header(unit_idx_start : unit_idx_end);
    end
    header(unit_idx_start : unit_idx_end) = [];
    
    % For any signals that start with a numeric value, add "Data_" to them
    % so that they can be valid structure fields
    if isstrprop(header(1),'digit')
        header = ['Data_', header];
    end
    
    header = strrep(header,' ','_');
    headers{i} = header;
    
    if ~exist('time_signal','var') && strcmpi(header,'time')
        time_signal = header;
    end
    
    data.(header) = struct;
    data.(header).unit = strrep(strrep(unit,'[',''),']','');
    data.(header).signals.values = zeros(numel(txt) - 1, 1);
    data.(header).time = [];
end


%% Iteratively append the signal values into the appropriate arrays
for i = 2 : numel(txt)
    data_row = txt{i};
    data_row = strsplit(data_row,'\t');
    
    for j = 1 : numel(data_row)
        header = headers{header_idx==j};
        data.(header).signals.values(i-1) = str2double(data_row{j});
    end
end

%% Assign the time signal to each structure
if ~exist('time_signal','var')
    error('Valid time signal could not be found. Please provide one using parseANLData(..., time_signal)');
end

time = data.(time_signal).signals.values;

for i = 1 : numel(headers)
    data.(headers{i}).time = time;
end

data = rmfield(data,time_signal); % Remove redundant time signal

end