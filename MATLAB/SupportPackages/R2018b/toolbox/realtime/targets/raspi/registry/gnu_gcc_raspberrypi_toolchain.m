function [tc, results] = gnu_gcc_raspberrypi_toolchain()
%GNU_GCC_RASPBERRYPI_TOOLCHAIN Toolchain definition file

% Copyright 2015-2017 The MathWorks, Inc.

toolchain.Platforms  = {'win64','win32','glnxa64','maci64'};
toolchain.Versions   = {'1.0'};
toolchain.Artifacts  = {'gmake'};
toolchain.FuncHandle = str2func('getToolchainInfoFor');
toolchain.ExtraFuncArgs = {};

[tc, results] = coder.make.internal.generateToolchainInfoObjects(mfilename, toolchain);
end

function tc = getToolchainInfoFor(platform, version, artifact, varargin)
% Toolchain Information

tc = coder.make.ToolchainInfo('BuildArtifact', 'custom makefile', ...
    'SupportedLanguages', {'Asm/C/C++'}, ...
    'BuildArtifactWriter', 'codertarget.raspi.Writer', ...
    'BuildArtifactExecutor', 'codertarget.raspi.Executor');
toolchainIdentifier = 'GNU GCC Raspberry Pi';
tc.Name = coder.make.internal.formToolchainName('GNU GCC Raspberry Pi', ...
    platform, version, artifact);
tc.Platform = platform;
tc.setBuilderApplication(platform);

% Toolchain's attribute
tc.addAttribute('TransformPathsWithSpaces');
tc.addAttribute('SupportsUNCPaths',     false);
tc.addAttribute('SupportsDoubleQuotes', false);

% ------------------------------
% Make
% ------------------------------
objectExtension = '.o';
depfileExtension = '.dep';
tc.InlinedCommands{1} = ['DERIVED_SRCS = $(subst ', objectExtension, ',', depfileExtension, ',', '$(OBJS))'];
tc.InlinedCommands{2} = '';
tc.InlinedCommands{3} = 'build:';
tc.InlinedCommands{4} = '';
tc.InlinedCommands{5} = ['%', depfileExtension, ':'];

% Makefile includes
make = tc.BuilderApplication();
make.IncludeFiles = {'codertarget_assembly_flags.mk', ['*', depfileExtension]};
make.setPath('');
make.setCommand('make');
make.CustomValidation = 'codertarget.raspi.toolchainValidator';
make.setDirective('FileSeparator','/');

% Add macros
tc.addMacro('CCOUTPUTFLAG', '--output_file=');
tc.addMacro('LDOUTPUTFLAG', '--output_file=');
% tc.addMacro('CPFLAGS', '-O binary');

% Assembler
assembler = tc.getBuildTool('Assembler');
assembler.setName([toolchainIdentifier ' Assembler']);
assembler.setCommand('as');
assembler.setDirective('IncludeSearchPath', '-I');
assembler.setDirective('PreprocessorDefine', '-D');
assembler.setDirective('OutputFlag', '-o');
assembler.setDirective('Debug', '-g');
assembler.setFileExtension('Source','.s');
assembler.setFileExtension('Object', '.s.o');
assembler.CustomValidation = 'codertarget.raspi.toolchainValidator';

% Compiler
compiler = tc.getBuildTool('C Compiler');
compiler.setName([toolchainIdentifier ' C Compiler']);
compiler.setCommand('gcc');
compiler.setDirective('CompileFlag', '-c');
compiler.setDirective('PreprocessFile', '-E');
compiler.setDirective('IncludeSearchPath', '-I');
compiler.setDirective('PreprocessorDefine', '-D');
compiler.setDirective('OutputFlag', '-o');
compiler.setDirective('Debug', '-g');
compiler.setDirective('FileSeparator', '/');
compiler.setFileExtension('Source', '.c');
compiler.setFileExtension('Header', '.h');
compiler.setFileExtension('Object', '.c.o');
compiler.CustomValidation = 'codertarget.raspi.toolchainValidator';
cObjBuildItem = compiler.FileExtensions.getValue('Object');
cObjBuildItem.setMacro('COBJ_EXT');
compiler.addFileExtension( 'DependencyFile', coder.make.BuildItem('C_DEP', '.c.dep'));
compiler.DerivedFileExtensions = {'.c.dep'};

% C++ compiler
cppcompiler = tc.getBuildTool('C++ Compiler');
cppcompiler.setName([toolchainIdentifier ' C++ Compiler']);
cppcompiler.setCommand('g++');
cppcompiler.setDirective('CompileFlag', '-c');
cppcompiler.setDirective('PreprocessFile', '-E');
cppcompiler.setDirective('IncludeSearchPath', '-I');
cppcompiler.setDirective('PreprocessorDefine', '-D');
cppcompiler.setDirective('OutputFlag', '-o');
cppcompiler.setDirective('Debug', '-g');
cppcompiler.setDirective('FileSeparator', '/');
cppcompiler.setFileExtension('Source', '.cpp');
cppcompiler.setFileExtension('Header', '.hpp');
cppcompiler.setFileExtension('Object', '.cpp.o');
cppcompiler.CustomValidation = 'codertarget.raspi.toolchainValidator';
cppObjBuildItem = cppcompiler.FileExtensions.getValue('Object');
cppObjBuildItem.setMacro('CPPOBJ_EXT');
cppcompiler.addFileExtension( 'DependencyFile', coder.make.BuildItem('CXX_DEP', '.cpp.dep'));
cppcompiler.DerivedFileExtensions = {'.cpp.dep'};

% Linker
linker = tc.getBuildTool('Linker');
linker.setName([toolchainIdentifier ' Linker']);
linker.setCommand('gcc');
linker.setDirective('Library', '-l');
linker.setDirective('LibrarySearchPath', '-L');
linker.setDirective('OutputFlag', '-o');
linker.setDirective('Debug', '-g');
linker.setDirective('FileSeparator', '/');
linker.setFileExtension('Executable', '.elf');
linker.setFileExtension('Shared Library', '.so');
linker.Libraries = {'-lm'};
linker.CustomValidation = 'codertarget.raspi.toolchainValidator';

% C++ Linker
cpplinker = tc.getBuildTool('C++ Linker');
cpplinker.setName([toolchainIdentifier ' C++ Linker']);
cpplinker.setCommand('g++');
cpplinker.setDirective('Library', '-l');
cpplinker.setDirective('LibrarySearchPath', '-L');
cpplinker.setDirective('OutputFlag', '-o');
cpplinker.setDirective('Debug', '-g');
cpplinker.setDirective('FileSeparator', '/');
cpplinker.setFileExtension('Executable', '');
cpplinker.setFileExtension('Shared Library', '.so');
cpplinker.Libraries = {'-lm','-lstdc++'};
cpplinker.CustomValidation = 'codertarget.raspi.toolchainValidator';

% Archiver
archiver = tc.getBuildTool('Archiver');
archiver.setName([toolchainIdentifier ' Archiver']);
archiver.setCommand('ar');
archiver.setDirective('OutputFlag', '');
archiver.setDirective('FileSeparator', '/');
archiver.setFileExtension('Static Library', '.lib');
archiver.CustomValidation = 'codertarget.raspi.toolchainValidator';

% --------------------------------------------
% BUILD CONFIGURATIONS
% --------------------------------------------
optimsOffOpts = {'-O0'};
optimsOnOpts = {'-O2'};
cCompilerOpts = {''};
archiverOpts = {'-r'};

compilerOpts = {...
    tc.getBuildTool('C Compiler').getDirective('CompileFlag'),...
    };


linkerOpts = { ...
    '-lrt -lpthread -ldl',...
    };


assemblerOpts = compilerOpts;
compilerOpts = [compilerOpts, ...                
    ['-MMD -MP -MF"$(@:%', objectExtension, '=%', depfileExtension, ')" -MT"$@" '],... % make dependency files
];

% Get the debug flag per build tool
debugFlag.CCompiler   = '-g -D"_DEBUG"';
debugFlag.Linker      = '-g';
debugFlag.Archiver    = '';

cfg = tc.getBuildConfiguration('Faster Builds');
cfg.setOption('Assembler',  horzcat(cCompilerOpts, assemblerOpts, '$(ASFLAGS_ADDITIONAL)', '$(INCLUDES)'));
cfg.setOption('C Compiler', horzcat(cCompilerOpts, compilerOpts, optimsOffOpts));
cfg.setOption('Linker',     linkerOpts);
cfg.setOption('Shared Library Linker', horzcat({'-shared '}, linkerOpts));
cfg.setOption('C++ Compiler', horzcat(cCompilerOpts, compilerOpts, optimsOnOpts));
cfg.setOption('C++ Linker', linkerOpts);
cfg.setOption('C++ Shared Library Linker', horzcat({'-shared '}, linkerOpts));
cfg.setOption('Archiver',   archiverOpts);

cfg = tc.getBuildConfiguration('Faster Runs');
cfg.setOption('Assembler',  horzcat(cCompilerOpts, assemblerOpts, '$(ASFLAGS_ADDITIONAL)', '$(INCLUDES)'));
cfg.setOption('C Compiler', horzcat(cCompilerOpts, compilerOpts, optimsOnOpts));
cfg.setOption('Linker',     linkerOpts);
cfg.setOption('Shared Library Linker', horzcat({'-shared '}, linkerOpts));
cfg.setOption('C++ Compiler', horzcat(cCompilerOpts, compilerOpts, optimsOnOpts));
cfg.setOption('C++ Linker', linkerOpts);
cfg.setOption('C++ Shared Library Linker', horzcat({'-shared '}, linkerOpts));
cfg.setOption('Archiver',   archiverOpts);

cfg = tc.getBuildConfiguration('Debug');
cfg.setOption('Assembler',  horzcat(cCompilerOpts, assemblerOpts, '$(ASFLAGS_ADDITIONAL)', '$(INCLUDES)', debugFlag.CCompiler));
cfg.setOption('C Compiler', horzcat(cCompilerOpts, compilerOpts, optimsOffOpts, debugFlag.CCompiler));
cfg.setOption('Linker',     horzcat(linkerOpts, debugFlag.Linker));
cfg.setOption('Shared Library Linker', horzcat({'-shared '}, linkerOpts, debugFlag.Linker));
cfg.setOption('C++ Compiler', horzcat(cCompilerOpts, compilerOpts, optimsOffOpts, debugFlag.CCompiler));
cfg.setOption('C++ Linker', horzcat(linkerOpts, debugFlag.Linker));
cfg.setOption('Shared Library Linker', horzcat({'-shared '}, linkerOpts, debugFlag.Linker));
cfg.setOption('Archiver',   horzcat(archiverOpts, debugFlag.Archiver));

tc.setBuildConfigurationOption('all', 'Download',  '');
tc.setBuildConfigurationOption('all', 'Execute',   '');
tc.setBuildConfigurationOption('all', 'Make Tool', '-f $(MAKEFILE)');
%tc.setBuildConfigurationOption('all', 'Make Tool', '"### Successfully generated all binary outputs."');

end
