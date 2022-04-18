% NOTE: DO NOT REMOVE THIS LINE XMAKEFILE_TOOL_CHAIN_CONFIGURATION
function toolChainConfiguration = gcc_linuxremotebuild()
%GCC_LINUXREMOTEBUILD Defines a tool chain configuration to be used for on-target
%compilation. That is, gcc / ar / make(gmake) is installed on the final
%target where code is intended to run.

% Copyright 2012 The MathWorks, Inc.

% Requirements
toolChainConfiguration.Decorator        = 'linkfoundation.xmakefile.decorator.eclipseDecorator';
% Make
toolChainConfiguration.MakePath         = fullfile(matlabroot,'bin',linkfoundation.xmakefile.getArchitecture(),'gmake');
toolChainConfiguration.MakeFlags        = '-f "[|||MW_XMK_GENERATED_FILE_NAME[R]|||]" [|||MW_XMK_ACTIVE_BUILD_ACTION_REF|||]';
toolChainConfiguration.MakeInclude      = '';
% Pre-build
toolChainConfiguration.PrebuildEnable   = false;
toolChainConfiguration.PrebuildToolPath = '';
toolChainConfiguration.PrebuildFlags    = '';
% Postlude
toolChainConfiguration.PostbuildEnable   = false;
toolChainConfiguration.PostbuildToolPath = '';
toolChainConfiguration.PostbuildFlags    = '';
% Execute
toolChainConfiguration.ExecuteDefault    = false;
toolChainConfiguration.ExecuteToolPath   = 'echo';
toolChainConfiguration.ExecuteFlags      = 'To customize the execute command, clone this configuration';

% General
toolChainConfiguration.Configuration     = 'LinuxRemoteBuild';
toolChainConfiguration.Description       = 'GNU GCC';
toolChainConfiguration.Version           = '2.0';
toolChainConfiguration.Operational       = true;

% Make
toolChainConfiguration.MakePath          = 'make';

% GCC related definitions
toolChainConfiguration.InstallPath       = '';

% Compiler
toolChainConfiguration.CompilerPath      = 'gcc';
toolChainConfiguration.CompilerFlags     = '-c';
toolChainConfiguration.SourceExtensions  = '.c';
toolChainConfiguration.HeaderExtensions  = '.h';
toolChainConfiguration.ObjectExtension   = '.o';
% Linker
toolChainConfiguration.LinkerPath        = 'gcc';
toolChainConfiguration.LinkerFlags       = '-o [|||MW_XMK_GENERATED_TARGET_REF|||]';
toolChainConfiguration.TargetExtension   = '';
toolChainConfiguration.LibraryExtensions = '.lib,.a,.so';
% Archiver
toolChainConfiguration.ArchiverPath      = 'ar';
toolChainConfiguration.ArchiverFlags     = 'cr [|||MW_XMK_GENERATED_TARGET_REF|||]';
toolChainConfiguration.ArchiveExtension  = '.a';
toolChainConfiguration.ArchiveNamePrefix = '';
% Be consistent with what the build process expects the model ref name to
% be. Otherwise, incremental builds will not work correctly.
toolChainConfiguration.ArchiveNamePostfix = '_rtwlib';

% Execute
toolChainConfiguration.ExecuteDefault    = true;
toolChainConfiguration.ExecuteToolPath   = '';
toolChainConfiguration.ExecuteFlags      = '';
% Other
toolChainConfiguration.DerivedPath = '[|||MW_XMK_SOURCE_PATH_REF|||]';
% Determine if the configuration is operational or not
if(isempty(toolChainConfiguration.CompilerPath))
    toolChainConfiguration.Operational = false;
    toolChainConfiguration.OperationalReason = message('realtime:build:xmk_warning_Functions_GCC_unidentified');
end

%[EOF]
    
% LocalWords:  XMAKEFILE gmake XMK realtime xmk
