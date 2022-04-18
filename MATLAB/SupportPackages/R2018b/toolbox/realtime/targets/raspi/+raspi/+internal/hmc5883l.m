classdef hmc5883l < handle & matlab.mixin.CustomDisplay
    %HMC5883L Three axis, digital magnetometer.
    %
    % mag = hmc5883l(rpi, bus) creates a HMC5883L object attached to the
    % specified I2C bus. The first parameter, rpi, is a raspi object. The
    % I2C address of the HMC5883L defaults to '0x1E'.
    %
    % OUT = readMagneticField(mag) reads the X, Y and Z components of the
    % magnetic field and returns it in a row vector, OUT. 
    %
    % The SamplesPerSecond property determines the number of magnetic field
    % measurements per second. The OversamplingRatio determines number of
    % samples averaged per magnetic field reading. The Sensitivity property
    % determines maximum field strength that can be measured and
    % resolution. For example, setting Sensitivity to '0.88' results
    % in highest resolution of 0.73 (mG/LSb).
    %
    % <a href="http://dlnmh9ip6v2uc.cloudfront.net/datasheets/Sensors/Magneto/HMC5883L-FDS.pdf">Device Datasheet</a>
    
    % Copyright 2014-2015 The MathWorks, Inc.
    
    properties (Constant)
        Address = '0x1E' % Default address of 0x0E
        OperatingMode = 'Continuous'
    end
    
    properties (Access=public)
        SamplesPerSecond  = 15
        OversamplingRatio = 1
        Sensitivity = 1.3;
    end
    
    properties (Dependent, Access=private)
        CRA_MA_BITS
        CRA_DO_BITS
        CRA_MS_BITS
        CRA_BITS
        CRB_BITS
        MODE_BITS
        Scale
    end
    
    properties (Hidden)
        Debug = false
    end
    
    properties (Hidden, Constant)
        AvailableSamplesPerSecond = [0.75, 1.5, 3, 7.5, 15, 30, 75]
        AvailableOversamplingRatio = [1, 2, 4, 8]
        AvailableSensitivity = [0.88, 1.3, 1.9, ...
            2.5, 4.0, 4.7, 5.6 8.1];
    end
    
    properties (Access = private)
        i2cObj
        REG_CACHE
        Initialized = false
    end
    
    properties (Constant, Access = private)
        % Register addresses
        CRA_REG       = 0
        CRB_REG       = 1
        MODE_REG      = 2
        OUT_X_MSB_REG = 3
        OUT_X_LSB_REG = 4
        OUT_Z_MSB_REG = 5
        OUT_Z_LSB_REG = 6
        OUT_Y_MSB_REG = 7
        OUT_Y_LSB_REG = 8
        STATUS_REG    = 9
        ID_A_REG      = 10
        ID_B_REG      = 11
        ID_C_REG      = 12
    end
    
    methods
        function obj = hmc5883l(hw, bus, samplesPerSecond, oversamplingRatio, sensitivity)
            if nargin > 2
                obj.SamplesPerSecond = samplesPerSecond;
            end
            if nargin > 3
                obj.OversamplingRatio = oversamplingRatio;
            end
            if nargin > 4
                obj.Sensitivity = sensitivity;
            end
            
            % Create an i2cdev object to talk to ADS1115
            obj.i2cObj = i2cdev(hw, bus, obj.Address);
            testDevice(obj);
            initializeDevice(obj);
        end
        
        function out = readMagneticField(obj)
            val = readRegister(obj.i2cObj, obj.OUT_X_MSB_REG, 'int16', 3);
            % z is the second int16 value and y us the third
            out = obj.Scale * double(swapbytes(val([1 3 2])));
        end
    end
    
    
    methods
        function set.Sensitivity(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'Sensitivity');
            if ~ismember(value, obj.AvailableSensitivity)
                error('raspi:utils:InvalidSensitivity', ...
                    'Invalid Sensitivity. Valid values for Sensitivity are: %s', ...
                    sprintf('%0.2f ', obj.AvailableSensitivity));
            end
            obj.Sensitivity = value;
            updateDeviceConfiguration(obj);
        end
        
        function set.SamplesPerSecond(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'DataRate');
            if ~ismember(value, obj.AvailableSamplesPerSecond)
                error('raspi:utils:InvalidDataRate', ...
                    'Invalid DataRate. Valid values for SamplesPerSecond are %s', ...
                    sprintf('%0.2f ', obj.AvailableSamplesPerSecond));
            end
            obj.SamplesPerSecond = value;
            updateDeviceConfiguration(obj);
        end
        
        function set.OversamplingRatio(obj, value)
            validateattributes(value, {'numeric'}, ...
                {'scalar', 'nonnan'}, '', 'OversamplingRatio');
            if ~ismember(value, obj.AvailableOversamplingRatio)
                error('raspi:utils:InvalidOversamplingRatio', ...
                    'Invalid OversamplingRatio. Valid values for OversamplingRatio are: %s', ...
                    sprintf('%d ', obj.AvailableOversamplingRatio));
            end
            obj.OversamplingRatio = value;
            updateDeviceConfiguration(obj);
        end
        
        function value = get.CRA_MA_BITS(obj)
            switch (obj.OversamplingRatio)
                case 1
                    value = 0;
                case 2
                    value = 1;
                case 4
                    value = 2;
                case 8
                    value = 3;
            end
        end
        
        function value = get.CRA_DO_BITS(obj)
            switch (obj.SamplesPerSecond)
                case 0.75,
                    value = 0;
                case 1.5,
                    value = 1;
                case 3,
                    value = 2;
                case 7.5,
                    value = 3;
                case 15,
                    value = 4;
                case 30,
                    value = 5;
                case 75,
                    value = 6;
            end
        end
        
        function value = get.CRA_MS_BITS(obj) %#ok<MANU>
            value = 0; % Normal measurement configuration
        end
        
        function value = get.CRA_BITS(obj)
            value = bitor(bitshift(obj.CRA_MA_BITS, 5), bitshift(obj.CRA_DO_BITS, 2));
            value = bitor(value, obj.CRA_MS_BITS);
        end
        
        function value = get.CRB_BITS(obj)
            switch obj.Sensitivity
                case 0.88,
                    value = 0;
                case 1.3,
                    value = 1;
                case 1.9,
                    value = 2;
                case 2.5,
                    value = 3;
                case 4.0,
                    value = 4;
                case 4.7,
                    value = 5;
                case 5.6,
                    value = 6;
                case 8.1,
                    value = 7;
            end
            value = bitshift(value, 5);
        end
        
        function value = get.Scale(obj)
            switch obj.Sensitivity
                case 0.88,
                    value = 0.73;
                case 1.3,
                    value = 0.92;
                case 1.9,
                    value = 1.22;
                case 2.5,
                    value = 1.52;
                case 4.0,
                    value = 2.27;
                case 4.7,
                    value = 2.56;
                case 5.6,
                    value = 3.03;
                case 8.1,
                    value = 4.35;
            end
        end
        
        function value = get.MODE_BITS(obj)
            switch obj.OperatingMode
                case 'Continuous'
                    value = 0;
                case 'Single-Shot'
                    value = 1;
                case 'Idle',
                    value = 2;
            end
        end
    end
    
    methods (Access = private)
        function testDevice(obj)
            ID_A = readRegister(obj.i2cObj, obj.ID_A_REG, 'uint8');
            ID_B = readRegister(obj.i2cObj, obj.ID_B_REG, 'uint8');
            ID_C = readRegister(obj.i2cObj, obj.ID_C_REG, 'uint8');
            if obj.Debug
                fprintf('ID(A, B, C) = (%x, %x, %x)\n', ID_A, ID_B, ID_C);
            end
            if ID_A ~= bin2dec('01001000') || ID_B ~= bin2dec('00110100') ...
                    || ID_C ~= bin2dec('00110011')
                error('raspi:utils:HMC5883LDeviceTestError', ...
                    ['Error communicating with the HMC5883L sensor. ', ...
                    'The value read from  ID_A, ID_B and ID_C registers do not ', ...
                    'match expected values.']);
            end
        end
        
        function value = readInt16(obj, REG)
            value = obj.i2cObj.readRegister(REG, 'int16');
            %value = double(swapbytes(value));
        end
        
        function initializeDevice(obj)
            % Configure device
            CRA_BITS  = obj.CRA_BITS;
            CRB_BITS  = obj.CRB_BITS;
            MODE_BITS = obj.MODE_BITS;
            configureDevice(obj, CRA_BITS, CRB_BITS, MODE_BITS);
            obj.REG_CACHE = [CRA_BITS, CRB_BITS, MODE_BITS]; % Update cache
            obj.Initialized = true;
        end
        
        function configureDevice(obj, CRA_BITS, CRB_BITS, MODE_BITS)
            writeRegister(obj.i2cObj, obj.CRA_REG, CRA_BITS); 
            writeRegister(obj.i2cObj, obj.CRB_REG, CRB_BITS);
            writeRegister(obj.i2cObj, obj.MODE_REG, MODE_BITS);
            status = readRegister(obj.i2cObj, obj.STATUS_REG);
            if obj.Debug
                fprintf('STATUS_REG = %x', status);
            end
        end
        
        function updateDeviceConfiguration(obj)
            if obj.Initialized
                CRA_BITS  = obj.CRA_BITS;
                CRB_BITS  = obj.CRB_BITS;
                MODE_BITS = obj.MODE_BITS;
                if ~isequal(obj.REG_CACHE, [CRA_BITS, CRB_BITS, MODE_BITS])
                    configureDevice(obj, CRA_BITS, CRB_BITS, MODE_BITS);
                    obj.REG_CACHE = [CRA_BITS, CRB_BITS, MODE_BITS];
                end
            end
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            disp(header);
            
            % Display main options
            fprintf('                Address: ''%s''\n', obj.Address);
            fprintf('          OperatingMode: ''%s''\n', obj.OperatingMode);
            fprintf('       SamplesPerSecond: %-10.2f (0.75, 1.5, 3, 7.5, 15, 30, or 75 Hz)\n', ...
                obj.SamplesPerSecond);
            fprintf('      OversamplingRatio: %-10d (1, 2, 4, or 8)\n', ...
                obj.OversamplingRatio);
            fprintf('            Sensitivity: %-10.2f (0.88, 1.3, 1.9, 2.5, 4.0, 4.7, 5.6, or 8.1 Gauss)\n', ...
                obj.Sensitivity);
            fprintf('\n');
            
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
    
    methods (Static, Access = private)
        function decvalue = hex2dec(hexvalue)
            decvalue = hex2dec(regexprep(hexvalue, '0x', ''));
        end
        
        function hexvalue = dec2hex(decvalue)
            hexvalue = sprintf('0x%02s', dec2hex(decvalue));
        end
    end
end

