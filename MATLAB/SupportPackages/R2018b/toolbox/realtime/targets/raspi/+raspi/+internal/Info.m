classdef (Sealed = false) Info < hgsetget
%INFO Base class for info object used by the build process
    
% Copyright 2011 The MathWorks, Inc.
    
    
    %% Properties
    properties %(SetAccess = 'private')
        Data;
    end
    
    properties(Constant)
    end
    
    %% Public Methods
    methods
        function h = Info()
            h.Data = [];
        end
        
        function h = serialize(h, fileName) %#ok<INUSD>
        end
        
        function deserialize(h, fileName, varargin)
            deserializeM(h, fileName, varargin{:});
        end
        
        function set(h, property, value)
            h.(property) = value;
        end
    end
    
    %% Private helper methods
    methods (Access = 'private')
        function deserializeCS(h, fileName)
            if ~exist(fullfile(fileName), 'file')
                return
            end
            fid = fopen(fileName);
            info = textscan(fid, '%q%q', 'Delimiter', '#', 'CommentStyle', '%');
            fclose(fid);
            h.Data = info;
        end
        
        function deserializeM(h, fileName, varargin)
            try
                info = feval(fileName, varargin{:});
                infofields = fields(info);
                for i=1:length(infofields)
                    set(h, (infofields{i}), info.(infofields{i}));
                end
            catch ME %#ok<NASGU>
                % OK, means no data of this type registered
            end
        end
    end
end
