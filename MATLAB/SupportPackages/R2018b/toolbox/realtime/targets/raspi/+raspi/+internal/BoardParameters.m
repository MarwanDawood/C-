classdef BoardParameters
    %BOARDPARAMETERS Manage default board parameters
    %   Manages default board parameters for Linux targets.
    %  
    
    properties
        BoardName
    end
    
    properties (Constant, Hidden)
        DEFAULTHOSTNAMEPREF = 'DefaultIpAddress';
        DEFAULTUSERNAMEPREF = 'DefaultUserName';
        DEFAULTPASSWORDPREF = 'DefaultPasswordPref';
        DEFAULTPORTPREF     = 'DefaultPortPref';
        DEFAULTBUILDDIRPREF = 'DefaultBuildDirPref';
        GROUP               = 'Hardware_Connectivity_Installer';
    end
    
    methods
        function obj = BoardParameters(boardName)
            % Manage board parameters.
            if (nargin > 0)
                obj.BoardName = regexprep(boardName, '\s', '');
            end
        end
        
        function [hostName, userName, password, port, buildDir] =  getBoardParameters(obj)
            % Return board parameters for the board named boardName
            if nargout > 0
                hostName = obj.getParam('hostName');
            end
            if nargout > 1
                userName = obj.getParam('userName');
            end
            if nargout > 2
                password = obj.getParam('password');
            end
            if nargout > 3
                port = obj.getParam('port');
            end
            if nargout > 4
                buildDir = obj.getParam('buildDir');
            end
        end
        
        function clearBoardParams(obj)
            raspi.internal.BoardParameters.removePref(obj.BoardName, obj.DEFAULTHOSTNAMEPREF);
            raspi.internal.BoardParameters.removePref(obj.BoardName, obj.DEFAULTUSERNAMEPREF);
            raspi.internal.BoardParameters.removePref(obj.BoardName, obj.DEFAULTPASSWORDPREF);
            raspi.internal.BoardParameters.removePref(obj.BoardName, obj.DEFAULTPORTPREF);
            raspi.internal.BoardParameters.removePref(obj.BoardName, obj.DEFAULTBUILDDIRPREF);
        end

        function ret = getParam(obj, parameterName)
            % Get parameter for a board
            switch lower(parameterName)
                case {'hostname', 'ipaddress'}
                    ret = raspi.internal.BoardParameters.getPref(...
                        obj.BoardName, obj.DEFAULTHOSTNAMEPREF);
                    if isempty(ret) || ~isa(ret, 'char')
                        % MATLAB preference for hostname is not set
                        ret = '';
                    end
                case 'username'
                    ret = raspi.internal.BoardParameters.getPref(...
                        obj.BoardName, obj.DEFAULTUSERNAMEPREF);
                    if isempty(ret) || ~isa(ret, 'char')
                        ret = '';
                    end
                case 'password'
                    ret = raspi.internal.BoardParameters.getPref(...
                        obj.BoardName, obj.DEFAULTPASSWORDPREF);
                    if ~isa(ret, 'char')
                        ret = '';
                    end
                case 'port'
                    ret = raspi.internal.BoardParameters.getPref(...
                        obj.BoardName, obj.DEFAULTPORTPREF);
                    if ~isnumeric(ret)
                        ret = [];
                    end
                case 'builddir'
                    ret = raspi.internal.BoardParameters.getPref(...
                        obj.BoardName, obj.DEFAULTBUILDDIRPREF);
                    if isempty(ret) || ~isa(ret, 'char')
                        userName = obj.getParam('userName');
                        ret = ['/home/', userName];
                    end
                otherwise
                    % Note case sensitive
                    ret = raspi.internal.BoardParameters.getPref(...
                        obj.BoardName, ['Default' parameterName, 'Pref']);
                    if isempty(ret)
                        ret = '';
                    end
            end
        end

        function setParam(obj, parameterName, parameterValue)
            % Set parameter for a board
            switch lower(parameterName)
                case {'hostname', 'ipaddress'}
                    raspi.internal.BoardParameters.setPref(...
                        obj.BoardName, obj.DEFAULTHOSTNAMEPREF, ...
                        parameterValue);
                case 'username'
                    raspi.internal.BoardParameters.setPref(...
                        obj.BoardName, obj.DEFAULTUSERNAMEPREF, ...
                        parameterValue);
                case 'password'
                    raspi.internal.BoardParameters.setPref(...
                        obj.BoardName, obj.DEFAULTPASSWORDPREF, ...
                        parameterValue);
                case 'port'
                    raspi.internal.BoardParameters.setPref(...
                        obj.BoardName, obj.DEFAULTPORTPREF, ...
                        parameterValue);
                case 'builddir'
                    raspi.internal.BoardParameters.setPref(...
                        obj.BoardName, obj.DEFAULTBUILDDIRPREF, ...
                        parameterValue);
                otherwise
                    % Note case sensitive
                    raspi.internal.BoardParameters.setPref(...
                        obj.BoardName, ...
                        ['Default' parameterName, 'Pref'], ...
                        parameterValue);
            end
        end
        
        function removeParam(obj, parameterName)
            % Remove a parameter from save list
            switch lower(parameterName)
                case {'hostname', 'ipaddress'}
                    raspi.internal.BoardParameters.removePref(...
                        obj.BoardName, obj.DEFAULTHOSTNAMEPREF);
                case 'username'
                    raspi.internal.BoardParameters.removePref(...
                        obj.BoardName, obj.DEFAULTUSERNAMEPREF);
                case 'password'
                    raspi.internal.BoardParameters.removePref(...
                        obj.BoardName, obj.DEFAULTPASSWORDPREF);
                case 'port'
                    raspi.internal.BoardParameters.removePref(...
                        obj.BoardName, obj.DEFAULTPORTPREF);
                case 'builddir'
                    raspi.internal.BoardParameters.removePref(...
                        obj.BoardName, obj.DEFAULTBUILDDIRPREF);
                otherwise
                    % Note case sensitive
                    raspi.internal.BoardParameters.removePref(...
                        obj.BoardName, ...
                        ['Default' parameterName, 'Pref']);
            end
        end
    end
    
    methods (Static, Hidden)
        function prefGroup = getPrefGroup(group)
            prefGroup = raspi.internal.BoardParameters.GROUP;
            prefGroup = strcat(prefGroup, '_', group);
        end
        
        % Return the preferences value
        function setPref(group, pref, value)
            prefGroup = raspi.internal.BoardParameters.getPrefGroup(group);
            setpref(prefGroup, pref, value);
        end

        % Get preferences value
        function prefValue = getPref(group, pref)
            prefGroup = raspi.internal.BoardParameters.getPrefGroup(group);
            if ispref(prefGroup, pref)
                prefValue = getpref(prefGroup, pref);
            else
                prefValue = [];
            end
        end
        
        function removePref(group, pref)
            prefGroup = raspi.internal.BoardParameters.getPrefGroup(group);
            if ispref(prefGroup, pref)
                rmpref(prefGroup, pref);
            end
        end
    end
end

