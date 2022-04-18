function Raspberrypi_MAT_stitcher(varargin)
% Raspberrypi_MAT_stitcher stitches MAT-files logged on embedded targets using SD card logging feature.
%
% Raspberrypi_MAT_stitcher(dir('*.mat')) stitches all the MAT-files starting with the same
% name in the current directory. The order of the stitching is based on the numeric characters found at the
% end of the file name.
% For example, if the directory contains following files:
%     Test_1_Logging0.mat
%     Test_1_Logging1.mat
%     Test_2_Logging0.mat
%     Test_2_Logging1.mat
%     Test_2_Logging2.mat
%
% The stitcher creates Test_1_Logging_stitched.mat and
% Test_2_Logging_stitched.mat files in the present working directory. All
% the data points logged in Test_1_Logging0.mat and Test_1_Logging1.mat files are
% copied to Test_1_Logging_stitched.mat file. All the data points logged in
% Test_2_Logging0.mat, Test_2_Logging1.mat, and Test_2_Logging2.mat files
% are copied to Test_2_Logging_stitched.mat file.
% 
% Raspberrypi_MAT_stitcher() is equivalent to Raspberrypi_MAT_stitcher(dir('*.mat')).
%
% In the stitcher function, you can specify the file and directory name in the following ways:
%
% To run the stitcher function on a folder, use Raspberrypi_MAT_stitcher('folder_name') command.
%
% "folder_name" is the name of the directory in which the MAT-files are present.
%
% To run the stitcher function on any particular MAT-files use
% Raspberrypi_MAT_stitcher('file_name1.mat', 'file_name2.mat', 'file_name3.mat))
% command. This command stitches the MAT-files in the order in which they are specified in the command.
%
% Copyright 2017-2018 MathWorks, Inc.

dir_prefix = [];
if nargin > 0
    % Case where an array of file struct i.e. dir('*.mat') is passed
    if (nargin == 1) && ...
            isstruct(varargin{1}) && ...
            isfield(varargin{1},'name')
        mat_sorted_list = sort_mat(varargin{1});
        
    elseif isdir(varargin{1}) % Case where a directory is passed as argument
        
        dir_prefix = [varargin{1} filesep];
        mat_sorted_list = sort_mat(dir([dir_prefix '*.mat']));
        
    elseif nargin > 1 && ... % Case where a list of mat files is passed
            isempty(find((cellfun(@isstr,varargin)) == false,1))
        mat_sorted_list(nargin).name = [];
        core_name = [];
        for j = 1:nargin
            if ((exist(varargin{j},'file') == 2) && ...
                    isequal(varargin{j}(end-3:end), '.mat'))
                if isempty(core_name)
                    core_name = extract_core_name(varargin{j});
                end
                mat_sorted_list(j).name = varargin{j};
                mat_sorted_list(j).core_name = core_name;
                
            else
                error(message('raspberrypi:utils:NotMATFile',varargin{j}))
            end
            
        end
    else
        error(message('raspberrypi:utils:InvalidInput',varargin{1}))
    end
else
    % no arguments, taking all the mat files present in the current directory
    mat_sorted_list = sort_mat(dir('*.mat'));
end
% mat list not empty and bigger than 2
if((isempty(mat_sorted_list)) || (size(mat_sorted_list,2)<1))
    error(message('raspberrypi:utils:NoMATFile'))
else
    
    previous_mat = mat_sorted_list(1).core_name;
    current_load = load([dir_prefix mat_sorted_list(1).name]);
    stitch_count = 0;
    for j = 2:length(mat_sorted_list)
        current_mat = mat_sorted_list(j).core_name;
        temp_load = load([dir_prefix mat_sorted_list(j).name]);
        if isequal(previous_mat, current_mat)
            current_load = concat_fields(current_load, temp_load);
            stitch_count = stitch_count + 1;
        else
            if (stitch_count)
                save([previous_mat '_stitched'], '-struct', 'current_load');
            end
            stitch_count = 0;
            previous_mat = current_mat;
            current_load = load([dir_prefix mat_sorted_list(j).name]);
        end
    end
    if ~isempty(current_load)
        if (stitch_count)
            save([previous_mat '_stitched'], '-struct', 'current_load');
        end
    end
end
end

function x = concat_fields(x,y)
fields_x = fieldnames(x);
fields_y = fieldnames(y);
for k = 1:length(fields_x)
    if isfield(y, fields_x{k})
        for l = 1:length(x)
            if (length(y) >= l)
                if isstruct(x(l).(fields_x{k}))
                    x(l).(fields_x{k}) = concat_fields(x(l).(fields_x{k}), y(l).(fields_x{k}));
                else
                    if ~(isequal(fields_x{k}, 'dimensions') || ...
                            isequal(fields_x{k}, 'label') || ...
                            isequal(fields_x{k}, 'title') || ...
                            isequal(fields_x{k}, 'plotStyle') || ...
                            isequal(fields_x{k}, 'inReferencedModel') || ...
                            isequal(fields_x{k}, 'sampleTime') || ...
                            isequal(fields_x{k}, 'blockName'))
                        if ((ndims(x(l).(fields_x{k})) > 2) && ...
                                (ndims(x(l).(fields_x{k})) == ndims(y(l).(fields_x{k})))) %#ok<ISMAT>
                            x(l).(fields_x{k}) = cat(ndims(x(l).(fields_x{k})), x(l).(fields_x{k}), y(l).(fields_x{k}));
                        else
                            x(l).(fields_x{k}) = [x(l).(fields_x{k}); y(l).(fields_x{k})];
                        end
                    end
                end
            end
        end
    end
end
for k = 1:length(fields_y)
    if ~isfield(x, fields_y{k})
        x.(fields_y{k}) = y.(fields_y{k});
    end
end
end

function [core_name, idx] = extract_core_name(mat_name)
inc = 4;
idx_str = [];
while ~isnan(str2double(mat_name(end-inc)))
    idx_str = [mat_name(end-inc) idx_str]; %#ok<AGROW>
    inc  = inc + 1;
end
core_name = mat_name(1:end-inc);
idx = str2double(idx_str);
end

function mat_sorted_list = sort_mat(mat_list)
if(~isempty(mat_list))
    mat_list_length = length(mat_list);
    for j = mat_list_length:-1:1
        if  (isequal(mat_list(j).name(end-3:end), '.mat'))
            %Ignore the files if it is not a MAT file
            mat_temp_list(j).('name') = mat_list(j).name;
            [mat_temp_list(j).('core_name'), mat_temp_list(j).('idx')] = ...
                extract_core_name(mat_list(j).name);
        end
    end
    mat_temp_list(isnan([mat_temp_list.idx])) = [];
    uniquenames = unique({mat_temp_list.core_name});
    mat_sorted_list = [];
    for i = 1:numel(uniquenames)
        unique_name_list = mat_temp_list(strcmp({mat_temp_list.core_name},uniquenames{i}));
        [~, sort_idx] = sort([unique_name_list.idx]);
        unique_name_list = unique_name_list(sort_idx);
        mat_sorted_list = [mat_sorted_list unique_name_list]; %#ok<AGROW>
    end
else
    mat_sorted_list = [];
end
end


