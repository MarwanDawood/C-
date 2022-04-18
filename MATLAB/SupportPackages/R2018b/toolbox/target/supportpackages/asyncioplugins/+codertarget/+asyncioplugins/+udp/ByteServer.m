classdef ByteServer < handle
    % A UDP server that sends and receives data from/to UDP clients. 
    %
    % Usages:
    %    obj = udp.ByteServer();
    %    obj = udp.ByteServer(PORT)
    %    obj = udp.ByteServer(PORT, [INPUTBUFFERSIZE,OUTPUTBUFFERSIZE])
    %
    % Example:
    %    addpath(fullfile(matlabroot,'toolbox','shared','asynciolib','examples'),'-end');    
    %    % Set up a server that listens on port 1200
    %    obj = udp.ByteServer(1200);
    %    obj.open();
    %
    %    % After data is sent from client, read data and respond...
    %    data = obj.read()
    %    data.Data = uint8('response');
    %    obj.write(data);
    %
    %    % Broadcast data to all listeners on a given port.
    %    data.Endpoint = 49000;
    %    data.Data = uint8('broadcast');
    %    obj.write(data);
    %
    %    % Cleanup
    %    obj.close();
    %    clear obj;
    %
    
    properties(SetAccess='private', GetAccess='public')
        PortNumber
    end

    properties(Access='public')
        NonBlocking = false;
        SocketReceiveSize = 64*1024;
        SocketSendSize = 64*1024;       
    end
    
    properties(SetAccess='private',GetAccess='public',Dependent)
        DataAvailable  % Data available to read.
        DataToSend     % Data written but not yet sent.
    end
    
    events(NotifyAccess='private')
        Closed
    end
    
    %% Lifetime
    methods
        function obj = ByteServer(portNumber, bufferSizes)
            % ByteServer creates a UDP server that sends and receives 
            % data to/from any UDP client.
            
            % If no buffer sizes specified, supply a default.
            if nargin < 2
                bufferSizes = [Inf Inf];
            end
            
            % If no port specified, supply a default.
            if nargin < 1
                portNumber = 0;  % 0 means, listen on no port.
            end
                
            obj.PortNumber = portNumber;
            options.PortNumber = portNumber;
            
            % Create channel.
            obj.Channel = codertarget.asyncioplugins.udp.Channel('udpserver', options, bufferSizes);
        end
    end
    
    %% Operations
    methods
        function open(obj)
            % Register listener for close.
            obj.ClosedListener = addlistener(obj.Channel, 'Closed',...
                       @(source,data) obj.onClosed() );
                     
            % Begin accepting connections.
            options.ReceiveSize = obj.SocketReceiveSize;
            options.SendSize = obj.SocketSendSize;
            obj.Channel.open(options);
        end
        
        function close(obj)
            % Stop accepting connections, and close down all open
            % connections.
            obj.Channel.close();
            
            % Unregister listeners.
            delete(obj.ClosedListener);
        end
        
        function result = isOpen(obj)
            result = obj.Channel.isOpen();
        end
        
        function [data, countRead] = read(obj, varargin)
            % [DATA COUNTREAD] = read(OBJ, COUNT);
            % Returned data will be an array of structures with fields 
            % Endpoint and Data where Endpoint will be IPADDRESS:PORT.
            
            % If nonblocking and not enough data, return.
            if obj.NonBlocking && nargin > 1 && varargin{1} > obj.DataAvailable
                data = [];
                countRead = 0;
                return;
            end                
            
            % Read data that has been sent from any client.
            [data, countRead, err] = obj.Channel.InputStream.read(varargin{:});
            if ~isempty(err)
                error(['byteserver:read:' err],['UDP server error reading data: ' err]);
            end
        end
        
        function countWritten = write(obj, data)
            % COUNTWRITTEN = write(OBJ, DATA);
            % DATA must be an array of structures with fields 
            % Endpoint and Data where Endpoint should be IPADDRESS:PORT to
            % send to a specific adress and port, and PORT to broadcast to
            % all adresses listening on that port.
            
            % If nonblocking and not enough room, return.
            if obj.NonBlocking && length(data) > obj.Channel.OutputStream.SpaceAvailable
                countWritten = 0;
                return;
            end  
            
            % Write data to all connected clients.
            [countWritten, err] = obj.Channel.OutputStream.write(data);
            if ~isempty(err)
                error(['byteserver:write:' err],['TCP server error writing data: ' err]);
            end
        end
    end
  
    %% Getters/Setters
    methods
        function value = get.DataAvailable(obj)
            value = obj.Channel.InputStream.DataAvailable;
        end
        
        function value = get.DataToSend(obj)
            value = obj.Channel.OutputStream.DataToSend;
        end
    end

    %% Lifetime
    methods(Access='private')
        function delete(obj)
            close(obj);
            delete(obj.Channel);
        end
    end
    
    %% Event Handlers
    methods(Access='private')
        function onClosed(obj)
            % Pass it along to any of our listeners.
            notify(obj, 'Closed');
        end 
    end
    
    %% Internal Properties
    properties(Access='protected',Transient)
        Channel
        ClosedListener
    end
end

