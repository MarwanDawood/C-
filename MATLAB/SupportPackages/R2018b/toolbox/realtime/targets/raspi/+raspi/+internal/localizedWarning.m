function localizedWarning(id,varargin)
% Display warning without stack trace

% Copyright 2018 The MathWorks, Inc.

% Turn off backtrace for a moment
sWarningBacktrace = warning('off','backtrace');
warning(message(id,varargin{:}));
warning(sWarningBacktrace.state, 'backtrace');
            
end