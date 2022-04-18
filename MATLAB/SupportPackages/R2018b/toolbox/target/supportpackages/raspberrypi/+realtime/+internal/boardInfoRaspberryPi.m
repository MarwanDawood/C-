function info = boardInfoRaspberryPi()
%boardInfoRaspberryPi   Detailed explanation goes here

% Copyright 2012 The MathWorks, Inc.
raspiRoot = raspi.internal.getRaspiRoot;
rootDir = codertarget.raspi.internal.getSpPkgRootDir;

%% Raspberry Pi Model B Rev 1
i = 1;
info.Board(i).Name = 'Model B Rev1';
% CPU info
info.Board(i).CPU.Implementer = '0x41';
info.Board(i).CPU.Architecture = '7';
info.Board(i).CPU.Variant = '0x0';
info.Board(i).CPU.Part = '0xb76';
info.Board(i).CPU.Revision = '7';
info.Board(i).CPU.Hardware = 'BCM2708';
info.Board(i).CPU.HardwareRevision = 0:3;
% LED info
info.Board(i).LED(1).Name = 'led0';
info.Board(i).LED(1).Color = 'Green';
info.Board(i).LED(1).DeviceFile = 'led0';
info.Board(i).LEDImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_modelb_led_location.png');
% GPIO info
info.Board(i).GPIOImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_modelb_rev1_gpio_pinmap.png');
info.Board(i).GPIO = i_addGpio([], 0, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 1, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 4);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 17);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 21);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 22);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 10);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 9);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 11);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 14);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 15);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 18);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 23);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 24);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 25);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 8);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 7);

%% Raspberry Pi Model B Rev 2
i = i + 1;
info.Board(i).Name = 'Model B Rev2';
% CPU info
info.Board(i).CPU.Implementer = '0x41';
info.Board(i).CPU.Architecture = '7';
info.Board(i).CPU.Variant = '0x0';
info.Board(i).CPU.Part = '0xb76';
info.Board(i).CPU.Revision = '7';
info.Board(i).CPU.Hardware = 'BCM2708';
info.Board(i).CPU.HardwareRevision = 4:15;
% LED info
info.Board(i).LED(1).Name = 'led0';
info.Board(i).LED(1).Color = 'Green';
info.Board(i).LED(1).DeviceFile = 'led0';
info.Board(i).LEDImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_modelb_led_location.png');
% GPIO info
info.Board(i).GPIOImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_modelb_rev2_gpio_pinmap.png');
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 2, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 3, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 4);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 17);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 27);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 22);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 10);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 9);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 11);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 14);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 15);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 18);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 23);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 24);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 25);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 8);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 7);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 28);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 30);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 29);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 31);


%% Raspberry Pi Model B+
i = i + 1;
info.Board(i).Name = 'Model B+';
% CPU info
info.Board(i).CPU.Implementer = '0x41';
info.Board(i).CPU.Architecture = '7';
info.Board(i).CPU.Variant = '0x0';
info.Board(i).CPU.Part = '0xb76';
info.Board(i).CPU.Revision = '7';
info.Board(i).CPU.Hardware = 'BCM2708';
info.Board(i).CPU.HardwareRevision = 16;
% LED info
info.Board(i).LED(1).Name = 'led0';
info.Board(i).LED(1).Color = 'Green';
info.Board(i).LED(1).DeviceFile = 'led0';
info.Board(i).LEDImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_modelb+_led_location.png');
% GPIO info
info.Board(i).GPIOImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_modelb+_gpio_pinmap.png');
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 2, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 3, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 4);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 17);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 27);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 22);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 10);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 9);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 11);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 14);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 15);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 18);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 23);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 24);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 25);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 8);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 7);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 5);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 6);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 12);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 13);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 19);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 16);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 26);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 20);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 21);

%% Raspberry Pi 2 Model B
% http://www.raspberrypi-spy.co.uk/2012/09/checking-your-raspberry-pi-board-version/
i = i + 1;
info.Board(i).Name = 'Pi 2 Model B';
% CPU info
info.Board(i).CPU.Implementer = '0x41';
info.Board(i).CPU.Architecture = '7';
info.Board(i).CPU.Variant = '0x0';
info.Board(i).CPU.Part = '0xc07';
info.Board(i).CPU.Revision = '5';
info.Board(i).CPU.Hardware = 'BCM2709';
info.Board(i).CPU.HardwareRevision = [];
% LED info
info.Board(i).LED(1).Name = 'led0';
info.Board(i).LED(1).Color = 'Green';
info.Board(i).LED(1).DeviceFile = 'led0';
info.Board(i).LEDImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_modelb+_led_location.png');
% GPIO info
info.Board(i).GPIOImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_modelb+_gpio_pinmap.png');
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 2, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 3, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 4);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 17);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 27);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 22);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 10);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 9);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 11);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 14);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 15);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 18);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 23);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 24);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 25);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 8);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 7);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 5);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 6);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 12);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 13);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 19);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 16);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 26);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 20);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 21);


%% Raspberry Pi 3 Model B
% http://www.raspberrypi-spy.co.uk/2012/09/checking-your-raspberry-pi-board-version/
i = i + 1;
info.Board(i).Name = 'Pi 3 Model B';
% CPU info
info.Board(i).CPU.Implementer = '0x41';
info.Board(i).CPU.Architecture = '7';
info.Board(i).CPU.Variant = '0x0';
info.Board(i).CPU.Part = '0xc07';
info.Board(i).CPU.Revision = '4';
info.Board(i).CPU.Hardware = 'BCM2709';
info.Board(i).CPU.HardwareRevision = [];
% LED info
info.Board(i).LED(1).Name = 'led0';
info.Board(i).LED(1).Color = 'Green';
info.Board(i).LED(1).DeviceFile = 'led0';
info.Board(i).LEDImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_3_modelb_led_location.jpg');
% GPIO info
info.Board(i).GPIOImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_3_modelb_gpio_pinmap.jpg');
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 2, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 3, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 4);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 17);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 27);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 22);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 10);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 9);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 11);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 14);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 15);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 18);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 23);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 24);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 25);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 8);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 7);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 5);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 6);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 12);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 13);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 19);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 16);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 26);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 20);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 21);

%% Raspberry Pi 3 Model B+
% http://www.raspberrypi-spy.co.uk/2012/09/checking-your-raspberry-pi-board-version/
i = i + 1;
info.Board(i).Name = 'Pi 3 Model B+';
% CPU info
info.Board(i).CPU.Implementer = '0x41';
info.Board(i).CPU.Architecture = '7';
info.Board(i).CPU.Variant = '0x0';
info.Board(i).CPU.Part = '0xd03';
info.Board(i).CPU.Revision = '4';
info.Board(i).CPU.Hardware = 'BCM2835';
info.Board(i).CPU.HardwareRevision = [];
% LED info
info.Board(i).LED(1).Name = 'led0';
info.Board(i).LED(1).Color = 'Green';
info.Board(i).LED(1).DeviceFile = 'led0';
info.Board(i).LEDImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_3_modelb_led_location.jpg');
% GPIO info
info.Board(i).GPIOImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_3_modelb_gpio_pinmap.jpg');
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 2, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 3, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 4);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 17);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 27);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 22);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 10);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 9);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 11);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 14);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 15);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 18);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 23);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 24);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 25);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 8);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 7);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 5);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 6);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 12);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 13);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 19);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 16);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 26);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 20);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 21);

%% Raspberry Pi Zero W
% http://www.raspberrypi-spy.co.uk/2012/09/checking-your-raspberry-pi-board-version/
i = i + 1;
info.Board(i).Name = 'Pi Zero W';
% CPU info
info.Board(i).CPU.Implementer = '0x41';
info.Board(i).CPU.Architecture = '7';
info.Board(i).CPU.Variant = '0x0';
info.Board(i).CPU.Part = '0xb76';
info.Board(i).CPU.Revision = '7';
info.Board(i).CPU.Hardware = 'BCM2835';
info.Board(i).CPU.HardwareRevision = [];
% LED info
info.Board(i).LED(1).Name = 'led0';
info.Board(i).LED(1).Color = 'Green';
info.Board(i).LED(1).DeviceFile = 'led0';
info.Board(i).LEDImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_zero_w_led_location.png');
% GPIO info
info.Board(i).GPIOImgFile = fullfile(raspiRoot, 'resources', ...
    'raspberrypi_zero_w_gpio_pinmap.png');
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 2, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 3, {'N/A'});
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 4);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 17);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 27);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 22);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 10);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 9);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 11);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 14);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 15);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 18);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 23);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 24);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 25);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 8);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 7);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 5);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 6);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 12);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 13);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 19);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 16);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 26);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 20);
info.Board(i).GPIO = i_addGpio(info.Board(i).GPIO, 21);
end

%% Internal functions
function gpio = i_addGpio(gpio, number, direction)
if nargin < 3
    direction = {'Input', 'Output'};
end
newGpio.Number = number;
newGpio.Direction = direction;
newGpio.PrimaryFunction = '';
newGpio.InternalResistor = {};
gpio = [gpio, newGpio];
end

%[EOF]
