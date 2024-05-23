classdef Command < uint8
% Command Enumeration of XCP commands.

% Copyright 2017 The MathWorks, Inc.
    
enumeration
    CONNECT                 (hex2dec('FF'))
    DISCONNECT              (hex2dec('FE'))
    GET_STATUS              (hex2dec('FD'))
    SYNCH                   (hex2dec('FC'))
    GET_COMM_MODE_INFO      (hex2dec('FB'))
    GET_ID                  (hex2dec('FA'))
    SET_REQUEST             (hex2dec('F9'))
    GET_SEED                (hex2dec('F8'))
    UNLOCK                  (hex2dec('F7'))
    SET_MTA                 (hex2dec('F6'))
    UPLOAD                  (hex2dec('F5'))
    SHORT_UPLOAD            (hex2dec('F4'))
    BUILD_CHECKSUM          (hex2dec('F3'))
    TRANSPORT_LAYER_CMD     (hex2dec('F2'))
    USER_CMD                (hex2dec('F1'))
    SET_DAQ_PTR             (hex2dec('E2'))
    WRITE_DAQ               (hex2dec('E1'))
    SET_DAQ_LIST_MODE       (hex2dec('E0'))
    START_STOP_DAQ_LIST     (hex2dec('DE'))
    START_STOP_SYNCH        (hex2dec('DD'))
    READ_DAQ                (hex2dec('DB'))
    GET_DAQ_CLOCK           (hex2dec('DC'))
    GET_DAQ_PROCESSOR_INFO  (hex2dec('DA'))
    GET_DAQ_RESOLUTION_INFO (hex2dec('D9'))
    GET_DAQ_LIST_MODE       (hex2dec('DF'))
    GET_DAQ_EVENT_INFO      (hex2dec('D7'))
    FREE_DAQ                (hex2dec('D6'))
    ALLOC_DAQ               (hex2dec('D5'))
    ALLOC_ODT               (hex2dec('D4'))
    ALLOC_ODT_ENTRY         (hex2dec('D3'))
    DOWNLOAD                (hex2dec('F0'))
    CLEAR_DAQ_LIST          (hex2dec('E2'))
    GET_DAQ_LIST_INFO       (hex2dec('D8'))
end

end
