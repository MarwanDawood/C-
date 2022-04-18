classdef BusTransactionInterface < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    % Copyright 2015 The MathWorks, Inc.
    %#codegen
    methods (Abstract)
        openCommChannel(obj);
        closeCommChannel(obj);
        data = read(obj,cnt,prec);
        write(obj,data,prec);
        data = readRegister(obj,reg,cnt,prec);
        writeRegister(obj,reg,data,prec);
    end
end


