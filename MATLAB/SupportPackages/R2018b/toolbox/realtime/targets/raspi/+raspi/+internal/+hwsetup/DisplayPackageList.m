classdef DisplayPackageList < matlab.hwmgr.internal.hwsetup.TemplateBase
    % DisplayPackageList - Screen implementation to display the required packages and libraries
    
    %   Copyright 2017-2019 The MathWorks, Inc.
    %
    
    properties(Hidden)
        Table_pkgs
        Table_lib
        Description
    end
    
    methods
        function obj = DisplayPackageList(workflow)
            % Call to class constructor
            obj@matlab.hwmgr.internal.hwsetup.TemplateBase(workflow)
            
            % Set Title
            obj.Title.Text = message('raspi:hwsetup:DisplayPackageListTitle').getString;
            obj.Description = matlab.hwmgr.internal.hwsetup.Label.getInstance(obj.ContentPanel);
            obj.Description.Text = message('raspi:hwsetup:DisplayPackageListDesc').getString;
            obj.Description.Visible = 'on';
            obj.Description.Position=[20 260 400 120];
            obj.Description.Color = matlab.hwmgr.internal.hwsetup.util.Color.WHITE;
            
            obj.Table_pkgs= matlab.hwmgr.internal.hwsetup.Table.getInstance(obj.ContentPanel);
            obj.Table_pkgs.Position = [20 22 169 302];
            obj.Table_pkgs.ColumnWidth = {150};
            raspbian = raspi.internal.hwsetup.Raspbian;
            obj.Table_pkgs.Data = raspbian.getRequiredPackages;
            obj.Table_pkgs.ColumnName = 'Packages';
            
            obj.Table_lib= matlab.hwmgr.internal.hwsetup.Table.getInstance(obj.ContentPanel);
            obj.Table_lib.Position = [250 220 152 105];
            obj.Table_lib.ColumnWidth = {150};
            obj.Table_lib.Data = raspbian.getRequiredLibraries; 
            obj.Table_lib.ColumnName = 'Libraries';
            
            
            
            obj.HelpText.WhatToConsider = message('raspi:hwsetup:DisplayPackageListConsider').getString;
            obj.HelpText.AboutSelection = '';
            
        end
        
        function out = getPreviousScreenID(obj) %#ok<*MANU>
            out = 'raspi.internal.hwsetup.ConnectforCustomization';
        end
        
        function out = getNextScreenID(obj)
            out = 'raspi.internal.hwsetup.InstallPackages';
        end
       
    end% methods end
end

% LocalWords:  raspi hwsetup Connectfor
