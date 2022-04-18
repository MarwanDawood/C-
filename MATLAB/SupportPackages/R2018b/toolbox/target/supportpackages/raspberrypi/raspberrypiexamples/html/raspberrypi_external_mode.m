%% Communicating with Raspberry Pi(R) Hardware
%
%
% This example shows how to tune the parameters and monitor the signals of
% an algorithm running on Raspberry Pi board.
 
% Copyright 2015-2017 The MathWorks, Inc.


%% Introduction
%
% Simulink Support Package for Raspberry Pi hardware enables you to monitor
% and tune algorithms running on Raspberry Pi board from the same
% Simulink(R) models from which you developed the algorithms.
%
% In this example you will learn how to tune and monitor the algorithm in
% real time as it is executing. When you are developing algorithms, it is
% often necessary to determine appropriate values of critical algorithm
% parameters in an iterative fashion. For example, a surveillance algorithm
% that measures motion energy in a room may use a threshold to determine an
% intruder in the presence of ambient noise. If the threshold value is set
% too low, the algorithm may erroneously interpret any movement as an
% intruder. If the threshold value is set too high, the algorithm may not
% be able to detect any movement at all. In such cases, the right threshold
% value may be obtained by trying different values until the desired
% algorithm performance is reached. This iterative process is called
% parameter tuning.
% 
% Simulink's External mode feature enables you to accelerate the process of
% parameter tuning by letting you change certain parameter values while the
% model is running on target hardware, without stopping the model. When you
% change parameter values from within Simulink, the modified parameter
% values are communicated to the target hardware immediately. The effects
% of the parameters tuning activity may be monitored by viewing algorithm
% signals on scopes or displays in Simulink.
%
% This example introduces the Simulink *External mode* feature by showing
% you how to:
%
% * Set up communication between Simulink and Raspberry Pi board.
% * Use a Simulink model to tune the parameters of an algorithm that is
% running on Raspberry Pi board.
% * Use Simulink scopes to monitor the state of an algorithm running on
% Raspberry Pi board.


%% Prerequisites
%
% We recommend completing
% <https://www.mathworks.com/help/supportpkg/beaglebone/examples/getting-started-with-beaglebone-black-support-package.html Getting Started with Embedded Coder Support Package for BeagleBone Black Hardware> example.
 
%% Required Hardware
%
% To run this example you will need the following hardware:
% 
% * Raspberry Pi board
%

open_system('raspberrypi_external_mode');

%% Task 1 - Configure the Model for Raspberry Pi Hardware
%
% In this task, you will configure the model for the supported Raspberry Pi
% board.
%
% *1.* Open the <matlab:raspberrypi_external_mode Communicating with
% Raspberry Pi Hardware> model.
%
% *2.*  In your Simulink model, click *Simulation > Model Configuration
% Parameters* to open *Configuration Parameters* dialog.
%
% *3.* Select the *Hardware Implementation* pane and select Raspberry Pi
% hardware from the *Hardware board* parameter list. Do not change any
% other settings.
%
% *4.* Click *OK*.
%

%% Task 2 - Simulate the Model
%
% To simulate the model, follow these steps:
%
% *1.* Observe that the model plays the motion energy recorded in a room
% and compares it with a threshold to detect intrusion.
%
% *2.* In the model, change the *Simulation mode* on the toolbar to
% *Normal*. This tells Simulink to run the model on the host computer. See
% Task 4 below to run the model on the Raspberry Pi hardware.
%
% *3.* In the model, click the *Run* button in the Simulink toolbar.
%
% *4.* Double click the *Scope* block. Observe that the algorithm detects
% multiple intrusions.
%
% *5.* Click *Stop* button in the Simulink model.
%

%% Task 3 - Run the Model in External Mode
%
% *1.* In the model, change the *Simulation mode* on the toolbar to
% *External*.
%
% *2.* In the model, click the *Run* button on the toolbar.
%

%% Task 4 - Communicate with the Model
%
% At this point, your model is running on Raspberry Pi board. As the model
% runs on hardware, it communicates with Simulink model in External mode
% using TCP/IP.
%
% *1.* Notice that the user LED is glowing almost constantly. This means
% that the selected threshold is too low and that the algorithm
% misinterprets even a minor motion energy change as an intrusion. You need
% to find a more optimal value of the threshold.
%
% *2.* Double-click the *Threshold* block in the model, increase its value,
% and click *OK* or *Apply*. This changes the threshold value in the model
% running on the board.
% 
% *3.* Check whether the glowing pattern of the LED has changed. The LED
% should light up every 10 and 11.5 seconds in a correctly tuned algorithm.
%
% *4.* If there is no change in LED light pattern, repeat the Steps 2 and 3
% until you find the right value of the threshold.
%
% *5.* Click *Stop* button in the Simulink model.
%

%% Other Things to Try
% 
% * Monitor other signals in the model. For example, add another scope to
% monitor the value of the recorded motion energy.
% * Improve the detection algorithm to filter out any motion energy changes
% that are shorter than 0.2 seconds.
%

%% Summary
%
% This example showed a workflow for tuning and monitoring an algorithm
% running on Raspberry Pi board. In this example you learned:
%
% * How to tune an algorithm parameter on Raspberry Pi board using the
% External mode feature.
% * How to monitor the outputs of an algorithm running on Raspberry Pi board
% in real-time

close_system('raspberrypi_external_mode', 0); 
displayEndOfDemoMessage(mfilename) 
% LocalWords: raspberry gettingstarted

