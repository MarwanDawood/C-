function info = boardInfoRaspberryPiModelBRev2()
%boardInfoRaspberryPiModelBRev2

% Copyright 2013-2014 The MathWorks, Inc.

rootDir = raspi.internal.getRaspiRoot;
info.Board.Name     = 'Raspberry Pi Model B Rev2';
info.Board.Revision = 2;

% LED info
info.Board.LED(1).Name       = 'led0';
info.Board.LED(1).Number     = 0;
info.Board.LED(1).Color      = 'Green';
info.Board.LED(1).DeviceFile = 'led0';
info.Board.LEDImgFile = fullfile(rootDir, 'resources', ...
    'raspberrypi_modelb_led_location.png');

% GPIO info
info.Board.GPIOPins   = sort([2, 3, 4, 17, 27, 22, 10, 9, 11, 14, 15, 18, ...
    23, 24, 25, 8, 7, 28, 29, 30, 31]);
info.Board.GPIOImgFile = fullfile(rootDir, 'resources', ...
    'raspberrypi_modelb_rev2_gpio_pinmap.png');

% I2C info
info.Board.I2C(1).Name   = 'i2c-0';
info.Board.I2C(1).Number = 0;
info.Board.I2C(1).Pins   = [28, 29]; % SDA, SCLK
info.Board.I2C(2).Name   = 'i2c-1';
info.Board.I2C(2).Number = 1;
info.Board.I2C(2).Pins   = [2, 3];   % SDA, SCLK

% SPI info
info.Board.SPI(1).Name   = 'spidev0';
info.Board.SPI(1).Number = 0; 
info.Board.SPI(1).Pins   = [7, 8, 9]; % MOSI, MISO, CLK, 
info.Board.SPI(1).Channel(1).Name   = 'CE0';
info.Board.SPI(1).Channel(1).Number = 0;
info.Board.SPI(1).Channel(1).Pins   = 10;       % CE0
info.Board.SPI(1).Channel(2).Name   = 'CE1';
info.Board.SPI(1).Channel(2).Number = 1;
info.Board.SPI(1).Channel(2).Pins   = 11; % CE1

% Serial info
info.Board.Serial(1).Name   = '/dev/ttyAMA0';
info.Board.Serial(1).Number = 0;
info.Board.Serial(1).Pins   = [14, 15];

end

%[EOF]
