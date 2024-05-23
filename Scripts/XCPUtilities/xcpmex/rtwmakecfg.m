function makeInfo = rtwmakecfg()
%RTWMAKECFG Add include and source directories to RTW make files.
%
%  MAKEINFO = RTWMAKECFG returns a structured array containing
%  following fields:
%
%     makeInfo.includePath - cell array containing additional include
%                            directories. Those directories will be 
%                            expanded into include instructions of rtw 
%                            generated make files.
%     
%     makeInfo.sourcePath  - cell array containing additional source
%                            directories. Those directories will be
%                            expanded into rules of rtw generated make
%                            files.
%
%     makeInfo.library     - structure containing additional runtime library
%                            names and module objects.  This information
%                            will be expanded into rules of rtw generated make
%                            files.

% Copyright 2012-2018 The MathWorks, Inc.


makeInfo.sourcePath = {};
makeInfo.includePath = {...
        fullfile(matlabroot, 'extern', 'include')};
 
makeInfo.sources = {};

makeInfo.precompile = 1;
makeInfo.library = [];

cgLibRoot = fullfile(matlabroot, 'toolbox', 'shared', 'xcpcore', 'cglib', computer('arch'));

%Locate static libraries for SLRT
if isSLRT
    slrtLibRoot = fullfile(matlabroot, 'toolbox', 'slrt', 'blocks', 'protocols', 'lib');

    if exist(fullfile(slrtLibRoot, 'xcpmpl_cg.lib'), 'file')
        cgLibRoot = slrtLibRoot;
        useUDPLibraryForSLRT = true;
    else
        %Legacy SLRT build (w/sources). TODO remove after reaching Bslrt
        cgLibRoot = fullfile(matlabroot, 'toolbox', 'shared', 'xcpcore', 'cglib', 'win32');
        useUDPLibraryForSLRT = false;
    end
end

%Statically link xcp master library
makeInfo.linkLibsObjs = {fullfile(cgLibRoot, 'xcpmpl_cg.lib')};

%Statically link both CAN and UDP libraries
makeInfo.linkLibsObjs(end+1) = {fullfile(cgLibRoot, 'xcpcantl_cg.lib' )}; %CAN

%UDP
if ~isSLRT || useUDPLibraryForSLRT
    makeInfo.linkLibsObjs(end+1) = {fullfile(cgLibRoot, 'xcpudptl_cg.lib' )};
else
    %Legacy SLRT build. TODO remove after reaching Bslrt
    makeInfo.sourcePath = [makeInfo.sourcePath ...
            {fullfile(matlabroot, 'toolbox', 'shared', 'xcpcore', 'src','xcpudptl')}];
    makeInfo.sources = [makeInfo.sources ...
            {'udptl.c','xcpudp.c'}];
    makeInfo.includePath = [makeInfo.includePath ...
            {fullfile(matlabroot, 'toolbox', 'shared', 'xcpcore','src','xcpudptl')}];
end


% Check if we are currently in SLRT build context
function out = isSLRT
out = ~isempty(regexpi(get_param(bdroot, 'SystemTargetFile'),'^slrt'));



